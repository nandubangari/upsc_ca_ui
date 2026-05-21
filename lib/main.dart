import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:upsc_ca_ui/core/theme/app_theme.dart';
import 'package:upsc_ca_ui/features/auth/screens/login_screen.dart';
import 'package:upsc_ca_ui/features/home/screens/dashboard_screen.dart';
import 'package:upsc_ca_ui/features/profile/screens/profile_setup_screen.dart';
import 'package:upsc_ca_ui/providers/dashboard_provider.dart';
import 'package:upsc_ca_ui/providers/theme_provider.dart';
import 'package:upsc_ca_ui/providers/subscription_provider.dart';
import 'package:upsc_ca_ui/data/repositories/auth_repository.dart';
import 'package:upsc_ca_ui/data/local/isar_service.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/data/sync/sync_manager.dart';
import 'package:upsc_ca_ui/data/services/billing_service.dart';
import 'package:upsc_ca_ui/core/services/analytics_service.dart';
import 'package:upsc_ca_ui/firebase_options.dart';
import 'package:upsc_ca_ui/shared/widgets/modern_loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize Billing Service early
  BillingService().initialize();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    AppLogger.d('Firebase initialization failed: $e');
  }

  await IsarService.init();

  final platform = WebViewPlatform.instance;
  if (platform is AndroidWebViewPlatform) {
    if (kDebugMode) {
      unawaited(AndroidWebViewController.enableDebugging(true));
    }
  }

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        Provider(create: (_) => AnalyticsService()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer precaching to avoid blocking the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      precacheImage(
        const NetworkImage('https://www.transparenttextures.com/patterns/asfalt-dark.png'),
        context,
      );
      precacheImage(
        const NetworkImage('https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png'),
        context,
      );
      // Initialize SyncManager after first frame
      SyncManager().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'UPSC CA',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        Provider.of<AnalyticsService>(context, listen: false).observer,
      ],
      theme: AppTheme.lightTheme(themeProvider.primaryColor).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransitionsBuilder(),
            TargetPlatform.iOS: NoTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: AppTheme.darkTheme(themeProvider.primaryColor).copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransitionsBuilder(),
            TargetPlatform.iOS: NoTransitionsBuilder(),
          },
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: const AuthWrapper(),
    );
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Stream<User?> _userStream;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _userStream = AuthRepository().user
        .transform<User?>(
          StreamTransformer<User?, User?>.fromHandlers(
            handleData: (data, sink) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                if (!mounted) return;
                sink.add(data);
              });
            },
          ),
        )
        .distinct((prev, next) => prev?.uid == next?.uid);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return const LoginEntryWrapper();
          } else {
            return const ProfileWrapper();
          }
        }
        
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class ProfileWrapper extends StatefulWidget {
  const ProfileWrapper({super.key});

  @override
  State<ProfileWrapper> createState() => _ProfileWrapperState();
}

class _ProfileWrapperState extends State<ProfileWrapper> {
  late final Future<dynamic> _profileFuture;
  StreamSubscription? _syncSubscription;
  double _syncProgress = 0.0;
  String _syncStatus = "Checking profile...";
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService().getProfile();
    
    // Listen to SyncManager events to show progress during subsequent logins
    _syncSubscription = SyncManager().events.listen((event) async {
      if (event.type == SyncEventType.progressUpdate) {
        // FIX: Only show loading overlay if profile setup is actually complete
        final isSetupComplete = await ProfileService().isProfileSetupComplete();
        if (!isSetupComplete) return;

        if (mounted) {
          setState(() {
            _isSyncing = true;
            _syncProgress = event.progress ?? _syncProgress;
            _syncStatus = event.status ?? _syncStatus;
          });
        }
      } else if (event.type == SyncEventType.initialSyncComplete || 
                 event.type == SyncEventType.userDataSyncComplete) {
        if (mounted) {
          setState(() {
            _isSyncing = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          // Brief spinner while determining user state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final hasProfile = profileSnapshot.data != null;

        // If background sync starts, only overlay the Dashboard, never the Setup screen
        if (_isSyncing && hasProfile) {
          return ModernLoadingScreen(
            progress: _syncProgress,
            status: _syncStatus,
            title: "SYNCHRONIZING DATA",
          );
        }
        
        // If no profile found in Isar or Cloud, it's a first-time user
        if (!hasProfile) {
          return const ProfileSetupScreen();
        }

        return const DashboardScreen();
      },
    );
  }
}

class LoginEntryWrapper extends StatefulWidget {
  const LoginEntryWrapper({super.key});

  @override
  State<LoginEntryWrapper> createState() => _LoginEntryWrapperState();
}

class _LoginEntryWrapperState extends State<LoginEntryWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500), // Reduced duration for faster entry
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: const LoginScreen(),
      ),
    );
  }
}
