class QuizModel {
  final String source;
  final String title;
  final bool isCompleted;
  final String? url;
  final String? completedAt;
  final String? date;

  QuizModel({
    required this.source,
    required this.title,
    this.isCompleted = false,
    this.url,
    this.completedAt,
    this.date,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      source: json['source'] as String? ?? 'Unknown',
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      url: json['url'] as String?,
      completedAt: json['completedAt'] as String?,
      date: json['date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'title': title,
      'isCompleted': isCompleted,
      'url': url,
      'completedAt': completedAt,
      'date': date,
    };
  }

  QuizModel copyWith({
    String? source,
    String? title,
    bool? isCompleted,
    String? url,
    String? completedAt,
    String? date,
  }) {
    return QuizModel(
      source: source ?? this.source,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      url: url ?? this.url,
      completedAt: completedAt ?? this.completedAt,
      date: date ?? this.date,
    );
  }
}
