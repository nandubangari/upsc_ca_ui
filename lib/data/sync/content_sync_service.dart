import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:isar/isar.dart';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:upsc_ca_ui/core/utils/firebase_cost_tracker.dart';
import 'package:upsc_ca_ui/data/local/isar_service.dart';
import 'package:upsc_ca_ui/data/local/models/local_content.dart';
import 'package:upsc_ca_ui/data/local/models/local_sync_metadata.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/data/services/profile_service.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';
import 'firestore_sync_service.dart';

class ContentSyncService extends FirestoreSyncService {
  ContentSyncService() : super(collectionName: 'content_upload');

  FirebaseDatabase get _db => FirebaseDatabase.instance;
  final Isar _isar = IsarService.isar;

  /// Marks a specific source/date as dirty for syncing to RTDB.
  /// documentId format: sourceId_dateStr
  Future<void> markContentDirty(String sourceId, String dateStr) async {
    final documentId = "${sourceId}_$dateStr";
    // We don't actually store the full content in localData to avoid bloat,
    // we'll fetch it from Isar during the sync() call.
    await updateLocal(documentId, {"dirty": true}, merge: true);
  }

  @override
  Future<void> sync(String documentId) async {
    // documentId is sourceId_dateStr
    final parts = documentId.split('_');
    if (parts.length < 2) return;
    
    final sourceId = parts[0];
    final dateStr = parts.sublist(1).join('_');

    final articles = await getLocalContent(dateStr, sourceId: sourceId, type: 'article');
    final quizzes = await getLocalContent(dateStr, sourceId: sourceId, type: 'quiz');

    if (articles.isEmpty && quizzes.isEmpty) {
      AppLogger.d("No local content found for $documentId to sync.");
      // Mark as clean anyway
      await _markClean(documentId);
      return;
    }

    final profile = await ProfileService().getProfile();
    final userStartDate = profile?.startDate;

    try {
      await uploadContentToRTDB(
        dateStr: dateStr,
        sourceId: sourceId,
        articles: articles.map((e) => ArticleModel(
          title: e.title,
          subtitle: e.subtitle,
          url: e.url,
          source: e.sourceId,
          date: e.date,
        )).toList(),
        quizzes: quizzes.map((e) => QuizModel(
          source: e.sourceId,
          title: e.title,
          url: e.url,
          date: e.date,
        )).toList(),
        userStartDate: userStartDate,
      );
      
      await _markClean(documentId);
    } catch (e) {
      AppLogger.e("Failed to sync content for $documentId", e);
    }
  }

  Future<void> _markClean(String documentId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";
    final fullDocId = "${uid}_${collectionName}_$documentId";
    
    await _isar.writeTxn(() async {
      final metadata = await _isar.localSyncMetadatas.filter().documentIdEqualTo(fullDocId).findFirst();
      if (metadata != null) {
        metadata.isDirty = false;
        metadata.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
        await _isar.localSyncMetadatas.put(metadata);
      }
    });
  }

  Future<void> syncContentForMonth(int year, int month) async {
    final yearStr = year.toString();
    final monthStr = month.toString().padLeft(2, '0');

    AppLogger.d("Syncing content for $yearStr-$monthStr from RTDB...");

    try {
      final ref = _db.ref('content/$yearStr/$monthStr');
      final snapshot = await ref.get();
      
      FirebaseCostTracker.recordRTDBRead();

      if (!snapshot.exists) {
        AppLogger.d("No content found in RTDB for month $yearStr-$monthStr");
        return;
      }

      final data = snapshot.value;
      if (data == null || data is! Map) return;

      final Map<dynamic, dynamic> monthData = Map<dynamic, dynamic>.from(data);
      List<LocalContent> allItems = [];

      for (var dateEntry in monthData.entries) {
        final dateStr = dateEntry.key.toString();
        final contentMap = Map<dynamic, dynamic>.from(dateEntry.value as Map);

        allItems.addAll(_parseRtdbContentStatic({
          'contentMap': contentMap,
          'year': yearStr,
          'month': monthStr,
          'dateStr': dateStr,
        }));
      }

      if (allItems.isNotEmpty) {
        AppLogger.d("Fetched ${allItems.length} items from RTDB for month $yearStr-$monthStr");
        await saveLocalContent(allItems);
      }
    } catch (e) {
      AppLogger.e("Failed to sync content for month $yearStr-$monthStr", e);
    }
  }

