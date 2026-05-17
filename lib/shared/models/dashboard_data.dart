import 'dashboard_task.dart';

class DashboardData {
  final int daysLeft;
  final List<DashboardTask> todayTasks;
  final List<DashboardTask> repetitionTasks;
  final List<DashboardTask> inProgressTasks;
  final List<DashboardTask> notStartedTasks;
  final List<DashboardTask> completedTasks;
  
  // Optimization: Pre-calculated and sorted list of all tasks
  final List<DashboardTask> allTasks;

  DashboardData({
    required this.daysLeft,
    required this.todayTasks,
    this.repetitionTasks = const [],
    this.inProgressTasks = const [],
    required this.notStartedTasks,
    required this.completedTasks,
  }) : allTasks = _calculateAllTasks(todayTasks, repetitionTasks, inProgressTasks, notStartedTasks, completedTasks);

  static List<DashboardTask> _calculateAllTasks(
    List<DashboardTask> today,
    List<DashboardTask> repetition,
    List<DashboardTask> inProgress,
    List<DashboardTask> notStarted,
    List<DashboardTask> completed,
  ) {
    final List<DashboardTask> combined = [
      ...today,
      ...repetition,
      ...inProgress,
      ...notStarted,
      ...completed,
    ];
    
    // Use a Set to avoid duplicates in allTasks if repetition tasks overlap
    final Map<String, DashboardTask> uniqueMap = {};
    for (var task in combined) {
      uniqueMap[task.date] = task;
    }

    final List<DashboardTask> uniqueList = uniqueMap.values.toList();
    
    // Sort by isoDate (pre-parsed) which is much faster than string parsing
    uniqueList.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    return uniqueList;
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final todayTasks = (json['todayTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList();
    final repetitionTasks = json['repetitionTasks'] != null
          ? (json['repetitionTasks'] as List)
              .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
              .toList()
          : <DashboardTask>[];
    final inProgressTasks = json['inProgressTasks'] != null
          ? (json['inProgressTasks'] as List)
              .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
              .toList()
          : <DashboardTask>[];
    final notStartedTasks = (json['notStartedTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList();
    final completedTasks = (json['completedTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList();

    return DashboardData(
      daysLeft: json['daysLeft'] as int,
      todayTasks: todayTasks,
      repetitionTasks: repetitionTasks,
      inProgressTasks: inProgressTasks,
      notStartedTasks: notStartedTasks,
      completedTasks: completedTasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daysLeft': daysLeft,
      'todayTasks': todayTasks.map((t) => t.toJson()).toList(),
      'repetitionTasks': repetitionTasks.map((t) => t.toJson()).toList(),
      'inProgressTasks': inProgressTasks.map((t) => t.toJson()).toList(),
      'notStartedTasks': notStartedTasks.map((t) => t.toJson()).toList(),
      'completedTasks': completedTasks.map((t) => t.toJson()).toList(),
    };
  }
}
