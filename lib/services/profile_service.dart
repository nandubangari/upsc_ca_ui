import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile_data.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches default profile data from a local JSON file.
  Future<ProfileData> fetchProfileFromJson() async {
    try {
      final String response = await rootBundle.loadString('assets/data/profile_defaults.json');
      final data = await json.decode(response);
      return ProfileData.fromJson(data);
    } catch (e) {
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
      print('Error fetching profile from cloud: $e');
      return null;
    }
  }

  /// Saves profile data to Firestore.
  Future<void> saveProfileToCloud(String uid, ProfileData data) async {
    try {
      await _db.collection('users').doc(uid).set({
        'settings': data.toFirestore(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error fetching profile from cloud: $e');
    }
  }

  /// Fetches profile data (tries cloud first, then local).
  Future<ProfileData?> getProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cloudProfile = await fetchProfileFromCloud(user.uid);
      if (cloudProfile != null) return cloudProfile;
    }
    try {
      return await fetchProfileFromJson();
    } catch (e) {
      return null;
    }
  }
}