  Future<void> downloadAllGlobalContent() async {
    AppLogger.d("Checking if global content download is needed...");
    try {
      final ref = _db.ref('content');
      final snapshot = await ref.get();
      
      FirebaseCostTracker.recordRTDBRead();

      if (!snapshot.exists || snapshot.value == null) {
        AppLogger.d("No global content found in RTDB.");
        return;
      }

      final data = snapshot.value;
      final List<LocalContent> allItems = await compute(_parseFullRtdbContent, data);

      if (allItems.isNotEmpty) {
        AppLogger.d("Initial sync: Found ${allItems.length} global items in RTDB. Saving to local...");
        await saveLocalContent(allItems);
        AppLogger.d("Initial sync complete.");
      }
    } catch (e) {
      AppLogger.e("Failed to download all global content", e);
    }
  }

  static List<LocalContent> _parseFullRtdbContent(dynamic data) {
    final List<LocalContent> items = [];
    if (data is! Map) return items;

    final Map<dynamic, dynamic> fullMap = Map<dynamic, dynamic>.from(data);
    fullMap.forEach((year, monthData) {
      if (monthData is Map) {
        final Map<dynamic, dynamic> yearMap = Map<dynamic, dynamic>.from(monthData);
        yearMap.forEach((month, dateData) {
          if (dateData is Map) {
            final Map<dynamic, dynamic> monthMap = Map<dynamic, dynamic>.from(dateData);
            monthMap.forEach((date, content) {
              if (content is Map) {
                items.addAll(_parseRtdbContentStatic({
                  'contentMap': Map<dynamic, dynamic>.from(content),
                  'year': year.toString(),
                  'month': month.toString(),
                  'dateStr': date.toString(),
                }));
              }
            });
          }
        });
      }
    });
    return items;
  }

  /// Pushes all existing local content to RTDB for a specific date range.
  /// This is useful for migrating historical data from local Isar to global RTDB.
  Future<void> pushLocalContentToRTDB(DateTime start, DateTime end) async {
    DateTime current = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    while (current.isBefore(normalizedEnd) || current.isAtSameMomentAs(normalizedEnd)) {
      final dateStr = DateFormatter.toIso(current);

      // Get all local items for this date across all sources
      final articles = await getLocalContent(dateStr, type: 'article');
      final quizzes = await getLocalContent(dateStr, type: 'quiz');
      
      if (articles.isNotEmpty || quizzes.isNotEmpty) {
        // Group by sourceId
        final Map<String, List<ArticleModel>> sourceArticles = {};
        for (var a in articles) {
          sourceArticles.putIfAbsent(a.sourceId, () => []).add(ArticleModel(
            title: a.title,
            subtitle: a.subtitle,
            url: a.url,
            source: a.sourceId,
            date: a.date,
          ));
        }

        final Map<String, List<QuizModel>> sourceQuizzes = {};
        for (var q in quizzes) {
          sourceQuizzes.putIfAbsent(q.sourceId, () => []).add(QuizModel(
            title: q.title,
            url: q.url,
            source: q.sourceId,
            date: q.date,
          ));
        }

        final allSources = {...sourceArticles.keys, ...sourceQuizzes.keys};
        
        for (var sourceId in allSources) {
          await uploadContentToRTDB(
            dateStr: dateStr,
            sourceId: sourceId,
            articles: sourceArticles[sourceId],
            quizzes: sourceQuizzes[sourceId],
          );
        }
      }

      current = current.add(const Duration(days: 1));
    }
  }

  Future<void> updateLastGlobalSync() async {
    try {
      final ref = _db.ref('metadata/last_global_sync');
      await ref.set(ServerValue.timestamp);
      AppLogger.d("Updated last_global_sync metadata using ServerValue.timestamp");
    } catch (e) {
      AppLogger.e("Failed to update last_global_sync metadata", e);
    }
  }

