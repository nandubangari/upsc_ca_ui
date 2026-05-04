import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_data.dart';

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
        throw Exception('Dashboard data not found in Firestore');
      }
    } catch (e) {
      throw Exception('Failed to load Firestore dashboard data: $e');
    }
  }
}
