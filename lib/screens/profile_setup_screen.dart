import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../components/gradient_background.dart';
import '../models/profile_data.dart';
import '../providers/theme_provider.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../config/app_constants.dart';
import 'dashboard_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  late TextEditingController _nameController;
  late DateTime _startDate;
  
  Map<String, bool> _articleSources = {};
  Map<String, bool> _quizSources = {};
  Set<int> _repetitionDays = {};
  List<int> _availableDays = [];

  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _startDate = DateTime.now();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _authService.currentUser;
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      
      // 1. Try fetching from Cloud first
      ProfileData? cloudData;
      if (user != null) {
        cloudData = await _profileService.fetchProfileFromCloud(user.uid);
      }
      
      // 2. Load JSON as a base for other settings (intervals, sources)
      final ProfileData localData = await _profileService.fetchProfileFromJson();

      if (mounted) {
        setState(() {
          // 3. Name Priority: Cloud > Google Auth > JSON
          if (cloudData != null) {
            _nameController.text = cloudData.name;
          } else if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
            _nameController.text = user.displayName!;
          } else {
            _nameController.text = localData.name;
          }

          // 4. Other settings (prefer Cloud, fallback to JSON)
          final activeData = cloudData ?? localData;
          _startDate = activeData.startDate;
          _repetitionDays = activeData.repetitionDays;
          _availableDays = activeData.availableDays;
          
          // Merge Article Sources: Keep saved preferences, add new ones from constants
          _articleSources = {};
          for (var source in AppConstants.defaultArticleSources) {
            _articleSources[source] = activeData.articleSources[source] ?? true;
          }
          
          // Merge Quiz Sources
          _quizSources = {};
          for (var source in AppConstants.defaultQuizSources) {
            _quizSources[source] = activeData.quizSources[source] ?? true;
          }
          
          // Apply theme color
          if (activeData.themeColorValue != null) {
            themeProvider.setPrimaryColor(Color(activeData.themeColorValue!));
          }

          _isDataLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
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
      return GradientBackground(
        child: Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary, strokeWidth: 1),
        ),
      );
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                    _buildIntervalsCard(context),
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
            
            // Minimal Float Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.canPop(context))
                    _buildBlurButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 44),
                  
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      final isDarkTheme = themeProvider.isDarkMode;
                      return _buildBlurButton(
                        icon: isDarkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        onTap: () => themeProvider.toggleTheme(!isDarkTheme),
                        iconColor: isDarkTheme ? Colors.amber : Colors.indigo,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurButton({required IconData icon, required VoidCallback onTap, Color? iconColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: iconColor ?? (isDark ? Colors.white70 : Colors.black54), size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final user = _authService.currentUser;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
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
          _buildModernTextField(
            controller: _nameController,
            hint: 'Your Full Name',
            label: 'FULL NAME',
          ),
          const SizedBox(height: 20),
          _buildModernDatePicker(context),
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
      onTap: () => provider.setPrimaryColor(color),
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
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
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
                  provider.setPrimaryColor(color);
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

  Widget _buildIntervalsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildModernCard(
      title: 'Study Intervals',
      icon: Icons.timer_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPETITION CYCLE (DAYS)',
            style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._availableDays.map((day) {
                final isSelected = _repetitionDays.contains(day);
                return _buildIntervalChip(day, isSelected);
              }),
              _buildAddIntervalButton(),
            ],
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
        children: sources.entries.map((e) => _buildModernSourceToggle(e.key, e.value, (val) {
          setState(() => sources[e.key] = val);
        })).toList(),
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
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
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

  Widget _buildModernTextField({required TextEditingController controller, required String hint, required String label}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        TextField(
          controller: controller,
          onChanged: (val) => setState(() {}),
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white12 : Colors.black12, fontSize: 16),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDatePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _startDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark 
                ? ColorScheme.dark(
                    primary: primaryColor,
                    surface: const Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: primaryColor,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _startDate = picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREPARATION START DATE', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_startDate.day} ${_getMonth(_startDate.month)} ${_startDate.year}',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Icon(Icons.calendar_today_rounded, size: 16, color: isDark ? Colors.white24 : Colors.black26),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
        ],
      ),
    );
  }

  Widget _buildIntervalChip(int day, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _repetitionDays.remove(day);
          } else {
            _repetitionDays.add(day);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 10)] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$day DAYS',
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _availableDays.remove(day);
                  _repetitionDays.remove(day);
                });
              },
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: isSelected ? Colors.white.withValues(alpha: 0.7) : (isDark ? Colors.white24 : Colors.black12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddIntervalButton() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: _showAddDayDialog,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Icon(Icons.add_rounded, size: 16, color: primaryColor),
      ),
    );
  }

  Widget _buildModernSourceToggle(String name, bool value, ValueChanged<bool> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isDark ? (value ? Colors.white : Colors.white38) : (value ? Colors.black87 : Colors.black26),
                  fontSize: 15,
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 38,
              height: 20,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: value ? Theme.of(context).colorScheme.primary : (isDark ? Colors.white10 : Colors.black12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFinishButton(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: () async {
        setState(() => _isDataLoading = true);
        
        final user = _authService.currentUser;
        if (user != null) {
          final profile = ProfileData(
            name: _nameController.text,
            startDate: _startDate,
            articleSources: _articleSources,
            quizSources: _quizSources,
            repetitionDays: _repetitionDays,
            availableDays: _availableDays,
            themeColorValue: themeProvider.primaryColor.toARGB32(),
          );
          await _profileService.saveProfileToCloud(user.uid, profile);
        }

        if (!mounted) return;
        setState(() => _isDataLoading = false);

        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
          ),
          (route) => false,
        );
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

  void _showAddDayDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Add Interval', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Days...',
            hintStyle: const TextStyle(color: Colors.white24),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w800))),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0 && !_availableDays.contains(val)) {
                setState(() {
                  _availableDays.add(val);
                  _availableDays.sort();
                  _repetitionDays.add(val);
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

  String _getMonth(int m) {
    return ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][m - 1];
  }
}
