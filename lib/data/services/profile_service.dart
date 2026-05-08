import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:upsc_ca_ui/shared/models/profile_data.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static ProfileData? _cachedProfile;

  /// Fetches default profile data from a local JSON file.
  Future<ProfileData> fetchProfileFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/data/profile_defaults.json');
      final data = await json.decode(response);
      return ProfileData.fromJson(data);
    } catch (e) {
      AppLogger.e('Failed to load profile from JSON', e);
      throw Exception('Failed to load profile from JSON: $e');
    }
  }

  /// Fetches profile data from Firestore for a specific user.
  Future<ProfileData?> fetchProfileFromCloud(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null && doc.data()!['settings'] != null) {
        return ProfileData.fromFirestore(Map<String, dynamic>.from(doc.data()!['settings']));
      }
      return null;
    } catch (e) {
      AppLogger.e('Error fetching profile from cloud', e);
      return null;
    }
  }

  /// Saves profile data to Firestore.
  Future<void> saveProfileToCloud(String uid, ProfileData data) async {
    try {
      await _db.collection('users').doc(uid).set({
        'settings': data.toFirestore(),
      }, SetOptions(merge: true));
      _cachedProfile = data; // Update cache
    } catch (e) {
      AppLogger.e('Error saving profile to cloud', e);
    }
  }

  /// Fetches profile data (tries memory cache, then cloud, then local).
  Future<ProfileData?> getProfile({bool forceRefresh = false}) async {
    if (_cachedProfile != null && !forceRefresh) return _cachedProfile;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cloudProfile = await fetchProfileFromCloud(user.uid);
      if (cloudProfile != null) {
        _cachedProfile = cloudProfile;
        return cloudProfile;
      }
    }
    
    try {
      final defaultProfile = await fetchProfileFromJson();
      _cachedProfile = defaultProfile;
      return defaultProfile;
    } catch (e) {
      return null;
    }
  }

  /// Clears the profile cache (e.g. on logout)
  static void clearCache() {
    _cachedProfile = null;
  }
}










