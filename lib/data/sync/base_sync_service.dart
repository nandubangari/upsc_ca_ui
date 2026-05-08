import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:upsc_ca_ui/shared/models/article_model.dart';
import 'package:upsc_ca_ui/shared/models/quiz_model.dart';
import 'package:upsc_ca_ui/shared/models/daily_study_data.dart';

abstract class BaseSyncService {
  final String sourceName;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  BaseSyncService({required this.sourceName});

  /// The unique key used in Firestore to identify this source's data
  String get sourceId => sourceName.toLowerCase().replaceAll(' ', '_');

  /// Fetches articles from the network for a specific month
  Future<List<DailyStudyData>> fetchFromNetwork(int year, int month, {DateTime? startDate, Function(String)? onStatusUpdate});

  /// Orchestrates the sync for a given date range
  Future<void> syncRange({
    required DateTime startDate,
    bool forceRefresh = false,
    Function(String)? onStatusUpdate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User must be logged in to sync");

    final now = DateTime.now();
    final fiveDaysAgo = now.subtract(const Duration(days: 5));

    // Iterate through months from startDate to now
    DateTime currentMonth = DateTime(startDate.year, startDate.month);
    
    while (currentMonth.isBefore(now) || (currentMonth.year == now.year && currentMonth.month == now.month)) {
      onStatusUpdate?.call('Checking $sourceName for ${currentMonth.year}/${currentMonth.month}...');

      // 1. Get existing data from Firestore for this source and month
      final existingData = await getMonthDataFromFirestore(user.uid, currentMonth.year, currentMonth.month);

      // 2. Decide if we need to fetch from network
      // We fetch if:
      // a) No data exists in Firestore for this month
      // b) The month is the current month
      // c) The month contains dates within the last 5 days
      // d) forceRefresh is enabled
      bool needsFetch = existingData.isEmpty || forceRefresh;
      
      if (!needsFetch) {
        final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;
        if (isCurrentMonth) {
          needsFetch = true;
        } else {
          final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);
          if (monthEnd.isAfter(fiveDaysAgo)) {
            needsFetch = true;
          }
        }
      }

      if (needsFetch) {
        onStatusUpdate?.call('Fetching $sourceName from net: ${currentMonth.year}/${currentMonth.month}');
        final List<DailyStudyData> netData = await fetchFromNetwork(
          currentMonth.year, 
          currentMonth.month, 
          startDate: startDate,
          onStatusUpdate: onStatusUpdate
        );
        
        // CRITICAL FIX: Only proceed with merge/save if we actually got data.
        // If netData is empty (e.g. fetch failed), we DO NOT want to call _mergeAndSave
        // especially with forceRefresh, because it would wipe out existing Firestore data.
        if (netData.isEmpty) {
          AppLogger.d("[$sourceName] No data received from network/cache for ${currentMonth.year}/${currentMonth.month}. Skipping save to preserve existing Firestore data.");
        } else {
          AppLogger.d("[$sourceName] Network fetch returned ${netData.length} daily entries for ${currentMonth.year}/${currentMonth.month}");

          // Ensure we ONLY save data (articles AND quizzes) that is on or after the startDate
          final filteredNetData = netData.map((d) {
            final itemDate = DateTime.tryParse(d.date);
            if (itemDate == null) return d;
            
            final normalizedItemDate = DateTime(itemDate.year, itemDate.month, itemDate.day);
            final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
            final normalizedNow = DateTime(now.year, now.month, now.day);
            
            final isWithinRange = (normalizedItemDate.isAtSameMomentAs(normalizedStartDate) || 
                                 normalizedItemDate.isAfter(normalizedStartDate)) &&
                                (normalizedItemDate.isAtSameMomentAs(normalizedNow) || 
                                 normalizedItemDate.isBefore(normalizedNow));

            if (!isWithinRange) {
              return DailyStudyData(date: d.date, items: [], quizzes: []);
            }
            return d;
          }).where((d) => d.items.isNotEmpty || d.quizzes.isNotEmpty).toList();

          // 3. Merge and Save
          await mergeAndSave(user.uid, currentMonth.year, currentMonth.month, existingData, filteredNetData, forceRefresh: forceRefresh);
        }
      }

      // Move to next month
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    }
  }

