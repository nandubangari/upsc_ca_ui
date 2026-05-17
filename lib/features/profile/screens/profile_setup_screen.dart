import 'dart:async';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/shared/models/profile_data.dart';
import 'package:upsc_ca_ui/shared/widgets/blur_button.dart';
import 'package:upsc_ca_ui/shared/widgets/modern_text_field.dart';
import 'package:upsc_ca_ui/shared/widgets/modern_switch.dart';
import 'package:upsc_ca_ui/shared/widgets/modern_date_picker.dart';

import 'package:upsc_ca_ui/providers/theme_provider.dart';
import 'package:upsc_ca_ui/data/repositories/auth_repository.dart';
import 'package:upsc_ca_ui/core/config/app_constants.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/features/home/screens/dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthRepository _authRepository = AuthRepository();
  late TextEditingController _nameController;
  late DateTime _joinedAt;
  late DateTime _startDate;
  DateTime? _examDate;
  
  Map<String, bool> _articleSources = {};
  Map<String, bool> _quizSources = {};
  List<int> _repetitionIntervals = [1, 7, 30, 120, 300];
  String _readingPreference = 'internal_browser';

  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _joinedAt = DateTime.now();
    _startDate = DateTime.now();
    unawaited(_loadProfileData());
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _authRepository.currentUser;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      
      ProfileData? cloudData;
      if (user != null) {
        cloudData = await _profileService.fetchProfileFromCloud(user.uid);
      }
      
      final ProfileData localData = await _profileService.fetchProfileFromJson();

      if (mounted) {
        setState(() {
          if (cloudData != null) {
            _nameController.text = cloudData.name;
          } else if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
            _nameController.text = user.displayName!;
          } else {
            _nameController.text = localData.name;
          }

          final activeData = cloudData ?? localData;
          _joinedAt = activeData.joinedAt;
          _startDate = activeData.startDate;
          _examDate = activeData.examDate;
          _repetitionIntervals = activeData.repetitionIntervals;
          _readingPreference = activeData.readingPreference;
          
          _articleSources = {};
          for (var source in AppConstants.defaultArticleSources) {
            _articleSources[source] = activeData.articleSources[source] ?? true;
          }
          
          _quizSources = {};
          for (var source in AppConstants.defaultQuizSources) {
            _quizSources[source] = activeData.quizSources[source] ?? true;
          }
          
          if (activeData.themeColorValue != null) {
            unawaited(themeProvider.setPrimaryColor(Color(activeData.themeColorValue!)));
          }

          _isDataLoading = false;
        });
      }
    } catch (e) {
      AppLogger.d('Error loading profile: $e');
      if (mounted) {
        setState(() => _isDataLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDataLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 1),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top + 20),
                  _buildModernHeader(context),
                  const SizedBox(height: 32),
                  _buildPersonalCard(context),
                  const SizedBox(height: 20),
                  _buildThemeColorCard(context),
                  const SizedBox(height: 20),
                  _buildReadingPreferenceCard(context),
                  const SizedBox(height: 20),
                  _buildRepetitionIntervalsCard(context),
                  const SizedBox(height: 20),
                  _buildSourcesCard(context, 'Article Sources', _articleSources),
                  const SizedBox(height: 20),
                  _buildSourcesCard(context, 'Quiz Sources', _quizSources),
                  const SizedBox(height: 40),
                  _buildModernFinishButton(context),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (Navigator.canPop(context))
                  BlurButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  )
                else
                  const SizedBox(width: 44),
                
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    final isDarkTheme = themeProvider.isDarkMode;
                    return BlurButton(
                      icon: isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      onTap: () => unawaited(themeProvider.toggleTheme(!isDarkTheme)),
                      iconColor: isDarkTheme ? Colors.amber : Colors.indigo,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildModernHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final user = _authRepository.currentUser;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5),
          ),
          child: CircleAvatar(
            radius: 40,
            backgroundImage: user?.photoURL != null 
                ? NetworkImage(user!.photoURL!)
                : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Nandhu'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _nameController.text.isNotEmpty ? _nameController.text : 'Nandhu',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'UPSC ASPIRANT',
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black26,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalCard(BuildContext context) {
    return _buildModernCard(
      title: 'Personal Info',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          ModernTextField(
            controller: _nameController,
            hint: 'Your Full Name',
            label: 'FULL NAME',
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 20),
          ModernDatePicker(
            label: 'PREPARATION START DATE',
            selectedDate: _startDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            onDateSelected: (date) => setState(() => _startDate = date),
          ),
          const SizedBox(height: 20),
          ModernDatePicker(
            label: 'TARGET EXAM DATE',
            selectedDate: _examDate ?? DateTime.now().add(const Duration(days: 365)),
            firstDate: DateTime.now(),
            lastDate: DateTime(2030),
            onDateSelected: (date) => setState(() => _examDate = date),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeColorCard(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> presets = [
      const Color(0xFFFF6F00), // Saffron
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF0D9488), // Teal
      const Color(0xFFE11D48), // Rose
      const Color(0xFF059669), // Emerald
      const Color(0xFF7C3AED), // Violet
    ];

    return _buildModernCard(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THEME ACCENT COLOR',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                ...presets.map((color) => _buildColorPreset(color, themeProvider.primaryColor == color, themeProvider)),
                _buildCustomColorButton(context, themeProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreset(Color color, bool isSelected, ThemeProvider provider) {
    return GestureDetector(
      onTap: () => unawaited(provider.setPrimaryColor(color)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 14),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected 
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) 
          : null,
      ),
    );
  }

  Widget _buildCustomColorButton(BuildContext context, ThemeProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showCustomColorPicker(context, provider),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 1.5,
              ),
            ),
            child: Icon(Icons.palette_rounded, size: 20, color: isDark ? Colors.white38 : Colors.black38),
          ),
        ],
      ),
    );
  }

  void _showCustomColorPicker(BuildContext context, ThemeProvider provider) {
    final List<Color> customGrid = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
      Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Custom Accent', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        content: SizedBox(
          width: 300,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: customGrid.length,
            itemBuilder: (context, index) {
              final color = customGrid[index];
              return GestureDetector(
                onTap: () {
                  unawaited(provider.setPrimaryColor(color));
                  Navigator.pop(context);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingPreferenceCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final options = [
      {'value': 'reader', 'label': 'Reader Mode', 'icon': Icons.chrome_reader_mode_outlined},
      {'value': 'internal_browser', 'label': 'In-App Browser', 'icon': Icons.tab_unselected_rounded},
    ];

    return _buildModernCard(
      title: 'Reading Experience',
      icon: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT PREFERRED READING MODE',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((opt) {
            final isSelected = _readingPreference == opt['value'];
            return GestureDetector(
              onTap: () => setState(() => _readingPreference = opt['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor.withValues(alpha: 0.1) : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? primaryColor : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      size: 20,
                      color: isSelected ? primaryColor : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        opt['label'] as String,
                        style: TextStyle(
                          color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white60 : Colors.black54),
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, size: 20, color: primaryColor),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRepetitionIntervalsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return _buildModernCard(
      title: 'Revision Cycle',
      icon: Icons.repeat_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPACED REPETITION INTERVALS (DAYS)',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26, 
              fontSize: 9, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._repetitionIntervals.map((interval) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$interval DAYS',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _repetitionIntervals.remove(interval);
                        });
                      },
                      child: Icon(Icons.close_rounded, size: 14, color: primaryColor.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              )),
              GestureDetector(
                onTap: _showAddIntervalDialog,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.add_rounded, size: 16, color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Complete all tasks for a day to schedule the next revision.',
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddIntervalDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Revision Interval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Number of days...',
            hintStyle: const TextStyle(color: Colors.white24),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w800))),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0 && !_repetitionIntervals.contains(val)) {
                setState(() {
                  _repetitionIntervals.add(val);
                  _repetitionIntervals.sort();
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesCard(BuildContext context, String title, Map<String, bool> sources) {
    return _buildModernCard(
      title: title,
      icon: title.contains('Article') ? Icons.article_outlined : Icons.quiz_outlined,
      child: Column(
        children: sources.entries.map((e) => ModernSwitch(
          label: e.key, 
          value: e.value, 
          onChanged: (val) {
            setState(() => sources[e.key] = val);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildModernCard({required String title, required IconData icon, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryColor),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }


  Widget _buildModernFinishButton(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final navigator = Navigator.of(context);
    
    return GestureDetector(
      onTap: () async {
        setState(() => _isDataLoading = true);
        
        final user = _authRepository.currentUser;
        if (user != null) {
          final now = DateTime.now();
          // If first time joining, set joinedAt to now and initialize trial
          final trialStart = _joinedAt;
          final trialEnd = trialStart.add(const Duration(days: 90));

          final profile = ProfileData(
            name: _nameController.text,
            joinedAt: _joinedAt,
            startDate: _startDate,
            examDate: _examDate,
            articleSources: _articleSources,
            quizSources: _quizSources,
            repetitionIntervals: _repetitionIntervals,
            readingPreference: _readingPreference,
            themeColorValue: themeProvider.primaryColor.toARGB32(),
            isPremium: true, // Default to true during trial
            trialStartDate: trialStart,
            trialEndDate: trialEnd,
          );
          await _profileService.saveProfileToCloud(user.uid, profile);
        }

        if (!mounted) return;
        setState(() => _isDataLoading = false);

        unawaited(navigator.pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          ),
          (route) => false,
        ));
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Center(
          child: Text(
            Navigator.canPop(context) ? 'UPDATE PROFILE' : 'CONTINUE TO DASHBOARD',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }
}
