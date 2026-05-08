import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_data.dart';

class TaskCategorizer {
  static DashboardData categorize({
    required List<DashboardTask> allTasks,
    required int daysLeft,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<DashboardTask> todayTasks = [];
    final List<DashboardTask> inProgressTasks = [];
    final List<DashboardTask> notStartedTasks = [];
    final List<DashboardTask> completedTasks = [];

    // Sort all tasks by date ASC (Oldest first) for consistent quota assignment
    allTasks.sort((a, b) => a.isoDate.compareTo(b.isoDate));

    final List<DashboardTask> uncompleted = [];
    for (var task in allTasks) {
      if (task.isFullyCompleted) {
        completedTasks.add(task);
      } else {
        uncompleted.add(task);
      }
    }

    // Recalculate Quota
    // Logic: Assign oldest uncompleted tasks to Today until quota is hit.
    // Quota is based on remaining days to exam.
    final int quota = daysLeft > 0 
        ? (uncompleted.length / daysLeft).ceil().clamp(3, uncompleted.length)
        : uncompleted.length;

    int assignedToToday = 0;
    for (var task in uncompleted) {
      final bool isStarted = (task.articlesDone + task.quizzesDone) > 0;
      final bool isActuallyToday = task.isoDate.isAtSameMomentAs(today);
      
      if (assignedToToday < quota || isActuallyToday) {
        todayTasks.add(task);
        assignedToToday++;
      } else if (isStarted) {
        inProgressTasks.add(task);
      } else {
        notStartedTasks.add(task);
      }
    }

    // Sort result lists latest first for UI
    todayTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    inProgressTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    notStartedTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    completedTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));

    return DashboardData(
      daysLeft: daysLeft,
      todayTasks: todayTasks,
      inProgressTasks: inProgressTasks,
      notStartedTasks: notStartedTasks,
      completedTasks: completedTasks,
    );
  }
}
