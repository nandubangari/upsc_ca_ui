import 'dart:async';
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
    bool onlyRecent = false,
    Function(String)? onStatusUpdate,
    bool Function()? shouldPause,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User must be logged in to sync");

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // 1. Fetch Sync Metadata
    final metadata = await _getSyncMetadata(user.uid);
    final String? minSyncedStr = metadata?['minSyncedDate'];
    final DateTime? oldMinSyncedDate = minSyncedStr != null ? DateTime.tryParse(minSyncedStr) : null;
    
    // Safety: If uncompletedMonths is missing from metadata but we have history, rebuild it once
    if (metadata != null && !metadata.containsKey('uncompletedMonths')) {
      AppLogger.d("[$sourceName] 🔄 Rebuilding Uncompleted Index...");
      unawaited(refreshUncompletedIndex(user.uid));
    }

    // 2. Determine Sync Segments
    // FLOW A: Historical Gap Sync (Only if needed and not onlyRecent)
    // FLOW B: Standard Recent Sync (Last 7 days - Always runs)

    bool hasHistoricalGap = oldMinSyncedDate == null || startDate.isBefore(oldMinSyncedDate);
    
    if (!onlyRecent && (forceRefresh || hasHistoricalGap)) {
      if (shouldPause?.call() ?? false) {
        AppLogger.d("[$sourceName] ⏸️ Sync paused (Reader open)");
        return;
      }

      DateTime gapStart = startDate;
      // If not first sync and not force refresh, we only need to sync up to the oldMinSyncedDate
      DateTime gapEnd = forceRefresh ? now : (oldMinSyncedDate ?? now);
      
      AppLogger.d("[$sourceName] 🟢 FLOW A: Syncing Historical Gap from ${gapStart.toIso8601String()} to ${gapEnd.toIso8601String()}");
      
      await _executeSyncForRange(
        user.uid, 
        gapStart, 
        gapEnd, 
        startDate: startDate, 
        forceRefresh: forceRefresh, 
        onStatusUpdate: onStatusUpdate,
        shouldPause: shouldPause,
        onMonthSynced: (syncedMonthEnd) async {
          // Update minSyncedDate incrementally if we are moving forward from startDate
          final currentMin = oldMinSyncedDate ?? gapEnd;
          if (startDate.isBefore(currentMin)) {
            // If we just finished a month that includes our target startDate or is adjacent, 
            // we update metadata to show we've covered that part.
            // For simplicity, we update it to the earliest date we've successfully synced in this session
            // that is >= startDate.
            await _updateSyncMetadata(user.uid, minSyncedDate: startDate);
          }
        },
      );
    } else {
      if (onlyRecent) {
        AppLogger.d("[$sourceName] ⏭️ Skipping FLOW A (onlyRecent=true)");
      } else {
        AppLogger.d("[$sourceName] ⏩ Skipping Historical Check. History is already synced up to ${oldMinSyncedDate?.toIso8601String() ?? 'N/A'}");
      }
    }

    // ALWAYS perform FLOW B: Standard Recent Sync (Last 7 days)
    if (shouldPause?.call() ?? false) {
      AppLogger.d("[$sourceName] ⏸️ Sync paused before FLOW B");
      return;
    }

    AppLogger.d("[$sourceName] 🔵 FLOW B: Standard Sync (Last 7 Days)");
    await _executeSyncForRange(
      user.uid, 
      sevenDaysAgo.isBefore(startDate) ? startDate : sevenDaysAgo, 
      now, 
      startDate: startDate, 
      forceRefresh: forceRefresh, 
      onStatusUpdate: onStatusUpdate,
      shouldPause: shouldPause,
      alwaysFetch: true,
    );

    // 3. Final Metadata Update
    await _updateSyncMetadata(user.uid,
        minSyncedDate: (!onlyRecent && (oldMinSyncedDate == null || startDate.isBefore(oldMinSyncedDate))) ? startDate : oldMinSyncedDate, 
        lastSyncedAt: now);
  }

  /// Internal helper to sync a specific date range month-by-month
  Future<void> _executeSyncForRange(
    String uid, 
    DateTime rangeStart, 
    DateTime rangeEnd, {
    required DateTime startDate,
    bool forceRefresh = false,
    Function(String)? onStatusUpdate,
    bool Function()? shouldPause,
    bool alwaysFetch = false,
    Future<void> Function(DateTime)? onMonthSynced,
  }) async {
    final now = DateTime.now();
    DateTime currentMonth = DateTime(rangeStart.year, rangeStart.month);
    
    while (currentMonth.isBefore(rangeEnd) || (currentMonth.year == rangeEnd.year && currentMonth.month == rangeEnd.month)) {
      if (shouldPause?.call() ?? false) {
        AppLogger.d("[$sourceName] ⏸️ Loop paused");
        break;
      }

      // 1. Get existing data from Firestore
      final existingData = await getMonthDataFromFirestore(uid, currentMonth.year, currentMonth.month);

      // 2. Decide if we need to fetch
      bool isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;
      bool needsFetch = alwaysFetch || forceRefresh || existingData.isEmpty || isCurrentMonth;

      if (needsFetch) {
        onStatusUpdate?.call('Syncing $sourceName: ${currentMonth.year}/${currentMonth.month}...');
        final List<DailyStudyData> netData = await fetchFromNetwork(
          currentMonth.year,
          currentMonth.month,
          startDate: startDate,
          onStatusUpdate: onStatusUpdate,
        );

        if (netData.isNotEmpty) {
          final filteredNetData = netData.where((d) {
            final itemDate = DateTime.tryParse(d.date);
            if (itemDate == null) return false;
            return (itemDate.isAtSameMomentAs(startDate) || itemDate.isAfter(startDate)) &&
                   (itemDate.isAtSameMomentAs(now) || itemDate.isBefore(now));
          }).toList();

          await mergeAndSave(uid, currentMonth.year, currentMonth.month, existingData, filteredNetData, forceRefresh: forceRefresh);
        }
      }
      
      if (onMonthSynced != null) {
        final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);
        await onMonthSynced(monthEnd);
      }

      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    }
  }

  Future<Map<String, dynamic>?> getSyncMetadata() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return _getSyncMetadata(user.uid);
  }

  Future<Map<String, dynamic>?> _getSyncMetadata(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).collection('synced_articles').doc(sourceId).get();
      return doc.data();
    } catch (e) {
      AppLogger.e("[$sourceName] Failed to fetch sync metadata", e);
      return null;
    }
  }

  Future<void> _updateSyncMetadata(String uid, {DateTime? minSyncedDate, DateTime? lastSyncedAt, List<String>? uncompletedMonths}) async {
    try {
      final Map<String, dynamic> data = {};
      if (minSyncedDate != null) {
        data['minSyncedDate'] = minSyncedDate.toIso8601String().split('T')[0];
      }
      if (lastSyncedAt != null) {
        data['lastSyncedAt'] = lastSyncedAt.toIso8601String();
      }
      if (uncompletedMonths != null) {
        data['uncompletedMonths'] = uncompletedMonths;
      }

      if (data.isNotEmpty) {
        await _db.collection('users').doc(uid).collection('synced_articles').doc(sourceId).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      AppLogger.e("[$sourceName] Failed to update sync metadata", e);
    }
  }

  Future<void> updateUncompletedIndexForMonth(String uid, String monthId) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months')
        .doc(monthId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    bool hasUncompleted = false;
    
    data.forEach((date, itemsJson) {
      if (itemsJson is List) {
        if (itemsJson.any((i) => i['isCompleted'] != true)) {
          hasUncompleted = true;
        }
      }
    });

    if (!hasUncompleted) {
      final quizzesQuery = await doc.reference.collection('quizzes')
          .where('isCompleted', isNotEqualTo: true)
          .limit(1)
          .get();
      if (quizzesQuery.docs.isNotEmpty) {
        hasUncompleted = true;
      }
    }

    final metadata = await _getSyncMetadata(uid);
    final List<String> uncompleted = List<String>.from(metadata?['uncompletedMonths'] ?? []);
    
    if (hasUncompleted) {
      if (!uncompleted.contains(monthId)) {
        uncompleted.add(monthId);
        await _updateSyncMetadata(uid, uncompletedMonths: uncompleted);
      }
    } else {
      if (uncompleted.contains(monthId)) {
        uncompleted.remove(monthId);
        await _updateSyncMetadata(uid, uncompletedMonths: uncompleted);
      }
    }
  }

  Future<void> refreshUncompletedIndex(String uid) async {
    final monthsQuery = await _db
        .collection('users')
        .doc(uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months')
        .get();

    final List<String> uncompleted = [];
    for (var doc in monthsQuery.docs) {
      final data = doc.data();
      bool hasUncompleted = false;
      
      // Check articles in root of doc
      data.forEach((date, itemsJson) {
        if (itemsJson is List) {
          if (itemsJson.any((i) => i['isCompleted'] != true)) {
            hasUncompleted = true;
          }
        }
      });

      // Also check quizzes subcollection
      if (!hasUncompleted) {
        final quizzesQuery = await doc.reference.collection('quizzes')
            .where('isCompleted', isNotEqualTo: true)
            .limit(1)
            .get();
        if (quizzesQuery.docs.isNotEmpty) {
          hasUncompleted = true;
        }
      }

      if (hasUncompleted) {
        uncompleted.add(doc.id);
      }
    }

    await _updateSyncMetadata(uid, uncompletedMonths: uncompleted);
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
      final List<dynamic> list = itemsJson as List<dynamic>;
      results[date] = list.map((i) => ArticleModel.fromJson(i as Map<String, dynamic>)).toList();
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
          final index = urlToIndex[url]!;
          var existingItem = existingItems[index];
          bool itemChanged = false;
          
          if (existingItem.title != incomingItem.title) {
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
            existingItem = existingItem.copyWith(subtitle: incomingItem.subtitle);
            itemChanged = true;
          }

          if (itemChanged) {
            existingItems[index] = existingItem;
            changed = true;
          }
        } else {
          existingItems.add(incomingItem);
          urlToIndex[incomingItem.url ?? ''] = existingItems.length - 1;
          changed = true;
        }
      }
      existing[date] = existingItems;

      if (daily.quizzes.isNotEmpty) {
        changed = true;
        final quizBatch = _db.batch();
        for (var quiz in daily.quizzes) {
          final quizId = quiz.title.hashCode.toString();
          final quizRef = monthRef.collection('quizzes').doc(quizId);
          
          quizBatch.set(quizRef, {
            'source': quiz.source,
            'title': quiz.title,
            if (quiz.url != null) 'url': quiz.url,
            'date': date,
          }, SetOptions(merge: true));
        }
        await quizBatch.commit();
      }
    }

    if (changed || existing.isEmpty) {
      final Map<String, dynamic> toSave = {};
      existing.forEach((date, items) {
        toSave[date] = items.map((i) => i.toJson()).toList();
      });

      await monthRef.set(toSave, SetOptions(merge: true));
      
      // Update uncompleted index for this specific month
      unawaited(updateUncompletedIndexForMonth(uid, docId));
    }
    AppLogger.d("[$sourceName] Sync Complete: $docId. Changed: $changed");
  }

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

      final List<dynamic> itemsJson = data[isoDate] as List<dynamic>;
      final items = itemsJson.map((i) => ArticleModel.fromJson(i as Map<String, dynamic>)).toList();

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
        unawaited(updateUncompletedIndexForMonth(user.uid, docId));
      }
    } catch (e) {
      AppLogger.e("[$sourceName] Failed to update article status", e);
    }
  }

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
      unawaited(updateUncompletedIndexForMonth(user.uid, docId));
    } catch (e) {
      AppLogger.e("[$sourceName] Failed to update quiz status", e);
    }
  }

  Future<Map<String, List<ArticleModel>>> getAllSyncedArticles({DateTime? startDate, List<String>? specificMonths}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final query = _db
        .collection('users')
        .doc(user.uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months');

    QuerySnapshot<Map<String, dynamic>> snapshot;
    
    if (specificMonths != null && specificMonths.isNotEmpty) {
      // Fetch only specific months (e.g. uncompleted ones)
      // Firestore doesn't support whereIn on document IDs easily for subcollections in a single query if too many
      // But we can fetch them in parallel.
      final List<Future<DocumentSnapshot<Map<String, dynamic>>>> futures = specificMonths.map((id) => query.doc(id).get()).toList();
      final docs = await Future.wait(futures);
      
      final Map<String, List<ArticleModel>> allArticles = {};
      for (var doc in docs) {
        if (!doc.exists) continue;
        final data = doc.data()!;
        data.forEach((date, itemsJson) {
          if (itemsJson is List) {
            final items = itemsJson.map((i) => ArticleModel.fromJson(i as Map<String, dynamic>)).toList();
            allArticles.putIfAbsent(date, () => []).addAll(items);
          }
        });
      }
      return allArticles;
    }

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
          final items = itemsJson.map((i) => ArticleModel.fromJson(i as Map<String, dynamic>)).toList();
          allArticles.putIfAbsent(date, () => []).addAll(items);
        }
      });
    }

    return allArticles;
  }

  Future<Map<String, List<QuizModel>>> getAllSyncedQuizzes({DateTime? startDate, List<String>? specificMonths}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final query = _db
        .collection('users')
        .doc(user.uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months');

    final List<DocumentSnapshot<Map<String, dynamic>>> monthDocs;

    if (specificMonths != null && specificMonths.isNotEmpty) {
      final List<Future<DocumentSnapshot<Map<String, dynamic>>>> futures = specificMonths.map((id) => query.doc(id).get()).toList();
      final snapshots = await Future.wait(futures);
      monthDocs = snapshots.where((s) => s.exists).toList();
    } else if (startDate != null) {
      final minDocId = '${startDate.year}_${startDate.month.toString().padLeft(2, '0')}';
      final snapshot = await query.where(FieldPath.documentId, isGreaterThanOrEqualTo: minDocId).get();
      monthDocs = snapshot.docs;
    } else {
      final snapshot = await query.get();
      monthDocs = snapshot.docs;
    }

    final Map<String, List<QuizModel>> allQuizzes = {};

    final List<Future<QuerySnapshot<Map<String, dynamic>>>> quizFutures = monthDocs.map((doc) => doc.reference.collection('quizzes').get()).toList();
    final List<QuerySnapshot<Map<String, dynamic>>> quizSnapshots = await Future.wait(quizFutures);

    for (int i = 0; i < monthDocs.length; i++) {
      final monthSnapshot = quizSnapshots[i];
      for (var quizDoc in monthSnapshot.docs) {
        final data = quizDoc.data();
        final date = data['date'] as String? ?? '0000-00-00'; 
        final quiz = QuizModel.fromJson(data);
        allQuizzes.putIfAbsent(date, () => []).add(quiz);
      }
    }

    return allQuizzes;
  }
}