  Future<Map<String, List<ArticleModel>>> getMonthDataFromFirestore(String uid, int year, int month) async {
    final docId = '${year}_${month.toString().padLeft(2, '0')}';
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months')
        .doc(docId)
        .get();

    if (!doc.exists || doc.data() == null) return {};

    final data = doc.data()!;
    final Map<String, List<ArticleModel>> results = {};
    
    data.forEach((date, itemsJson) {
      final List<dynamic> list = itemsJson;
      results[date] = list.map((i) => ArticleModel.fromJson(i)).toList();
    });

    return results;
  }

  Future<void> mergeAndSave(
    String uid, 
    int year, 
    int month, 
    Map<String, List<ArticleModel>> existing, 
    List<DailyStudyData> incoming, {
    bool forceRefresh = false,
  }) async {
    bool changed = false;
    int addedCount = 0;
    int updatedCount = 0;
    int duplicateCount = 0;

    final docId = '${year}_${month.toString().padLeft(2, '0')}';
    final monthRef = _db
        .collection('users')
        .doc(uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months')
        .doc(docId);

    for (var daily in incoming) {
      final date = daily.date;
      final existingItems = existing[date] ?? [];
      final Map<String, int> urlToIndex = {
        for (int i = 0; i < existingItems.length; i++) existingItems[i].url ?? '': i
      };

      for (var incomingItem in daily.items) {
        final url = incomingItem.url ?? '';
        if (urlToIndex.containsKey(url)) {
          // Check if we should update the item
          final index = urlToIndex[url]!;
          var existingItem = existingItems[index];
          bool itemChanged = false;
          
          // Update title if it changed
          if (existingItem.title != incomingItem.title) {
            AppLogger.d("[$sourceName] Title updated for $url: FROM: \"${existingItem.title}\" TO: \"${incomingItem.title}\"");
            existingItem = existingItem.copyWith(title: incomingItem.title);
            itemChanged = true;
          }

          final hasIncomingSubtitle = incomingItem.subtitle != null && 
                                      incomingItem.subtitle!.isNotEmpty && 
                                      incomingItem.subtitle!.toLowerCase() != "null";
          
          final existingSubtitle = existingItem.subtitle;
          final needsSubtitleUpdate = existingSubtitle == null || 
                              existingSubtitle.isEmpty || 
                              existingSubtitle.toLowerCase() == "null";

          if (needsSubtitleUpdate && hasIncomingSubtitle) {
            AppLogger.d("[$sourceName] Updating subtitle for $url");
            existingItem = existingItem.copyWith(subtitle: incomingItem.subtitle);
            itemChanged = true;
          }

          if (itemChanged) {
            existingItems[index] = existingItem;
            updatedCount++;
            changed = true;
          } else {
            duplicateCount++;
          }
        } else {
          existingItems.add(incomingItem);
          urlToIndex[incomingItem.url ?? ''] = existingItems.length - 1;
          addedCount++;
          changed = true;
        }
      }
      existing[date] = existingItems;

      // Handle Quizzes
      if (daily.quizzes.isNotEmpty) {
        changed = true;
        AppLogger.d("[$sourceName] Saving ${daily.quizzes.length} quizzes for $date");
        // Quizzes are stored in a separate collection for easier status tracking
        final quizBatch = _db.batch();
        for (var quiz in daily.quizzes) {
          final quizId = quiz.title.hashCode.toString();
          final quizRef = monthRef.collection('quizzes').doc(quizId);
          
          quizBatch.set(quizRef, {
            'source': quiz.source,
            'title': quiz.title,
            if (quiz.url != null) 'url': quiz.url,
            'date': date, // Explicitly save date for easier retrieval later
          }, SetOptions(merge: true));
        }
        await quizBatch.commit();
      }
    }

    AppLogger.d("[$sourceName] Sync Results - Added: $addedCount, Updated: $updatedCount, Duplicates: $duplicateCount");

    if (changed || existing.isEmpty) {
      final Map<String, dynamic> toSave = {};
      existing.forEach((date, items) {
        toSave[date] = items.map((i) => i.toJson()).toList();
      });

      await monthRef.set(toSave, SetOptions(merge: true));
    }
  }

  /// Updates the completion status of a specific article in Firestore
  Future<void> updateArticleStatus(String isoDate, String url, bool isCompleted, {String? completedAt}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final date = DateTime.tryParse(isoDate);
    if (date == null) return;

    final docId = '${date.year}_${date.month.toString().padLeft(2, '0')}';
    final monthRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months')
        .doc(docId);

    try {
      final doc = await monthRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      if (!data.containsKey(isoDate)) return;

      final List<dynamic> itemsJson = data[isoDate];
      final items = itemsJson.map((i) => ArticleModel.fromJson(i)).toList();

      bool found = false;
      for (int i = 0; i < items.length; i++) {
        if (items[i].url == url) {
          items[i] = items[i].copyWith(
            isCompleted: isCompleted,
            completedAt: completedAt,
          );
          found = true;
          break;
        }
      }

      if (found) {
        data[isoDate] = items.map((i) => i.toJson()).toList();
        await monthRef.set(data, SetOptions(merge: true));
        AppLogger.d("[$sourceName] Updated completion status for $url to $isCompleted");
      }
    } catch (e) {
      AppLogger.e("[$sourceName] Failed to update article status", e);
    }
  }

  /// Updates the completion status of a specific quiz in Firestore
  Future<void> updateQuizStatus(String isoDate, String quizTitle, bool isCompleted, {String? completedAt}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final date = DateTime.tryParse(isoDate);
    if (date == null) return;

    final docId = '${date.year}_${date.month.toString().padLeft(2, '0')}';
    final monthRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months')
        .doc(docId);

    try {
      final quizId = quizTitle.hashCode.toString();
      final quizRef = monthRef.collection('quizzes').doc(quizId);
      
      await quizRef.update({
        'isCompleted': isCompleted,
        if (completedAt != null) ...{'completedAt': completedAt},
      });
      AppLogger.d("[$sourceName] Updated quiz status for $quizTitle to $isCompleted (at $completedAt)");
    } catch (e) {
      AppLogger.e("[$sourceName] Failed to update quiz status", e);
    }
  }

  /// Retrieves synced articles for this source from Firestore.
  /// Optionally filters by startDate to optimize data retrieval.
  Future<Map<String, List<ArticleModel>>> getAllSyncedArticles({DateTime? startDate}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final query = _db
        .collection('users')
        .doc(user.uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months');

    QuerySnapshot<Map<String, dynamic>> snapshot;
    
    if (startDate != null) {
      final minDocId = '${startDate.year}_${startDate.month.toString().padLeft(2, '0')}';
      snapshot = await query.where(FieldPath.documentId, isGreaterThanOrEqualTo: minDocId).get();
    } else {
      snapshot = await query.get();
    }

    final Map<String, List<ArticleModel>> allArticles = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      data.forEach((date, itemsJson) {
        if (itemsJson is List) {
          final items = itemsJson.map((i) => ArticleModel.fromJson(i)).toList();
          allArticles.putIfAbsent(date, () => []).addAll(items);
        }
      });
    }

    return allArticles;
  }

  /// Retrieves synced quizzes for this source from Firestore.
  /// Optionally filters by startDate to optimize data retrieval.
  Future<Map<String, List<QuizModel>>> getAllSyncedQuizzes({DateTime? startDate}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final query = _db
        .collection('users')
        .doc(user.uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months');

    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (startDate != null) {
      final minDocId = '${startDate.year}_${startDate.month.toString().padLeft(2, '0')}';
      snapshot = await query.where(FieldPath.documentId, isGreaterThanOrEqualTo: minDocId).get();
    } else {
      snapshot = await query.get();
    }

    final Map<String, List<QuizModel>> allQuizzes = {};

    for (var monthDoc in snapshot.docs) {
      final quizSnapshot = await monthDoc.reference.collection('quizzes').get();
      for (var quizDoc in quizSnapshot.docs) {
        final data = quizDoc.data();
        final date = data['date'] as String? ?? '0000-00-00'; 
        final quiz = QuizModel.fromJson(data);
        allQuizzes.putIfAbsent(date, () => []).add(quiz);
      }
    }

    return allQuizzes;
  }
}
