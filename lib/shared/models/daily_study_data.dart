import 'article_model.dart';
import 'quiz_model.dart';

class DailyStudyData {
  final String date;
  final List<ArticleModel> items;
  final List<QuizModel> quizzes;

  DailyStudyData({
    required this.date,
    required this.items,
    this.quizzes = const [],
  });

  factory DailyStudyData.fromJson(Map<String, dynamic> json) {
    return DailyStudyData(
      date: json['date'] as String,
      items: (json['items'] as List)
          .map((i) => ArticleModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      quizzes: json['quizzes'] != null
          ? (json['quizzes'] as List)
              .map((q) => QuizModel.fromJson(q as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'items': items.map((i) => i.toJson()).toList(),
      'quizzes': quizzes.map((q) => q.toJson()).toList(),
    };
  }
}
