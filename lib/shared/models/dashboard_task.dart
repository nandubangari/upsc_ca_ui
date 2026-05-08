import 'article_model.dart';
import 'quiz_model.dart';
import 'repetition_data.dart';

enum TaskType { normal, revision }

class DashboardTask {
  final String date;
  final int articlesDone;
  final int totalArticles;
  final int quizzesDone;
  final int totalQuizzes;
  final TaskType type;
  final int? dueDays;
  final String? lastCompleted;
  final List<RepetitionData>? repetitions;
  final List<QuizModel> quizzes;
  final List<ArticleModel> articles;

  DashboardTask({
    required this.date,
    required this.articlesDone,
    required this.totalArticles,
    required this.quizzesDone,
    required this.totalQuizzes,
    this.type = TaskType.normal,
    this.dueDays,
    this.lastCompleted,
    this.repetitions,
    this.quizzes = const [],
    this.articles = const [],
  });

  factory DashboardTask.fromJson(Map<String, dynamic> json) {
    return DashboardTask(
      date: json['date'] as String,
      articlesDone: json['articlesDone'] as int,
      totalArticles: json['totalArticles'] as int,
      quizzesDone: json['quizzesDone'] as int,
      totalQuizzes: json['totalQuizzes'] as int,
      type: TaskType.values.firstWhere((e) => e.name == (json['type'] ?? 'normal')),
      dueDays: json['dueDays'] as int?,
      lastCompleted: json['lastCompleted'] as String?,
      repetitions: json['repetitions'] != null
          ? (json['repetitions'] as List)
              .map((r) => RepetitionData.fromJson(r as Map<String, dynamic>))
              .toList()
          : null,
      quizzes: json['quizzes'] != null
          ? (json['quizzes'] as List)
              .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
              .toList()
          : [],
      articles: json['articles'] != null
          ? (json['articles'] as List)
              .map((a) => ArticleModel.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'articlesDone': articlesDone,
      'totalArticles': totalArticles,
      'quizzesDone': quizzesDone,
      'totalQuizzes': totalQuizzes,
      'type': type.name,
      'dueDays': dueDays,
      'lastCompleted': lastCompleted,
      'repetitions': repetitions?.map((r) => r.toJson()).toList(),
      'quizzes': quizzes.map((q) => q.toJson()).toList(),
      'articles': articles.map((a) => a.toJson()).toList(),
    };
  }

  bool get isFullyCompleted => (totalArticles + totalQuizzes) > 0 && 
                               (articlesDone + quizzesDone) == (totalArticles + totalQuizzes);

  DateTime get isoDate {
    try {
      return DateTime.parse(_toIsoDate(date));
    } catch (_) {
      return DateTime(2000);
    }
  }

  String _toIsoDate(String dateStr) {
    try {
      return DateTime.parse(dateStr).toIso8601String().split('T')[0];
    } catch (_) {
      try {
        final parts = dateStr.split(' ');
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final monthStr = parts[1].toUpperCase();
          final year = parts[2];
          final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
          final monthIdx = months.indexOf(monthStr) + 1;
          if (monthIdx > 0) return '$year-${monthIdx.toString().padLeft(2, '0')}-$day';
        }
      } catch (_) {}
      return "0000-00-00";
    }
  }

  DashboardTask copyWith({
    String? date,
    int? articlesDone,
    int? totalArticles,
    int? quizzesDone,
    int? totalQuizzes,
    TaskType? type,
    int? dueDays,
    String? lastCompleted,
    List<RepetitionData>? repetitions,
    List<QuizModel>? quizzes,
    List<ArticleModel>? articles,
  }) {
    return DashboardTask(
      date: date ?? this.date,
      articlesDone: articlesDone ?? this.articlesDone,
      totalArticles: totalArticles ?? this.totalArticles,
      quizzesDone: quizzesDone ?? this.quizzesDone,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      type: type ?? this.type,
      dueDays: dueDays ?? this.dueDays,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      repetitions: repetitions ?? this.repetitions,
      quizzes: quizzes ?? this.quizzes,
      articles: articles ?? this.articles,
    );
  }
}
