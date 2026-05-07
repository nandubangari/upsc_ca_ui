import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/gradient_background.dart';
import '../models/dashboard_data.dart';
import '../providers/dashboard_provider.dart';
import 'article_reader_screen.dart';
import 'common_web_view_screen.dart';

class DayDetailScreen extends StatelessWidget {
  final DashboardTask task;

  const DayDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        final currentTask = _findLatestTask(provider, task.date) ?? task;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        // Sort items: Completed at the end
        final sortedQuizzes = List<QuizDetail>.from(currentTask.quizzes)
          ..sort((a, b) => a.isCompleted == b.isCompleted ? 0 : (a.isCompleted ? 1 : -1));
        final sortedArticles = List<ArticleDetail>.from(currentTask.articles)
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

                if (isTablet) {
                  return _buildTabletLayout(context, sortedQuizzes, sortedArticles, currentTask);
                } else if (isLandscape) {
                  return _buildLandscapeLayout(context, sortedQuizzes, sortedArticles, currentTask);
                } else {
                  return _buildPortraitLayout(context, sortedQuizzes, sortedArticles, currentTask);
                }
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

  Widget _buildPortraitLayout(BuildContext context, List<QuizDetail> quizzes, List<ArticleDetail> articles, DashboardTask currentTask) {
    final groupedArticles = _groupArticlesBySource(articles);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(context, 'ARTICLES'),
          ...groupedArticles.entries.map((entry) => _buildSourceGroup(context, entry.key, entry.value, articles, currentTask)),
          const SizedBox(height: 32),
          _buildSectionHeader(context, 'QUIZZES'),
          ...quizzes.map((q) => _buildQuizCard(context, q, currentTask)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, List<QuizDetail> quizzes, List<ArticleDetail> articles, DashboardTask currentTask) {
    final groupedArticles = _groupArticlesBySource(articles);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 10, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'ARTICLES'),
                ...groupedArticles.entries.map((entry) => _buildSourceGroup(context, entry.key, entry.value, articles, currentTask)),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 10, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'QUIZZES'),
                ...quizzes.map((q) => _buildQuizCard(context, q, currentTask)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<ArticleDetail>> _groupArticlesBySource(List<ArticleDetail> articles) {
    final groups = <String, List<ArticleDetail>>{};
    for (var a in articles) {
      final source = a.source ?? 'Other Sources';
      groups.putIfAbsent(source, () => []).add(a);
    }
    return groups;
  }

  Widget _buildSourceGroup(BuildContext context, String sourceName, List<ArticleDetail> articlesInGroup, List<ArticleDetail> allArticles, DashboardTask currentTask) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
          child: Text(
            sourceName.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...articlesInGroup.map((a) => _buildArticleCard(context, a, allArticles, currentTask)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, List<QuizDetail> quizzes, List<ArticleDetail> articles, DashboardTask currentTask) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: _buildLandscapeLayout(context, quizzes, articles, currentTask),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, QuizDetail quiz, DashboardTask currentTask) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: quiz.isCompleted ? cardColor.withValues(alpha: 0.5) : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quiz.isCompleted ? Colors.green.withValues(alpha: 0.5) : borderColor,
          width: 1,
        ),
        boxShadow: [
          if (!quiz.isCompleted && !isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (quiz.url != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CommonWebViewScreen(
                  url: quiz.url!,
                  title: quiz.title,
                  task: currentTask,
                  quiz: quiz,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No URL available for this quiz')),
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
              if (quiz.isCompleted)
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18)
              else
                Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black12, size: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, ArticleDetail article, List<ArticleDetail> allArticles, DashboardTask currentTask) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Reduced margin for compact look
      decoration: BoxDecoration(
        color: article.isCompleted ? cardColor.withValues(alpha: 0.5) : cardColor,
        borderRadius: BorderRadius.circular(10), // Slightly smaller radius
        border: Border.all(
          color: article.isCompleted 
              ? Colors.green.withValues(alpha: 0.5) 
              : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: InkWell(
        onTap: () {
          if (article.url != null) {
            if (article.isCustom) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommonWebViewScreen(
                    url: article.url!,
                    title: article.title,
                    task: currentTask,
                    article: article,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleReaderScreen(
                    initialUrl: article.url,
                  ),
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No URL available for this article')),
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // Reduced padding
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title, // Topic Heading
                      maxLines: 3, // Increased lines slightly since subtitle is gone
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w800, // Stronger weight for heading
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (article.isCompleted)
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16)
              else
                Icon(Icons.arrow_forward_ios_rounded, 
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black12,
                  size: 12),
            ],
          ),
        ),
      ),
    );
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final source = sourceController.text;
                final title = titleController.text.isEmpty ? source : titleController.text;
                final url = urlController.text.isEmpty ? null : urlController.text;

                Navigator.pop(context);
                await provider.addCustomTask(date, source, title, url);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }
}
