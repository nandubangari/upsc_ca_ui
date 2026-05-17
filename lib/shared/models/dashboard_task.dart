import 'article_model.dart';
import 'quiz_model.dart';
import 'repetition_data.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';

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
  final bool isOverdue;
  final List<RepetitionData>? repetitions;
  final List<QuizModel> quizzes;
  final List<ArticleModel> articles;
  
  // Optimization: Store pre-parsed date
  final DateTime isoDate;

  DashboardTask({
    required this.date,
    required this.articlesDone,
    required this.totalArticles,
    required this.quizzesDone,
    required this.totalQuizzes,
    this.type = TaskType.normal,
    this.dueDays,
    this.lastCompleted,
    this.isOverdue = false,
    this.repetitions,
    this.quizzes = const [],
    this.articles = const [],
    DateTime? isoDate,
  }) : isoDate = isoDate ?? DateFormatter.parseAny(date);

  factory DashboardTask.fromJson(Map<String, dynamic> json) {
    final String date = json['date'] as String;
    return DashboardTask(
      date: date,
      articlesDone: json['articlesDone'] as int,
      totalArticles: json['totalArticles'] as int,
      quizzesDone: json['quizzesDone'] as int,
      totalQuizzes: json['totalQuizzes'] as int,
      type: TaskType.values.firstWhere((e) => e.name == (json['type'] ?? 'normal')),
      dueDays: json['dueDays'] as int?,
      lastCompleted: json['lastCompleted'] as String?,
      isOverdue: json['isOverdue'] as bool? ?? false,
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
      isoDate: DateFormatter.parseAny(date),
    );
  }

  bool get isFullyCompleted => (totalArticles + totalQuizzes) > 0 && 
                               (articlesDone + quizzesDone) == (totalArticles + totalQuizzes);

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
      'isOverdue': isOverdue,
      'repetitions': repetitions?.map((r) => r.toJson()).toList(),
      'quizzes': quizzes.map((q) => q.toJson()).toList(),
      'articles': articles.map((a) => a.toJson()).toList(),
    };
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
    bool? isOverdue,
    List<RepetitionData>? repetitions,
    List<QuizModel>? quizzes,
    List<ArticleModel>? articles,
    DateTime? isoDate,
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
      isOverdue: isOverdue ?? this.isOverdue,
      repetitions: repetitions ?? this.repetitions,
      quizzes: quizzes ?? this.quizzes,
      articles: articles ?? this.articles,
      isoDate: isoDate ?? this.isoDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardTask &&
        other.date == date &&
        other.articlesDone == articlesDone &&
        other.totalArticles == totalArticles &&
        other.quizzesDone == quizzesDone &&
        other.totalQuizzes == totalQuizzes &&
        other.type == type &&
        other.dueDays == dueDays &&
        other.lastCompleted == lastCompleted &&
        other.isOverdue == isOverdue;
  }

  @override
  int get hashCode =>
      date.hashCode ^
      articlesDone.hashCode ^
      totalArticles.hashCode ^
      quizzesDone.hashCode ^
      totalQuizzes.hashCode ^
      type.hashCode ^
      dueDays.hashCode ^
      lastCompleted.hashCode ^
      isOverdue.hashCode;
}
