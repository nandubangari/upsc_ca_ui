import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/main.dart';
import 'package:upsc_ca_ui/providers/dashboard_provider.dart';
import 'package:upsc_ca_ui/providers/theme_provider.dart';
import 'package:upsc_ca_ui/firebase_options.dart';
import './mock_firebase.dart';

void main() {
  setupMockFirebase();

  testWidgets('App loads and shows login screen', (WidgetTester tester) async {
    // Ensure Firebase is initialized for the test
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => DashboardProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Initial pump to let the AuthWrapper build
    await tester.pump();

    // Verify that the login screen is shown (assuming no user is logged in)
    // Check for "UPSC CA" text which is in LoginScreen
    expect(find.text('UPSC CA'), findsOneWidget);
    expect(find.text('Read today. Recall tomorrow.'), findsOneWidget);
  });
}
