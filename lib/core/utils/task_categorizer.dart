import 'package:upsc_ca_ui/shared/models/dashboard_task.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_data.dart';
import 'package:upsc_ca_ui/shared/models/repetition_task.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';
import 'dart:math';

class TaskCategorizer {
  static DashboardData categorize({
    required List<DashboardTask> allTasks,
    required int daysLeft,
    List<RepetitionTask> repetitions = const [],
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = DateFormatter.toIso(today);

    final List<DashboardTask> todayTasks = [];
    final List<DashboardTask> repetitionTasks = [];
    final List<DashboardTask> inProgressTasks = [];
    final List<DashboardTask> notStartedTasks = [];
    final List<DashboardTask> completedTasks = [];

    allTasks.sort((a, b) => a.isoDate.compareTo(b.isoDate));

    // 1. Identify due repetitions (Active reviews)
    for (var rep in repetitions) {
      if (!rep.isFullyCompleted && rep.nextDueDate != null && rep.nextDueDate!.compareTo(todayStr) <= 0) {
        try {
          final originalTask = allTasks.firstWhere((t) => DateFormatter.toIso(t.isoDate) == rep.contentDate);
          
          // Last review date: if history is empty, it's the firstCompletedDate.
          // Otherwise, it's the completedDate of the last history entry.
          final String lastReviewDate = rep.history.isEmpty 
              ? rep.firstCompletedDate 
              : rep.history.last.completedDate;

          final resetArticles = originalTask.articles.map((a) {
            bool isDoneInThisRound = false;
            if (a.completedAt != null) {
              if (a.completedAt!.compareTo(lastReviewDate) > 0) {
                isDoneInThisRound = true;
              }
            }
            return a.copyWith(isCompleted: isDoneInThisRound);
          }).toList();
          
          final resetQuizzes = originalTask.quizzes.map((q) {
            bool isDoneInThisRound = false;
            if (q.completedAt != null) {
              if (q.completedAt!.compareTo(lastReviewDate) > 0) {
                isDoneInThisRound = true;
              }
            }
            return q.copyWith(isCompleted: isDoneInThisRound);
          }).toList();

          final articlesDone = resetArticles.where((a) => a.isCompleted).length;
          final quizzesDone = resetQuizzes.where((q) => q.isCompleted).length;
          
          final revisionTask = originalTask.copyWith(
            articles: resetArticles,
            quizzes: resetQuizzes,
            articlesDone: articlesDone,
            quizzesDone: quizzesDone,
            type: TaskType.revision,
            dueDays: rep.currentRepetition, // Round number
            lastCompleted: lastReviewDate,
            isOverdue: rep.isOverdue(todayStr),
          );
          
          if (!repetitionTasks.any((t) => t.date == revisionTask.date)) {
            repetitionTasks.add(revisionTask);
          }
        } catch (_) {}
      }
    }

    final List<DashboardTask> uncompleted = [];
    for (var task in allTasks) {
      // Check if this task is already in the repetition queue
      final isCurrentlyInRepetition = repetitionTasks.any((t) => t.date == task.date);
      
      // Also check if it's already a saved repetition (not due yet or fully completed)
      final savedRep = repetitions.where((r) => r.contentDate == DateFormatter.toIso(task.isoDate)).firstOrNull;

      if (task.isFullyCompleted && savedRep == null) {
        // This is a "fresh" completion that hasn't been saved to SR yet
        completedTasks.add(task);
      } else if (task.isFullyCompleted && savedRep != null) {
        // This is an item already in SR cycle. 
        // If it's not due today (not in repetitionTasks), it stays in completed/hidden.
        if (!isCurrentlyInRepetition) {
          completedTasks.add(task);
        }
      } else if (!isCurrentlyInRepetition) {
        // Only add to uncompleted pool if it's not currently due for repetition
        uncompleted.add(task);
      }
    }

    // Fixed logic for Quota Calculation
    // Ensure lower limit (3) is not greater than upper limit (uncompleted.length)
    int quota;
    if (daysLeft > 0 && uncompleted.isNotEmpty) {
      final calculatedQuota = (uncompleted.length / daysLeft).ceil();
      // Use min(3, length) as the actual minimum to avoid ArgumentError in clamp
      final minQuota = min(3, uncompleted.length);
      quota = calculatedQuota.clamp(minQuota, uncompleted.length);
    } else {
      quota = uncompleted.length;
    }

    int assignedToToday = 0;
    for (var task in uncompleted) {
      final bool isStarted = (task.articlesDone + task.quizzesDone) > 0;
      final bool isActuallyToday = task.isoDate.isAtSameMomentAs(today);
      
      if (isStarted) {
        inProgressTasks.add(task);
      } else if (isActuallyToday || assignedToToday < quota) {
        todayTasks.add(task);
        if (!isActuallyToday) assignedToToday++;
      } else {
        notStartedTasks.add(task);
      }
    }

    todayTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    repetitionTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    inProgressTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    notStartedTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));
    completedTasks.sort((a, b) => b.isoDate.compareTo(a.isoDate));

    return DashboardData(
      daysLeft: daysLeft,
      todayTasks: todayTasks,
      repetitionTasks: repetitionTasks,
      inProgressTasks: inProgressTasks,
      notStartedTasks: notStartedTasks,
      completedTasks: completedTasks,
    );
  }
}
