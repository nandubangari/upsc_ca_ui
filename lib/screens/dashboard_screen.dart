import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/gradient_background.dart';
import '../models/dashboard_data.dart';
import '../providers/dashboard_provider.dart';
import '../services/auth_service.dart';
import 'day_detail_screen.dart';
import 'profile_setup_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          );
        } else if (provider.error != null) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadDashboardData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (provider.data == null) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Scaffold(
            body: Center(child: Text('No data found', style: TextStyle(color: isDark ? Colors.white : Colors.black87))),
          );
        }

        final data = provider.data!;
        return GradientBackground(
          child: Column(
            children: [
              _buildTopBar(context, data.daysLeft),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 700;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: isWide ? _buildWideLayout(context, data) : _buildNarrowLayout(context, data),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, int daysLeft) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final user = AuthService().currentUser;
    final provider = context.watch<DashboardProvider>();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundImage: user?.photoURL != null 
                        ? NetworkImage(user!.photoURL!)
                        : const NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Nandhu'),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      provider.isSyncing ? Icons.sync_disabled : Icons.sync,
                      size: 20,
                      color: provider.isSyncing ? Colors.grey : primaryColor,
                    ),
                    onPressed: provider.isSyncing ? null : () => provider.syncAllArticles(forceRefresh: true),
                    tooltip: 'Sync Sources',
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          '$daysLeft DAYS LEFT',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (provider.isSyncing && provider.syncStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.syncStatus!,
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Today\'s Tasks'),
        ...data.todayTasks.map((t) => _buildTaskCard(context, t)),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Not Started'),
        ...data.notStartedTasks.map((t) => _buildTaskCard(context, t)),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Completed History'),
        ...data.completedTasks.map((t) => _buildTaskCard(context, t)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Today\'s Tasks'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 10,
            mainAxisExtent: 80,
          ),
          itemCount: data.todayTasks.length,
          itemBuilder: (context, index) => _buildTaskCard(context, data.todayTasks[index]),
        ),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'Not Started'),
                  ...data.notStartedTasks.map((t) => _buildTaskCard(context, t)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'Completed'),
                  ...data.completedTasks.map((t) => _buildTaskCard(context, t)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white24 : Colors.black45,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, DashboardTask task) {
    if (task.repetitions != null) {
      return CompletedTaskCard(task: task);
    }
    
    final isRevision = task.type == TaskType.revision;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DayDetailScreen(task: task)),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isRevision 
                    ? primaryColor.withValues(alpha: 0.2)
                    : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05)),
                width: 1,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                if (isRevision)
                  Container(
                    width: 3,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 4),
                      ],
                    ),
                  ),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        task.date,
                        style: TextStyle(
                          color: isRevision ? primaryColor : (isDark ? Colors.white : Colors.black87),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildMicroStat(context, Icons.article_rounded, '${task.articlesDone}/${task.totalArticles}'),
                          const SizedBox(width: 12),
                          _buildMicroStat(context, Icons.quiz_rounded, '${task.quizzesDone}/${task.totalQuizzes}'),
                          if (isRevision) ...[
                            const Spacer(),
                            Text(
                              'DUE IN ${task.dueDays}D',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                if (!isRevision) _buildLinearProgress(context, task),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicroStat(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 10, color: isDark ? Colors.white24 : Colors.black26),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLinearProgress(BuildContext context, DashboardTask task) {
    final progress = (task.articlesDone + task.quizzesDone) / (task.totalArticles + task.totalQuizzes);
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.05, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class CompletedTaskCard extends StatefulWidget {
  final DashboardTask task;
  const CompletedTaskCard({super.key, required this.task});

  @override
  State<CompletedTaskCard> createState() => _CompletedTaskCardState();
}

class _CompletedTaskCardState extends State<CompletedTaskCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.green, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DayDetailScreen(task: widget.task)),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.date,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'REVISION: 10/04/2026',
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black38, 
                            fontSize: 9, 
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white12 : Colors.black12,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildAnalyticsGrid(context),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          ...widget.task.repetitions!.map((r) => _buildMicroRepetitionRow(context, r)),
        ],
      ),
    );
  }

  Widget _buildMicroRepetitionRow(BuildContext context, RepetitionData r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REPETITION ${r.number}',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${r.date.day}/${r.date.month}/${r.date.year}',
                style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _buildMicroMetric(context, 'TOTAL QNS', '${r.totalQuestions}'),
              _buildMicroMetric(context, 'ATTEMPTED', '${r.attempted}'),
              _buildMicroMetric(context, 'UNATTEMPTED', '${r.notAttempted}'),
              _buildMicroMetric(context, 'WRONG', '${r.wrong}', color: Colors.redAccent),
              _buildMicroMetric(context, 'ACCURACY', '${r.accuracy.toInt()}%', 
                color: r.accuracy > 80 ? Colors.green : primaryColor,
                isBold: true,
              ),
              _buildMicroMetric(context, 'SCORE', '${r.score}/${r.totalMarks}', isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroMetric(BuildContext context, String label, String value, {Color? color, bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white12 : Colors.black26, fontSize: 8, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? (isDark ? Colors.white60 : Colors.black87),
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
