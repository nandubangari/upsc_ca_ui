import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/widgets/section_header.dart';
import 'package:upsc_ca_ui/shared/widgets/article_card.dart';
import 'package:upsc_ca_ui/shared/widgets/quiz_card.dart';
import 'package:upsc_ca_ui/shared/widgets/gradient_background.dart';




import 'package:upsc_ca_ui/providers/dashboard_provider.dart';


class TaskDetailScreen extends StatelessWidget {
  final DashboardTask task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final currentTask = _findLatestTask(provider, task.date) ?? task;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        // Sort items: Completed at the end
        final sortedQuizzes = List<QuizModel>.from(currentTask.quizzes)
          ..sort((a, b) => a.isCompleted == b.isCompleted ? 0 : (a.isCompleted ? 1 : -1));
        final sortedArticles = List<ArticleModel>.from(currentTask.articles)
          ..sort((a, b) => a.isCompleted == b.isCompleted ? 0 : (a.isCompleted ? 1 : -1));

        return GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.add_rounded, color: isDark ? Colors.white : Colors.black87, size: 24),
                  onPressed: () => _showAddTaskDialog(context, provider, currentTask.date),
                ),
                const SizedBox(width: 8),
              ],
              centerTitle: true,
              title: Text(
                currentTask.date,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 600;
                final isLandscape = constraints.maxWidth > constraints.maxHeight && !isTablet;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: isTablet
                      ? _buildTabletSlivers(context, sortedQuizzes, sortedArticles, currentTask)
                      : isLandscape
                          ? _buildLandscapeSlivers(context, sortedQuizzes, sortedArticles, currentTask)
                          : _buildPortraitSlivers(context, sortedQuizzes, sortedArticles, currentTask),
                );
              },
            ),
          ),
        );
      },
    );
  }

  DashboardTask? _findLatestTask(DashboardProvider provider, String date) {
    if (provider.data == null) return null;
    try {
      return provider.data!.allTasks.firstWhere((t) => t.date == date);
    } catch (_) {
      return null;
    }
  }

  List<Widget> _buildPortraitSlivers(BuildContext context, List<QuizModel> quizzes, List<ArticleModel> articles, DashboardTask currentTask) {
    final groupedArticles = _groupArticlesBySource(articles);
    final slivers = <Widget>[];

    slivers.add(const SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
      sliver: SliverToBoxAdapter(child: SectionHeader(title: 'ARTICLES')),
    ));

    for (var entry in groupedArticles.entries) {
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
            child: Text(
              entry.key.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ));
      
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => ArticleCard(article: entry.value[index], task: currentTask),
            childCount: entry.value.length,
          ),
        ),
      ));
    }

    slivers.add(const SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
      sliver: SliverToBoxAdapter(child: SectionHeader(title: 'QUIZZES')),
    ));

    slivers.add(SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => QuizCard(quiz: quizzes[index], task: currentTask),
          childCount: quizzes.length,
        ),
      ),
    ));

    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 40)));
    
    return slivers;
  }

  List<Widget> _buildLandscapeSlivers(BuildContext context, List<QuizModel> quizzes, List<ArticleModel> articles, DashboardTask currentTask) {
    return _buildWideVirtualizedSlivers(context, quizzes, articles, currentTask);
  }

  List<Widget> _buildTabletSlivers(BuildContext context, List<QuizModel> quizzes, List<ArticleModel> articles, DashboardTask currentTask) {
    return _buildWideVirtualizedSlivers(context, quizzes, articles, currentTask);
  }

  List<Widget> _buildWideVirtualizedSlivers(BuildContext context, List<QuizModel> quizzes, List<ArticleModel> articles, DashboardTask currentTask) {
    final groupedArticles = _groupArticlesBySource(articles);
    
    // Define the builders for each column to maintain virtualization
    final leftSide = <Widget Function(BuildContext)>[];
    final rightSide = <Widget Function(BuildContext)>[];

    // Articles Column
    leftSide.add((_) => const SectionHeader(title: 'ARTICLES'));
    for (var entry in groupedArticles.entries) {
      leftSide.add((context) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
        child: Text(
          entry.key.toUpperCase(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ));
      
      for (var a in entry.value) {
        leftSide.add((_) => ArticleCard(article: a, task: currentTask));
      }
      leftSide.add((_) => const SizedBox(height: 16));
    }

    // Quizzes Column
    rightSide.add((_) => const SectionHeader(title: 'QUIZZES'));
    for (var q in quizzes) {
      rightSide.add((_) => QuizCard(quiz: q, task: currentTask));
    }

    final rowCount = (leftSide.length > rightSide.length) ? leftSide.length : rightSide.length;

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: index < leftSide.length ? leftSide[index](context) : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: index < rightSide.length ? rightSide[index](context) : const SizedBox.shrink(),
                  ),
                ],
              );
            },
            childCount: rowCount,
          ),
        ),
      ),
    ];
  }

  Map<String, List<ArticleModel>> _groupArticlesBySource(List<ArticleModel> articles) {
    final groups = <String, List<ArticleModel>>{};
    for (var a in articles) {
      final source = a.source ?? 'Other Sources';
      groups.putIfAbsent(source, () => []).add(a);
    }
    return groups;
  }

  void _showAddTaskDialog(BuildContext context, DashboardProvider provider, String date) {
    final sourceController = TextEditingController();
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Task', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: sourceController,
                  decoration: const InputDecoration(
                    labelText: 'Source*',
                    hintText: 'e.g., The Hindu, IE, YouTube',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Source is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title (Optional)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL (Optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => unawaited(() async {
              if (formKey.currentState!.validate()) {
                final source = sourceController.text;
                final title = titleController.text.isEmpty ? source : titleController.text;
                final url = urlController.text.isEmpty ? null : urlController.text;

                Navigator.pop(context);
                unawaited(provider.addCustomTask(date, source, title, url));
              }
            }()),
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }
}

































