import 'dashboard_data.dart';

class StudyItem {
  String title;
  String? subtitle;
  final String url;
  final String? date;
  String? source;
  bool isCompleted;
  bool isCustom;
  String? completedAt; // Added

  StudyItem({
    required this.title,
    this.subtitle,
    required this.url,
    this.date,
    this.source,
    this.isCompleted = false,
    this.isCustom = false,
    this.completedAt,
  });

  factory StudyItem.fromJson(Map<String, dynamic> json) {
    String? subtitle = json['subtitle'] as String?;
    if (subtitle?.toLowerCase() == "null") subtitle = null;
    
    return StudyItem(
      title: json['title'] as String,
      subtitle: subtitle,
      url: json['url'] as String,
      date: json['date'] as String?,
      source: json['source'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
      completedAt: json['completedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'url': url,
      'date': date,
      'source': source,
      'isCompleted': isCompleted,
      'isCustom': isCustom,
      'completedAt': completedAt,
    };
  }
}

class DailyStudyData {
  final String date;
  final List<StudyItem> items;
  final List<QuizDetail> quizzes; // Added quizzes support

  DailyStudyData({
    required this.date,
    required this.items,
    this.quizzes = const [],
  });

  factory DailyStudyData.fromJson(Map<String, dynamic> json) {
    return DailyStudyData(
      date: json['date'] as String,
      items: (json['items'] as List)
          .map((i) => StudyItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      quizzes: json['quizzes'] != null
          ? (json['quizzes'] as List)
              .map((q) => QuizDetail.fromJson(q as Map<String, dynamic>))
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