  Future<bool> hasGlobalData() async {
    try {
      final ref = _db.ref('content');
      final snapshot = await ref.limitToFirst(1).get();
      return snapshot.exists && snapshot.value != null;
    } catch (e) {
      AppLogger.e("Error checking for global data", e);
      return false;
    }
  }

  Future<int?> getLastGlobalSyncTimestamp() async {
    try {
      final ref = _db.ref('metadata/last_global_sync');
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        return snapshot.value as int;
      }
    } catch (e) {
      AppLogger.e("Failed to get last_global_sync", e);
    }
    return null;
  }

  Future<void> syncContentForDate(DateTime date) async {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    AppLogger.d("Syncing content for $dateStr from RTDB...");

    try {
      final ref = _db.ref('content/$year/$month/$dateStr');
      final snapshot = await ref.get();
      
      FirebaseCostTracker.recordRTDBRead();

      if (!snapshot.exists) {
        AppLogger.d("No content found in RTDB for $dateStr");
        return;
      }

      final data = snapshot.value;
      if (data == null || data is! Map) {
        AppLogger.d("No valid map data found in RTDB for $dateStr (Type: ${data?.runtimeType})");
        return;
      }

      final Map<dynamic, dynamic> contentMap = Map<dynamic, dynamic>.from(data);
      
      // Offload map parsing to a background isolate
      final List<LocalContent> itemsToSave = await compute(_parseRtdbContentStatic, {
        'contentMap': contentMap,
        'year': year,
        'month': month,
        'dateStr': dateStr,
      });

      if (itemsToSave.isNotEmpty) {
        AppLogger.d("Fetched ${itemsToSave.length} items from RTDB for $dateStr");
        await saveLocalContent(itemsToSave);
        AppLogger.d("Saved ${itemsToSave.length} content items for $dateStr to Isar");
      }
    } catch (e) {
      AppLogger.e("Failed to sync content for $dateStr", e);
    }
  }

  static List<LocalContent> _parseRtdbContentStatic(Map<String, dynamic> params) {
    final Map<dynamic, dynamic> contentMap = params['contentMap'];
    final String year = params['year'];
    final String month = params['month'];
    final String dateStr = params['dateStr'];
    
    final List<LocalContent> itemsToSave = [];

    if (contentMap.containsKey('articles')) {
      final Map<dynamic, dynamic> sources = Map<dynamic, dynamic>.from(contentMap['articles']);
      sources.forEach((sourceId, articles) {
        if (articles is Map) {
          final Map<dynamic, dynamic> articleMap = Map<dynamic, dynamic>.from(articles);
          articleMap.forEach((articleId, articleData) {
            if (articleData is Map) {
              final Map<dynamic, dynamic> article = Map<dynamic, dynamic>.from(articleData);
              final url = article['url']?.toString();
              final finalArticleId = url?.hashCode.toString() ?? articleId.toString();

              itemsToSave.add(LocalContent()
                ..contentId = finalArticleId
                ..type = 'article'
                ..year = year
                ..month = month
                ..date = dateStr
                ..sourceId = sourceId.toString()
                ..title = article['title']?.toString() ?? ''
                ..subtitle = article['subtitle']?.toString()
                ..url = url
                ..lastFetchedAt = DateTime.now());
            }
          });
        }
      });
    }

    if (contentMap.containsKey('quizzes')) {
      final Map<dynamic, dynamic> sources = Map<dynamic, dynamic>.from(contentMap['quizzes']);
      sources.forEach((sourceId, quizzes) {
        if (quizzes is Map) {
          final Map<dynamic, dynamic> quizMap = Map<dynamic, dynamic>.from(quizzes);
          quizMap.forEach((quizId, quizData) {
            if (quizData is Map) {
              final Map<dynamic, dynamic> quiz = Map<dynamic, dynamic>.from(quizData);
              itemsToSave.add(LocalContent()
                ..contentId = quizId.toString()
                ..type = 'quiz'
                ..year = year
                ..month = month
                ..date = dateStr
                ..sourceId = sourceId.toString()
                ..title = quiz['title']?.toString() ?? ''
                ..url = quiz['url']?.toString()
                ..lastFetchedAt = DateTime.now());
            }
          });
        }
      });
    }

    return itemsToSave;
  }

  Future<List<LocalSyncMetadata>> getDirtyDocs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";
    return await _isar.localSyncMetadatas
        .filter()
        .collectionEqualTo(collectionName)
        .documentIdStartsWith("${uid}_${collectionName}_")
        .isDirtyEqualTo(true)
        .findAll();
  }

  Future<void> saveLocalContent(List<LocalContent> items) async {
    await _isar.writeTxn(() async {
      for (var item in items) {
        await _isar.localContents.put(item);
      }
    });
  }

  Future<void> uploadContentToRTDB({
    required String dateStr,
    required String sourceId,
    List<ArticleModel>? articles,
    List<QuizModel>? quizzes,
    DateTime? userStartDate,
  }) async {
    final dateParts = dateStr.split('-');
    if (dateParts.length != 3) return;

    final year = dateParts[0];
    final month = dateParts[1].padLeft(2, '0');
    
    final Map<String, dynamic> updates = {};

    if (articles != null && articles.isNotEmpty) {
      AppLogger.d("--- Syncing Articles for $sourceId on $dateStr ---");
      for (var article in articles) {
        AppLogger.d("  - ${article.title}");
        final articleId = article.url?.hashCode.toString() ?? article.title.hashCode.toString();
        if (articleId.isEmpty) continue;

        updates['content/$year/$month/$dateStr/articles/$sourceId/$articleId'] = {
          'title': article.title,
          if (article.subtitle != null) 'subtitle': article.subtitle,
          'url': article.url,
        };
      }
    }

    if (quizzes != null && quizzes.isNotEmpty) {
      AppLogger.d("--- Syncing Quizzes for $sourceId on $dateStr ---");
      for (var quiz in quizzes) {
        AppLogger.d("  - ${quiz.title}");
        final quizId = quiz.title.hashCode.toString();
        updates['content/$year/$month/$dateStr/quizzes/$sourceId/$quizId'] = {
          'title': quiz.title,
          if (quiz.url != null) 'url': quiz.url,
        };
      }
    }

    if (updates.isNotEmpty) {
      // Update specific source sync time for visibility
      updates['metadata/sources/$sourceId/last_sync'] = ServerValue.timestamp;

      // 2. Update earliest start date if necessary
      if (userStartDate != null) {
        try {
          final metaRef = _db.ref('metadata/earliest_start_date');
          final snapshot = await metaRef.get();
          
          bool shouldUpdateDate = true;
          if (snapshot.exists && snapshot.value != null) {
            try {
              final currentMin = DateTime.parse(snapshot.value.toString());
              if (userStartDate.isAfter(currentMin) || userStartDate.isAtSameMomentAs(currentMin)) {
                shouldUpdateDate = false;
              }
            } catch (e) {
              AppLogger.e("Error parsing earliest_start_date from RTDB: $e");
            }
          }

          if (shouldUpdateDate) {
            updates['metadata/earliest_start_date'] = DateFormatter.toIso(userStartDate);
            AppLogger.d("Marking new earliest start date in RTDB: ${DateFormatter.toIso(userStartDate)}");
          }
        } catch (e) {
          AppLogger.e("Error checking earliest_start_date in RTDB: $e");
        }
      }

      try {
        AppLogger.d("Attempting RTDB upload for $sourceId on $dateStr (${updates.length} items)...");
        await _db.ref().update(updates);
        FirebaseCostTracker.recordRTDBWrite();
        AppLogger.d("SUCCESS: Uploaded content for $sourceId on $dateStr to RTDB");
      } catch (e) {
        AppLogger.e("FAILED RTDB upload for $sourceId on $dateStr: $e");
        rethrow; // Rethrow to let sync() handle it
      }
    }
  }

  Future<List<LocalContent>> getLocalContent(String dateStr, {String? sourceId, String? type}) async {
    var query = _isar.localContents.filter().dateEqualTo(dateStr);
    
    if (sourceId != null) {
      query = query.sourceIdEqualTo(sourceId);
    }
    
    if (type != null) {
      query = query.typeEqualTo(type);
    }

    return await query.findAll();
  }
}
