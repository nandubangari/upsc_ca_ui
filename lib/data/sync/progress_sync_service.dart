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
    final documentId = "${year}_$monthId";
    final timestamp = "${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z";
    final data = {
      "completed": {
        monthId: {
          date: {
            "articles": {
              articleId: timestamp
            }
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
    final documentId = "${year}_$monthId";
    final timestamp = "${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z";
    final data = {
      "inProgress": {
        monthId: {
          date: {
            "articles": {
              articleId: timestamp
            }
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
    final documentId = "${year}_$monthId";
    final timestamp = "${DateTime.now().toUtc().toIso8601String().split('.')[0]}Z";
    final data = {
      "completed": {
        monthId: {
          date: {
            "quizzes": {
              quizId: timestamp
            }
          }
        }
      }
    };
    
    await updateLocal(documentId, data);
  }
}
