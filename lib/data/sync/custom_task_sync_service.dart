import 'firestore_sync_service.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'dart:convert';
import 'package:upsc_ca_ui/data/local/models/local_sync_metadata.dart';
import 'package:isar_community/isar.dart';

class CustomTaskSyncService extends FirestoreSyncService {
  CustomTaskSyncService() : super(collectionName: 'customTasks');

  Future<void> addCustomTask(String isoDate, ArticleModel item) async {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return;

    final documentId = "${date.year}_${date.month.toString().padLeft(2, '0')}";
    final data = {
      isoDate: {
        "articles": {
          item.url ?? "": item.toJson()
        }
      }
    };
    
    await updateLocal(documentId, data);
  }

  Future<void> deleteCustomTask(String isoDate, String articleUrl) async {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return;

    final documentId = "${date.year}_${date.month.toString().padLeft(2, '0')}";
    final uid = getUid();
    final fullDocId = "${uid}_${collectionName}_$documentId";

    await isar.writeTxn(() async {
      final metadata = await isar.localSyncMetadatas.filter().documentIdEqualTo(fullDocId).findFirst();
      if (metadata == null) return;

      Map<String, dynamic> localData = jsonDecode(metadata.localData);
      
      // Navigate the nested map and remove the article
      if (localData.containsKey(isoDate)) {
        final dayData = localData[isoDate] as Map<String, dynamic>;
        if (dayData.containsKey("articles")) {
          final articles = dayData["articles"] as Map<String, dynamic>;
          if (articles.containsKey(articleUrl)) {
            articles.remove(articleUrl);
            
            // If articles for this day is now empty, we can choose to keep the day key 
            // but the content is gone. For Firestore sync, updateLocal handles merge.
            // However, we want to OVERWRITE the whole document state for a deletion 
            // to ensure it propagates correctly to the cloud.
            metadata.localData = jsonEncode(localData);
            metadata.isDirty = true;
            metadata.localUpdatedAt = DateTime.now().millisecondsSinceEpoch;
            await isar.localSyncMetadatas.put(metadata);
          }
        }
      }
    });
  }
}
