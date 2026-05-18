class TaskCompletion {
  final String taskDay;
  final String completedDate;
  final int round;
  final int? intervalUsed;
  final String? nextDueDate;
  final bool isFullyDone;

  TaskCompletion({
    required this.taskDay,
    required this.completedDate,
    required this.round,
    this.intervalUsed,
    this.nextDueDate,
    required this.isFullyDone,
  });

  Map<String, dynamic> toJson() {
    return {
      'taskDay': taskDay,
      'completedDate': completedDate,
      'round': round,
      'intervalUsed': intervalUsed,
      'nextDueDate': nextDueDate,
      'isFullyDone': isFullyDone,
    };
  }

  factory TaskCompletion.fromJson(Map<String, dynamic> json) {
    return TaskCompletion(
      taskDay: json['taskDay'] as String,
      completedDate: json['completedDate'] as String,
      round: json['round'] as int,
      intervalUsed: json['intervalUsed'] as int?,
      nextDueDate: json['nextDueDate'] as String?,
      isFullyDone: json['isFullyDone'] as bool,
    );
  }
}
