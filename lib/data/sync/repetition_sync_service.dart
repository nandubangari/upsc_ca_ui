import 'dart:convert';
import 'package:isar/isar.dart';
import 'package:upsc_ca_ui/data/sync/firestore_sync_service.dart';
import 'package:upsc_ca_ui/shared/models/repetition_task.dart';
import 'package:upsc_ca_ui/data/local/models/local_sync_metadata.dart';

class RepetitionSyncService extends FirestoreSyncService {
  RepetitionSyncService() : super(collectionName: 'repetitions');

  Future<void> saveRepetition(RepetitionTask repetition) async {
    final docId = repetition.contentDate; // Document ID is the original content date
    await updateLocal(docId, repetition.toJson());
  }

  Future<List<RepetitionTask>> getAllRepetitions() async {
    final uid = getUid();
    final results = await isar.localSyncMetadatas
        .filter()
        .collectionEqualTo(collectionName)
        .and()
        .documentIdStartsWith("${uid}_${collectionName}_")
        .findAll();

    return results.map((m) {
      final data = jsonDecode(m.localData) as Map<String, dynamic>;
      return RepetitionTask.fromJson(data);
    }).toList();
  }

  Future<RepetitionTask?> getRepetition(String contentDate) async {
    final uid = getUid();
    final fullDocId = "${uid}_${collectionName}_$contentDate";
    final metadata = await isar.localSyncMetadatas.filter().documentIdEqualTo(fullDocId).findFirst();
    
    if (metadata != null) {
      final data = jsonDecode(metadata.localData) as Map<String, dynamic>;
      return RepetitionTask.fromJson(data);
    }
    return null;
  }

  Future<List<RepetitionTask>> getDueRepetitions(String todayStr) async {
    // We can't easily query nextDueDate <= todayStr in Isar without a specific index on JSON content
    // So we fetch all and filter locally for now, or fetch all from the specific collection.
    final all = await getAllRepetitions();
    return all.where((r) => 
      !r.isFullyCompleted && 
      r.nextDueDate != null && 
      r.nextDueDate!.compareTo(todayStr) <= 0
    ).toList();
  }
}
