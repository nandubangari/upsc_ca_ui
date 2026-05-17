import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/core/utils/firebase_cost_tracker.dart';
import 'package:upsc_ca_ui/shared/models/profile_data.dart';
import 'package:upsc_ca_ui/data/sync/profile_sync_service.dart';
import 'package:isar/isar.dart';
import 'package:upsc_ca_ui/data/local/isar_service.dart';
import 'package:upsc_ca_ui/data/local/models/local_sync_metadata.dart';
import 'dart:async';

class ProfileService {
  final ProfileSyncService _profileSync = ProfileSyncService();
  final Isar _isar = IsarService.isar;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static ProfileData? _cachedProfile;

  /// Saves profile data local-first and triggers background sync.
  Future<void> saveProfile(ProfileData data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _profileSync.updateLocal('main', data.toFirestore());
    _cachedProfile = data;
    
    unawaited(_profileSync.sync('main'));
  }

  /// Compatibility method for ProfileSetupScreen
  Future<void> saveProfileToCloud(String uid, ProfileData data) async {
    await saveProfile(data);
  }

  /// Fetches profile data from Isar (offline-first).
  /// Returns null if no profile exists, which triggers the ProfileSetupScreen.
  Future<ProfileData?> getProfile({bool forceCloudFetch = false}) async {
    if (_cachedProfile != null && !forceCloudFetch) return _cachedProfile;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final fullDocId = "${user.uid}_profile_main";
    
    if (forceCloudFetch) {
      await _profileSync.download('main', force: true);
    }

    // 1. Try Isar
    final metadata = await _isar.localSyncMetadatas.filter().documentIdEqualTo(fullDocId).findFirst();
    
    if (metadata != null) {
      try {
        final data = jsonDecode(metadata.localData);
        _cachedProfile = ProfileData.fromFirestore(Map<String, dynamic>.from(data));
        return _cachedProfile;
      } catch (e) {
        AppLogger.e("Failed to parse local profile", e);
      }
    }

    // 2. Try Firestore (Background sync layer)
    await _profileSync.download('main');
    FirebaseCostTracker.recordFirestoreRead();
    
    final freshMetadata = await _isar.localSyncMetadatas.filter().documentIdEqualTo(fullDocId).findFirst();
    if (freshMetadata != null) {
      try {
        final data = jsonDecode(freshMetadata.localData);
        _cachedProfile = ProfileData.fromFirestore(Map<String, dynamic>.from(data));
        return _cachedProfile;
      } catch (e) {
        AppLogger.e("Failed to parse downloaded profile", e);
      }
    }

    // 3. No profile found in Isar or Cloud.
    // We return null so the UI can redirect to ProfileSetupScreen.
    return null;
  }

  /// Manual fetch from cloud (bypass Isar logic)
  Future<ProfileData?> fetchProfileFromCloud(String uid) async {
    try {
      // 1. Try fetching from the consolidated 'profile/main' document
      final doc = await _db.collection('users').doc(uid).collection('profile').doc('main').get();
      FirebaseCostTracker.recordFirestoreRead();
      
      if (doc.exists && doc.data() != null) {
        return ProfileData.fromFirestore(doc.data()!);
      }
      
      // 2. Fallback: Check root user doc for legacy "settings" and migrate if found
      final userDoc = await _db.collection('users').doc(uid).get();
      FirebaseCostTracker.recordFirestoreRead();
      
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        if (userData.containsKey('settings')) {
          AppLogger.d("Found legacy settings in root user doc. Migrating to profile/main.");
          try {
            final settings = Map<String, dynamic>.from(userData['settings']);
            final profile = ProfileData.fromFirestore(settings);
            
            // Save to consolidated location
            await saveProfile(profile);
            
            // Cleanup root doc (best effort)
            unawaited(_db.collection('users').doc(uid).update({'settings': FieldValue.delete()}));
            
            return profile;
          } catch (e) {
            AppLogger.e("Failed to migrate legacy settings", e);
          }
        }
      }

      return null;
    } catch (e) {
      AppLogger.e('Error fetching profile from cloud', e);
      return null;
    }
  }

  /// Load defaults from assets
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

  static void clearCache() {
    _cachedProfile = null;
  }
}
