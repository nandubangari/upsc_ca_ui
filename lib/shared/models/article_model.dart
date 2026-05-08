class ArticleModel {
  final String title;
  final String? subtitle;
  final String? url;
  final String? source;
  final bool isCompleted;
  final bool isCustom;
  final String? completedAt;
  final String? date; // Used in some contexts like synced articles

  ArticleModel({
    required this.title,
    this.subtitle,
    this.url,
    this.source,
    this.isCompleted = false,
    this.isCustom = false,
    this.completedAt,
    this.date,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    String? subtitle = json['subtitle'] as String?;
    if (subtitle?.toLowerCase() == "null") subtitle = null;
    
    return ArticleModel(
      title: json['title'] as String,
      subtitle: subtitle,
      url: json['url'] as String?,
      source: json['source'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
      completedAt: json['completedAt'] as String?,
      date: json['date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'url': url,
      'source': source,
      'isCompleted': isCompleted,
      'isCustom': isCustom,
      'completedAt': completedAt,
      'date': date,
    };
  }

  ArticleModel copyWith({
    String? title,
    String? subtitle,
    String? url,
    String? source,
    bool? isCompleted,
    bool? isCustom,
    String? completedAt,
    String? date,
  }) {
    return ArticleModel(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      url: url ?? this.url,
      source: source ?? this.source,
      isCompleted: isCompleted ?? this.isCompleted,
      isCustom: isCustom ?? this.isCustom,
      completedAt: completedAt ?? this.completedAt,
      date: date ?? this.date,
    );
  }
}
