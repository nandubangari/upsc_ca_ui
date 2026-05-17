import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/repetition_data.dart';
import 'progress_bar.dart';
import 'package:upsc_ca_ui/features/home/screens/task_detail_screen.dart';
import 'package:upsc_ca_ui/providers/dashboard_provider.dart';
import 'package:upsc_ca_ui/shared/widgets/premium_gate.dart';
import 'package:upsc_ca_ui/features/subscription/screens/subscription_screen.dart';

class TaskCard extends StatelessWidget {
  final String date;

  static const _microStatSpacing = SizedBox(width: 12);
  static const _verticalSpacing = SizedBox(height: 4);

  const TaskCard({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardProvider, (bool, TaskType, int?, bool, List<RepetitionData>?)?>(
      selector: (_, p) {
        final task = p.getTaskByDate(date);
        if (task == null) return null;
        return (
          task.repetitions != null,
          task.type,
          task.dueDays,
          task.isOverdue,
          task.repetitions,
        );
      },
      builder: (context, data, _) {
        if (data == null) return const SizedBox.shrink();
        final (hasAnalyticalData, taskType, dueDays, isOverdue, repetitions) = data;

        final isRevision = taskType == TaskType.revision;

        // Only show completed card if it's NOT a revision task and has analytical data
        if (hasAnalyticalData && !isRevision) {
          final task = context.read<DashboardProvider>().getTaskByDate(date);
          if (task == null) return const SizedBox.shrink();
          return CompletedTaskCard(task: task);
        }
        
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).colorScheme.primary;
        final statusColor = isOverdue ? Colors.redAccent : primaryColor;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 78, // Fixed height to match SliverFixedExtentList itemExtent (88 - 10 margin)
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final task = context.read<DashboardProvider>().getTaskByDate(date);
                if (task != null) {
                  unawaited(Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
                  ));
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isRevision 
                        ? statusColor.withValues(alpha: 0.3)
                        : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (isRevision)
                      Container(
                        width: 3,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 4),
                          ],
                        ),
                      ),
                    
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                date,
                                style: TextStyle(
                                  color: isRevision ? statusColor : (isDark ? Colors.white : Colors.black87),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (isOverdue) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
                                  ),
                                  child: const Text(
                                    'OVERDUE',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          _verticalSpacing,
                          Selector<DashboardProvider, String>(
                            selector: (_, p) {
                              final stats = p.getTaskStats(date);
                              return '${stats['articlesDone']}/${stats['totalArticles']}/${stats['quizzesDone']}/${stats['totalQuizzes']}';
                            },
                            builder: (context, statsStr, _) {
                              final parts = statsStr.split('/');
                              return Row(
                                children: [
                                  _MicroStat(icon: Icons.article_rounded, text: '${parts[0]}/${parts[1]}'),
                                  _microStatSpacing,
                                  _MicroStat(icon: Icons.quiz_rounded, text: '${parts[2]}/${parts[3]}'),
                                  if (isRevision) ...[
                                    const Spacer(),
                                    Text(
                                      'REVISION · ROUND $dueDays',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }
                          ),
                        ],
                      ),
                    ),
                    
                    if (!isRevision) 
                      Selector<DashboardProvider, double>(
                        selector: (_, p) => p.getTaskProgress(date),
                        builder: (context, progress, _) {
                          return ProgressBar(progress: progress);
                        }
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MicroStat extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MicroStat({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
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
                      unawaited(Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TaskDetailScreen(task: widget.task)),
                      ));
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
                        const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Colors.white38,
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
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isExpanded 
              ? PremiumGate(
                  subtitle: "Detailed preparation analytics are premium",
                  child: RepaintBoundary(child: _AnalyticsGrid(task: widget.task)),
                )
              : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  final DashboardTask task;
  const _AnalyticsGrid({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          ...task.repetitions!.map((r) => _MicroRepetitionRow(r: r)),
        ],
      ),
    );
  }
}

class _MicroRepetitionRow extends StatelessWidget {
  final RepetitionData r;
  const _MicroRepetitionRow({required this.r});

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _MicroMetric(label: 'TOTAL QNS', value: '${r.totalQuestions}'),
              _MicroMetric(label: 'ATTEMPTED', value: '${r.attempted}'),
              _MicroMetric(label: 'UNATTEMPTED', value: '${r.notAttempted}'),
              _MicroMetric(label: 'WRONG', value: '${r.wrong}', color: Colors.redAccent),
              _MicroMetric(
                label: 'ACCURACY', 
                value: '${r.accuracy.toInt()}%', 
                color: r.accuracy > 80 ? Colors.green : primaryColor,
                isBold: true,
              ),
              _MicroMetric(label: 'SCORE', value: '${r.score}/${r.totalMarks}', isBold: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicroMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool isBold;

  const _MicroMetric({
    required this.label,
    required this.value,
    this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white12, fontSize: 8, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white60,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
