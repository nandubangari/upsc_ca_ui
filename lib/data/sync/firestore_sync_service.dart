import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isar_community/isar.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/core/utils/firebase_cost_tracker.dart';
import 'package:upsc_ca_ui/data/local/isar_service.dart';
import 'package:upsc_ca_ui/data/local/models/local_sync_metadata.dart';

abstract class FirestoreSyncService {
  final String collectionName;
  final Isar _isar = IsarService.isar;
  
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  Isar get isar => _isar;

  FirestoreSyncService({required this.collectionName});

  String getUid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "anonymous";
    return user.uid;
  }

  Future<void> updateLocal(String documentId, Map<String, dynamic> data, {bool merge = true}) async {
    final uid = getUid();
    final fullDocId = "${uid}_${collectionName}_$documentId";

    await _isar.writeTxn(() async {
      var metadata = await _isar.localSyncMetadatas.filter().documentIdEqualTo(fullDocId).findFirst();

      Map<String, dynamic> currentLocalData = {};
      if (metadata != null) {
        try {
          currentLocalData = jsonDecode(metadata.localData);
        } catch (e) {
          AppLogger.e("Local data corrupted for $fullDocId. Resetting.");
          currentLocalData = {};
        }
      } else {
        metadata = LocalSyncMetadata()
          ..documentId = fullDocId
          ..collection = collectionName
          ..originalDocId = documentId
          ..lastFetchedCloudCopy = "{}"
          ..cloudUpdatedAt = 0
          ..lastSyncedAt = 0
          ..syncVersion = 0;
      }

      if (merge) {
        currentLocalData = _deepMerge(currentLocalData, data);
      } else {
        currentLocalData = data;
      }

      metadata.localData = jsonEncode(currentLocalData);
      metadata.isDirty = true;
      metadata.localUpdatedAt = DateTime.now().millisecondsSinceEpoch;

      await _isar.localSyncMetadatas.put(metadata);
    });

    AppLogger.d("Updated local $collectionName/$documentId. Marked as dirty.");
  }

  Future<void> sync(String documentId) async {
    final uid = getUid();
    if (uid == "anonymous") return;
    
    final fullDocId = "${uid}_${collectionName}_$documentId";

    final metadata = await _isar.localSyncMetadatas.filter().documentIdEqualTo(fullDocId).findFirst();
    if (metadata == null || !metadata.isDirty) return;

    Map<String, dynamic> localData;
    Map<String, dynamic> lastCloudCopy;
    
    try {
      localData = jsonDecode(metadata.localData);
      lastCloudCopy = jsonDecode(metadata.lastFetchedCloudCopy);
    } catch (e) {
      AppLogger.e("Corruption detected during sync of $fullDocId. Forcing download.");
      await download(documentId, force: true);
      return;
    }

    if (_isEqual(localData, lastCloudCopy)) {
      AppLogger.d("Local data for $documentId is identical to last cloud copy. Skipping upload.");
      await _isar.writeTxn(() async {
        metadata.isDirty = false;
        await _isar.localSyncMetadatas.put(metadata);
      });
      return;
    }

    final diff = _calculateIncrementalUpdate("", localData, lastCloudCopy);
    if (diff.isEmpty) {
      AppLogger.d("Sync: No incremental changes found for $collectionName/$documentId. Marking clean.");
      await _isar.writeTxn(() async {
        metadata.isDirty = false;
        await _isar.localSyncMetadatas.put(metadata);
      });
      return;
    }

    AppLogger.d("Sync: Uploading ${diff.length} fields for $collectionName/$documentId...");

    try {
      final docRef = _db.collection('users').doc(uid).collection(collectionName).doc(documentId);
      
      // If we've never successfully synced this doc and have no cloud copy, 
      // use set() to avoid the NOT_FOUND error from update().
      if (metadata.lastSyncedAt == 0 && lastCloudCopy.isEmpty) {
        AppLogger.d("Sync: Document $documentId appears new. Using set().");
        await docRef.set(localData, SetOptions(merge: true));
      } else {
        try {
          // Use update() to correctly handle dot-notated field paths as nested maps in Firestore.
          // set(merge: true) treats dots in keys as literal parts of the field name.
          await docRef.update(diff);
        } catch (e) {
          // If document doesn't exist, update() fails. Fallback to set() with the full nested localData.
          if (e is FirebaseException && (e.code == 'not-found' || e.code == 'NOT_FOUND')) {
            AppLogger.d("Sync: Document $documentId not found during update. Falling back to set().");
            await docRef.set(localData, SetOptions(merge: true));
          } else {
            rethrow;
          }
        }
      }
      
      FirebaseCostTracker.recordFirestoreWrite();

      AppLogger.d("Sync: SUCCESS for $collectionName/$documentId");

      await _isar.writeTxn(() async {
        metadata.lastFetchedCloudCopy = metadata.localData;
        metadata.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
        metadata.isDirty = false;
        await _isar.localSyncMetadatas.put(metadata);
      });
    } catch (e) {
      AppLogger.e("Sync: FAILED for $collectionName/$documentId", e);
    }
  }

  Future<void> download(String documentId, {bool force = false}) async {
    final uid = getUid();
    if (uid == "anonymous") return;
    
    final fullDocId = "${uid}_${collectionName}_$documentId";

    var metadata = await _isar.localSyncMetadatas.filter().documentIdEqualTo(fullDocId).findFirst();
    
    try {
      final docRef = _db.collection('users').doc(uid).collection(collectionName).doc(documentId);
      final snapshot = await docRef.get();
      
      FirebaseCostTracker.recordFirestoreRead();

      if (!snapshot.exists) return;

      final cloudData = snapshot.data() ?? {};
      
      if (metadata == null || force) {
        await _isar.writeTxn(() async {
          final m = metadata ??= LocalSyncMetadata()
                ..documentId = fullDocId
                ..collection = collectionName
                ..originalDocId = documentId
                ..cloudUpdatedAt = 0
                ..localUpdatedAt = DateTime.now().millisecondsSinceEpoch // Fix: Initialize localUpdatedAt
                ..syncVersion = 0;

          m.localData = jsonEncode(cloudData);
          m.lastFetchedCloudCopy = jsonEncode(cloudData);
          m.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
          m.isDirty = false;
          await _isar.localSyncMetadatas.put(m);
        });
        AppLogger.d("Downloaded $collectionName/$documentId from Firestore.");
      }
    } catch (e) {
      AppLogger.e("Failed to download $collectionName/$documentId from Firestore", e);
    }
  }

  Future<void> downloadAll() async {
    final uid = getUid();
    if (uid == "anonymous") return;

    try {
      final querySnapshot = await _db.collection('users').doc(uid).collection(collectionName).get();
      
      // Cost tracking: 1 query = 1 read if empty, or 1 read per document.
      // We pass the document count to track the actual cost.
      FirebaseCostTracker.recordFirestoreRead(querySnapshot.docs.isEmpty ? 1 : querySnapshot.docs.length);

      if (querySnapshot.docs.isEmpty) return;

      await _isar.writeTxn(() async {
        for (var doc in querySnapshot.docs) {
          final documentId = doc.id;
          final fullDocId = "${uid}_${collectionName}_$documentId";
          final cloudData = doc.data();

          var metadata = await _isar.localSyncMetadatas.filter().documentIdEqualTo(fullDocId).findFirst();
          
          final m = metadata ??= LocalSyncMetadata()
                ..documentId = fullDocId
                ..collection = collectionName
                ..originalDocId = documentId
                ..cloudUpdatedAt = 0
                ..localUpdatedAt = DateTime.now().millisecondsSinceEpoch
                ..syncVersion = 0;

          // Merge logic: If local is dirty, don't overwrite local changes
          if (m.isDirty) {
            Map<String, dynamic> localData = {};
            try {
              localData = jsonDecode(m.localData);
            } catch (e) {
              AppLogger.e("Data corruption in $fullDocId. Overwriting.");
            }
            // Merge cloud updates into local, but local values win on conflict for dirty fields
            m.localData = jsonEncode(_deepMerge(cloudData, localData));
            // Keep it dirty so these changes are eventually pushed back up
          } else {
            m.localData = jsonEncode(cloudData);
            m.isDirty = false;
          }

          m.lastFetchedCloudCopy = jsonEncode(cloudData);
          m.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
          await _isar.localSyncMetadatas.put(m);
        }
      });
      AppLogger.d("Downloaded all ${querySnapshot.docs.length} docs for $collectionName from Firestore.");
    } catch (e) {
      AppLogger.e("Failed to download all from $collectionName", e);
    }
  }

  Map<String, dynamic> _deepMerge(Map<String, dynamic> target, Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(target);
    source.forEach((key, value) {
      if (value is Map<String, dynamic> && result[key] is Map<String, dynamic>) {
        result[key] = _deepMerge(result[key], value);
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  bool _isEqual(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_isEqual(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_isEqual(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  Map<String, dynamic> _calculateIncrementalUpdate(String path, Map<String, dynamic> local, Map<String, dynamic> cloud) {
    final Map<String, dynamic> updates = {};

    local.forEach((key, value) {
      final currentPath = path.isEmpty ? key : "$path.$key";
      if (!cloud.containsKey(key)) {
        updates[currentPath] = value;
      } else if (value is Map<String, dynamic> && cloud[key] is Map<String, dynamic>) {
        updates.addAll(_calculateIncrementalUpdate(currentPath, value, cloud[key]));
      } else if (!_isEqual(value, cloud[key])) {
        updates[currentPath] = value;
      }
    });

    return updates;
  }
}
