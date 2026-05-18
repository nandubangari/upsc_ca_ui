import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/providers/dashboard_provider.dart';
import 'package:upsc_ca_ui/shared/widgets/premium_gate.dart';
import 'package:upsc_ca_ui/core/utils/link_launcher_utils.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  final DashboardTask? task;

  const ArticleCard({
    super.key,
    required this.article,
    this.task,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Selector<DashboardProvider, bool>(
      selector: (_, p) => p.isArticleCompleted(article.url),
      builder: (context, isCompleted, child) {
        Widget content = RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isCompleted ? cardColor.withValues(alpha: 0.5) : cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCompleted 
                    ? Colors.green.withValues(alpha: 0.5) 
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
              ),
            ),
            child: InkWell(
              onTap: () async {
                final profile = await ProfileService().getProfile();
                final preference = profile?.readingPreference ?? 'internal_browser';
                
                if (context.mounted) {
                  await LinkLauncherUtils.launchArticle(
                    context: context,
                    article: article,
                    preference: preference,
                    task: task,
                  );
                }
              },
              onLongPress: article.isCustom ? () async {
                final confirmed = await _showDeleteConfirmation(context);
                if (confirmed && context.mounted) {
                  context.read<DashboardProvider>().deleteCustomTask(task!.date, article.url!);
                }
              } : null,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCompleted)
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16)
                    else
                      Icon(Icons.arrow_forward_ios_rounded, 
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black12,
                        size: 12),
                  ],
                ),
              ),
            ),
          ),
        );

        if (article.isCustom && task != null) {
          return Dismissible(
            key: Key('custom-task-${article.url}-${task!.date}'),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
            ),
            confirmDismiss: (direction) => _showDeleteConfirmation(context),
            onDismissed: (direction) {
              context.read<DashboardProvider>().deleteCustomTask(task!.date, article.url!);
            },
            child: content,
          );
        }

        return content;
      },
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete "${article.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (result == true && article.isCustom && task != null) {
      // If triggered by long press, we need to call delete manually
      // If triggered by swipe, Dismissible handles it in onDismissed
      // This is a bit tricky, so we'll just return the result for Dismissible
      // and let the caller handle manual deletion if needed.
    }
    return result ?? false;
  }
}
