import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/features/reader/screens/article_reader_screen.dart';
import 'package:upsc_ca_ui/features/web_view/screens/web_view_screen.dart';
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
        return RepaintBoundary(
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
      },
    );
  }
}
