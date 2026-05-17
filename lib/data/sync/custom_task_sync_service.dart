import 'firestore_sync_service.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';

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
}
