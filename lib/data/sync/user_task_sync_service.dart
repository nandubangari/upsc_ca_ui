import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:upsc_ca_ui/data/sync/base_sync_service.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';

class UserTaskSyncService extends BaseSyncService {
  UserTaskSyncService() : super(sourceName: 'User Tasks');

  @override
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate}) async {
    // User tasks are only fetched from Firestore, not from any network source.
    return [];
  }

  /// Adds a custom task to Firestore
  Future<void> addCustomTask(String isoDate, ArticleModel item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User must be logged in to add tasks");

    final date = DateTime.tryParse(isoDate);
    if (date == null) throw Exception("Invalid date format: $isoDate");

    final docId = '${date.year}_${date.month.toString().padLeft(2, '0')}';
    
    // Ensure item is marked as custom
    final customItem = item.copyWith(isCustom: true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('synced_articles')
          .doc(sourceId)
          .collection('months')
          .doc(docId)
          .get();
          
      Map<String, dynamic> data = {};
      if (doc.exists) {
        data = doc.data()!;
      }

      final List<dynamic> itemsJson = data[isoDate] ?? [];
      final List<ArticleModel> items = itemsJson.map((i) => ArticleModel.fromJson(i)).toList();

      // Check if URL already exists to avoid duplicates
      if (customItem.url != null && customItem.url!.isNotEmpty && items.any((i) => i.url == customItem.url)) {
        final index = items.indexWhere((i) => i.url == customItem.url);
        items[index] = customItem;
      } else {
        items.add(customItem);
      }

      data[isoDate] = items.map((i) => i.toJson()).toList();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('synced_articles')
          .doc(sourceId)
          .collection('months')
          .doc(docId)
          .set(data, SetOptions(merge: true));

      AppLogger.d("[UserTaskSyncService] Added custom task for $isoDate: ${customItem.title}");
    } catch (e) {
      AppLogger.e("[UserTaskSyncService] Failed to add custom task", e);
      rethrow;
    }
  }
}
