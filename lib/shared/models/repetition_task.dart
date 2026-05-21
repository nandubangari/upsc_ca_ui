
class RepetitionHistory {
  final int repNumber;
  final String scheduledDate;
  final String completedDate;

  RepetitionHistory({
    required this.repNumber,
    required this.scheduledDate,
    required this.completedDate,
  });

  factory RepetitionHistory.fromJson(Map<String, dynamic> json) {
    return RepetitionHistory(
      repNumber: json['repNumber'] as int,
      scheduledDate: json['scheduledDate'] as String,
      completedDate: json['completedDate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'repNumber': repNumber,
      'scheduledDate': scheduledDate,
      'completedDate': completedDate,
    };
  }
}

class RepetitionTask {
  final String contentDate; // Original content date (yyyy-MM-dd)
  final String firstCompletedDate; // Date when the user first finished the content
  final int currentRepetition; // Starts at 1 after first completion
  final String? nextDueDate; // Today + interval[currentRepetition - 1]
  final List<RepetitionHistory> history;
  final bool isFullyCompleted;

  RepetitionTask({
    required this.contentDate,
    required this.firstCompletedDate,
    required this.currentRepetition,
    this.nextDueDate,
    this.history = const [],
    this.isFullyCompleted = false,
  });

  factory RepetitionTask.fromJson(Map<String, dynamic> json) {
    return RepetitionTask(
      contentDate: json['contentDate'] as String,
      firstCompletedDate: json['firstCompletedDate'] as String,
      currentRepetition: json['currentRepetition'] as int,
      nextDueDate: json['nextDueDate'] as String?,
      history: json['history'] != null
          ? (json['history'] as List)
              .map((h) => RepetitionHistory.fromJson(h as Map<String, dynamic>))
              .toList()
          : [],
      isFullyCompleted: json['isFullyCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentDate': contentDate,
      'firstCompletedDate': firstCompletedDate,
      'currentRepetition': currentRepetition,
      'nextDueDate': nextDueDate,
      'history': history.map((h) => h.toJson()).toList(),
      'isFullyCompleted': isFullyCompleted,
    };
  }

  RepetitionTask copyWith({
    String? contentDate,
    String? firstCompletedDate,
    int? currentRepetition,
    String? nextDueDate,
    List<RepetitionHistory>? history,
    bool? isFullyCompleted,
  }) {
    return RepetitionTask(
      contentDate: contentDate ?? this.contentDate,
      firstCompletedDate: firstCompletedDate ?? this.firstCompletedDate,
      currentRepetition: currentRepetition ?? this.currentRepetition,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      history: history ?? this.history,
      isFullyCompleted: isFullyCompleted ?? this.isFullyCompleted,
    );
  }

  bool isOverdue(String todayStr) {
    if (nextDueDate == null) return false;
    return nextDueDate!.compareTo(todayStr) < 0;
  }
}
