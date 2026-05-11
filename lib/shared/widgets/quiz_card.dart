import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/features/web_view/screens/web_view_screen.dart';
import 'package:upsc_ca_ui/providers/dashboard_provider.dart';

class QuizCard extends StatelessWidget {
  final QuizModel quiz;
  final DashboardTask? task;

  const QuizCard({
    super.key,
    required this.quiz,
    this.task,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);

    return Selector<DashboardProvider, bool>(
      selector: (_, p) => p.isQuizCompleted(quiz.source, quiz.title),
      builder: (context, isCompleted, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCompleted ? cardColor.withValues(alpha: 0.5) : cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted ? Colors.green.withValues(alpha: 0.5) : borderColor,
              width: 1,
            ),
            boxShadow: [
              if (!isCompleted && !isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: InkWell(
            onTap: () {
              if (quiz.url != null && task != null) {
                unawaited(Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(
                      url: quiz.url!,
                      title: quiz.title,
                      task: task,
                      quiz: quiz,
                    ),
                  ),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(quiz.url == null ? 'No URL available' : 'Task data missing')),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: quiz.source,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' — ${quiz.title}',
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isCompleted)
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18)
                  else
                    Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black12, size: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

