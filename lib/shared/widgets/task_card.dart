import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/repetition_data.dart';
import 'progress_bar.dart';
import 'package:upsc_ca_ui/features/home/screens/task_detail_screen.dart';
import 'package:upsc_ca_ui/providers/dashboard_provider.dart';

class TaskCard extends StatelessWidget {
  final DashboardTask task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
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
            unawaited(Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
            ));
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isRevision 
                    ? primaryColor.withValues(alpha: 0.3)
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
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
                        BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 4),
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
                      Selector<DashboardProvider, String>(
                        selector: (_, p) {
                          final stats = p.getTaskStats(task.date);
                          return '${stats['articlesDone']}/${stats['totalArticles']}/${stats['quizzesDone']}/${stats['totalQuizzes']}';
                        },
                        builder: (context, statsStr, _) {
                          final parts = statsStr.split('/');
                          return Row(
                            children: [
                              _buildMicroStat(context, Icons.article_rounded, '${parts[0]}/${parts[1]}'),
                              const SizedBox(width: 12),
                              _buildMicroStat(context, Icons.quiz_rounded, '${parts[2]}/${parts[3]}'),
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
                          );
                        }
                      ),
                    ],
                  ),
                ),
                
                if (!isRevision) 
                  Selector<DashboardProvider, double>(
                    selector: (_, p) => p.getTaskProgress(task.date),
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
                        Text(
                          'COMPLETED', // Or actual completion/revision info
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38, 
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
            secondChild: _isExpanded ? _buildAnalyticsGrid(context) : const SizedBox(width: double.infinity),
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
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1), height: 1),
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

