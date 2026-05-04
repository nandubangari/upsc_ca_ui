class ProfileData {
  final String name;
  final DateTime startDate;
  final Map<String, bool> articleSources;
  final Map<String, bool> quizSources;
  final Set<int> repetitionDays;
  final List<int> availableDays;
  final int? themeColorValue; // Added to sync theme color
  final DateTime? examDate; // Target exam date for countdown

  ProfileData({
    required this.name,
    required this.startDate,
    required this.articleSources,
    required this.quizSources,
    required this.repetitionDays,
    required this.availableDays,
    this.themeColorValue,
    this.examDate,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      articleSources: Map<String, bool>.from(json['articleSources'] as Map),
      quizSources: Map<String, bool>.from(json['quizSources'] as Map),
      repetitionDays: Set<int>.from(json['repetitionDays'] as List),
      availableDays: List<int>.from(json['availableDays'] as List),
      themeColorValue: json['themeColorValue'] as int?,
      examDate: json['examDate'] != null ? DateTime.parse(json['examDate'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'startDate': startDate.toIso8601String(),
      'articleSources': articleSources,
      'quizSources': quizSources,
      'repetitionDays': repetitionDays.toList(),
      'availableDays': availableDays,
      'themeColorValue': themeColorValue,
      'examDate': examDate?.toIso8601String(),
    };
  }

  factory ProfileData.fromFirestore(Map<String, dynamic> doc) {
    return ProfileData.fromJson(doc);
  }

  Map<String, dynamic> toFirestore() {
    return toJson();
  }
}
