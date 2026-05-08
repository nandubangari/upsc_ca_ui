import 'dashboard_task.dart';

class DashboardData {
  final int daysLeft;
  final List<DashboardTask> todayTasks;
  final List<DashboardTask> inProgressTasks;
  final List<DashboardTask> notStartedTasks;
  final List<DashboardTask> completedTasks;

  DashboardData({
    required this.daysLeft,
    required this.todayTasks,
    this.inProgressTasks = const [],
    required this.notStartedTasks,
    required this.completedTasks,
  });

  /// 🟢 Returns all tasks across all sections, sorted by date (latest first).
  List<DashboardTask> get allTasks {
    final List<DashboardTask> combined = [
      ...todayTasks,
      ...inProgressTasks,
      ...notStartedTasks,
      ...completedTasks,
    ];
    
    // Sort by date (latest first) to ensure consistent ordering everywhere
    combined.sort((a, b) {
      final isoA = _toIso(a.date);
      final isoB = _toIso(b.date);
      return isoB.compareTo(isoA);
    });
    
    return combined;
  }

  String _toIso(String dateStr) {
    try {
      return DateTime.parse(dateStr).toIso8601String().split('T')[0];
    } catch (_) {
      try {
        // Handle "DD MMM YYYY" format
        final parts = dateStr.split(' ');
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final monthStr = parts[1].toUpperCase();
          final year = parts[2];
          
          final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
          final monthIdx = months.indexOf(monthStr) + 1;
          if (monthIdx > 0) {
            return '$year-${monthIdx.toString().padLeft(2, '0')}-$day';
          }
        }
      } catch (_) {}
      return "0000-00-00";
    }
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      daysLeft: json['daysLeft'] as int,
      todayTasks: (json['todayTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList(),
      inProgressTasks: json['inProgressTasks'] != null
          ? (json['inProgressTasks'] as List)
              .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
              .toList()
          : [],
      notStartedTasks: (json['notStartedTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList(),
      completedTasks: (json['completedTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daysLeft': daysLeft,
      'todayTasks': todayTasks.map((t) => t.toJson()).toList(),
      'inProgressTasks': inProgressTasks.map((t) => t.toJson()).toList(),
      'notStartedTasks': notStartedTasks.map((t) => t.toJson()).toList(),
      'completedTasks': completedTasks.map((t) => t.toJson()).toList(),
    };
  }
}
