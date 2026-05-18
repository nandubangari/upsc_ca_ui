class ProfileData {
  final String name;
  final DateTime joinedAt;
  final DateTime startDate;
  final Map<String, bool> articleSources;
  final Map<String, bool> quizSources;
  final List<int> repetitionIntervals;
  final int? themeColorValue; // Added to sync theme color
  final DateTime? examDate; // Target exam date for countdown
  final String readingPreference; // reader, custom_tabs, internal_browser

  // Subscription & Access Control
  final bool isPremium;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final String? subscriptionPlan; // monthly, quarterly, yearly
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final bool manualPremium;
  final String? manualPremiumReason;
  final String? purchasePlatform;
  final DateTime? lastValidationAt;

  ProfileData({
    required this.name,
    required this.joinedAt,
    required this.startDate,
    required this.articleSources,
    required this.quizSources,
    this.repetitionIntervals = const [1, 7, 30, 120, 300],
    this.themeColorValue,
    this.examDate,
    this.readingPreference = 'internal_browser',
    this.isPremium = false,
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionPlan,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.manualPremium = false,
    this.manualPremiumReason,
    this.purchasePlatform,
    this.lastValidationAt,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      name: json['name'] as String,
      joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt'] as String) : DateTime.now(),
      startDate: DateTime.parse(json['startDate'] as String),
      articleSources: Map<String, bool>.from(json['articleSources'] as Map),
      quizSources: Map<String, bool>.from(json['quizSources'] as Map),
      repetitionIntervals: json['repetitionIntervals'] != null 
          ? List<int>.from(json['repetitionIntervals'] as List)
          : const [1, 7, 30, 120, 300],
      themeColorValue: json['themeColorValue'] as int?,
      examDate: json['examDate'] != null ? DateTime.parse(json['examDate'] as String) : null,
      readingPreference: json['readingPreference'] as String? ?? 'internal_browser',
      isPremium: json['isPremium'] as bool? ?? false,
      trialStartDate: json['trialStartDate'] != null ? DateTime.parse(json['trialStartDate'] as String) : null,
      trialEndDate: json['trialEndDate'] != null ? DateTime.parse(json['trialEndDate'] as String) : null,
      subscriptionPlan: json['subscriptionPlan'] as String?,
      subscriptionStartDate: json['subscriptionStartDate'] != null ? DateTime.parse(json['subscriptionStartDate'] as String) : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null ? DateTime.parse(json['subscriptionEndDate'] as String) : null,
      manualPremium: json['manualPremium'] as bool? ?? false,
      manualPremiumReason: json['manualPremiumReason'] as String?,
      purchasePlatform: json['purchasePlatform'] as String?,
      lastValidationAt: json['lastValidationAt'] != null ? DateTime.parse(json['lastValidationAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'joinedAt': joinedAt.toIso8601String(),
      'startDate': startDate.toIso8601String(),
      'articleSources': articleSources,
      'quizSources': quizSources,
      'repetitionIntervals': repetitionIntervals,
      'themeColorValue': themeColorValue,
      'examDate': examDate?.toIso8601String(),
      'readingPreference': readingPreference,
      'isPremium': isPremium,
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'subscriptionPlan': subscriptionPlan,
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'manualPremium': manualPremium,
      'manualPremiumReason': manualPremiumReason,
      'purchasePlatform': purchasePlatform,
      'lastValidationAt': lastValidationAt?.toIso8601String(),
    };
  }

  factory ProfileData.fromFirestore(Map<String, dynamic> doc) {
    return ProfileData.fromJson(doc);
  }

  Map<String, dynamic> toFirestore() {
    return toJson();
  }

  ProfileData copyWith({
    String? name,
    DateTime? joinedAt,
    DateTime? startDate,
    Map<String, bool>? articleSources,
    Map<String, bool>? quizSources,
    List<int>? repetitionIntervals,
    int? themeColorValue,
    DateTime? examDate,
    String? readingPreference,
    bool? isPremium,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    String? subscriptionPlan,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    bool? manualPremium,
    String? manualPremiumReason,
    String? purchasePlatform,
    DateTime? lastValidationAt,
  }) {
    return ProfileData(
      name: name ?? this.name,
      joinedAt: joinedAt ?? this.joinedAt,
      startDate: startDate ?? this.startDate,
      articleSources: articleSources ?? this.articleSources,
      quizSources: quizSources ?? this.quizSources,
      repetitionIntervals: repetitionIntervals ?? this.repetitionIntervals,
      themeColorValue: themeColorValue ?? this.themeColorValue,
      examDate: examDate ?? this.examDate,
      readingPreference: readingPreference ?? this.readingPreference,
      isPremium: isPremium ?? this.isPremium,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      manualPremium: manualPremium ?? this.manualPremium,
      manualPremiumReason: manualPremiumReason ?? this.manualPremiumReason,
      purchasePlatform: purchasePlatform ?? this.purchasePlatform,
      lastValidationAt: lastValidationAt ?? this.lastValidationAt,
    );
  }
}
