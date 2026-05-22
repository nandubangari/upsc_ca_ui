import 'firestore_sync_service.dart';

class ProgressSyncService extends FirestoreSyncService {
  ProgressSyncService() : super(collectionName: 'progress');

  Future<void> markArticleCompleted({
    required String sourceId,
    required String year,
    required String monthId,
    required String date,
    required String articleId,
  }) async {
    final documentId = monthId; // Use monthId (e.g. 2025_05) as the document ID
    final timestamp = "${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z";
    final data = {
      "completed": {
        date: {
          "articles": {
            articleId: timestamp
          }
        }
      }
    };
    
    await updateLocal(documentId, data);
  }

  Future<void> markArticleInProgress({
    required String sourceId,
    required String year,
    required String monthId,
    required String date,
    required String articleId,
  }) async {
    final documentId = monthId;
    final timestamp = "${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z";
    final data = {
      "inProgress": {
        date: {
          "articles": {
            articleId: timestamp
          }
        }
      }
    };
    
    await updateLocal(documentId, data);
  }

  Future<void> markQuizCompleted({
    required String sourceId,
    required String year,
    required String monthId,
    required String date,
    required String quizId,
  }) async {
    final documentId = monthId;
    final timestamp = "${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z";
    final data = {
      "completed": {
        date: {
          "quizzes": {
            quizId: timestamp
          }
        }
      }
    };
    
    await updateLocal(documentId, data);
  }
}
