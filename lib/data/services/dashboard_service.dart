import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upsc_ca_ui/shared/models/dashboard_data.dart';

abstract class DashboardService {
  /// Fetches dashboard data from the respective source.
  Future<DashboardData> fetchDashboardData();
}

class EmptyDashboardService implements DashboardService {
  @override
  Future<DashboardData> fetchDashboardData() async {
    return DashboardData(
      daysLeft: 0,
      todayTasks: [],
      notStartedTasks: [],
      completedTasks: [],
    );
  }
}

class FirestoreDashboardService implements DashboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<DashboardData> fetchDashboardData() async {
    try {
      final doc = await _db.collection('dashboard').doc('current').get();
      if (doc.exists && doc.data() != null) {
        return DashboardData.fromJson(doc.data()!);
      } else {
        // Return empty data instead of throwing if the global config is missing
        return DashboardData(
          daysLeft: 0,
          todayTasks: [],
          notStartedTasks: [],
          completedTasks: [],
        );
      }
    } catch (e) {
      // For network errors or permission issues, we still want to know what happened
      throw Exception('Failed to load Firestore dashboard data: $e');
    }
  }
}















