import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/study_item_model.dart';
import '../../models/dashboard_data.dart';

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
    final tenDaysAgo = now.subtract(const Duration(days: 10));

    // Iterate through months from startDate to now
    DateTime currentMonth = DateTime(startDate.year, startDate.month);
    
    while (currentMonth.isBefore(now) || (currentMonth.year == now.year && currentMonth.month == now.month)) {
      onStatusUpdate?.call('Checking $sourceName for ${currentMonth.year}/${currentMonth.month}...');

      // 1. Get existing data from Firestore for this source and month
      final existingData = await _getMonthDataFromFirestore(user.uid, currentMonth.year, currentMonth.month);

      // 2. Decide if we need to fetch from network
      // We fetch if:
      // a) No data exists in Firestore for this month
      // b) The month is the current month
      // c) The month contains dates within the last 10 days
      // d) forceRefresh is enabled
      bool needsFetch = existingData.isEmpty || forceRefresh;
      
      if (!needsFetch) {
        final isCurrentMonth = currentMonth.year == now.year && currentMonth.month == now.month;
        if (isCurrentMonth) {
          needsFetch = true;
        } else {
          final monthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);
          if (monthEnd.isAfter(tenDaysAgo)) {
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
          print('DEBUG: [$sourceName] No data received from network/cache for ${currentMonth.year}/${currentMonth.month}. Skipping save to preserve existing Firestore data.');
        } else {
          print('DEBUG: [$sourceName] Network fetch returned ${netData.length} daily entries for ${currentMonth.year}/${currentMonth.month}');

          // Ensure we ONLY save data (articles AND quizzes) that is on or after the startDate
          final filteredNetData = netData.map((d) {
            final itemDate = DateTime.tryParse(d.date);
            if (itemDate == null) return d;
            
            final normalizedItemDate = DateTime(itemDate.year, itemDate.month, itemDate.day);
            final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
            final normalizedNow = DateTime(now.year, now.month, now.day);
            
            bool isWithinRange = (normalizedItemDate.isAtSameMomentAs(normalizedStartDate) || 
                                 normalizedItemDate.isAfter(normalizedStartDate)) &&
                                (normalizedItemDate.isAtSameMomentAs(normalizedNow) || 
                                 normalizedItemDate.isBefore(normalizedNow));

            if (!isWithinRange) {
              return DailyStudyData(date: d.date, items: [], quizzes: []);
            }
            return d;
          }).where((d) => d.items.isNotEmpty || d.quizzes.isNotEmpty).toList();

          // 3. Merge and Save
          await _mergeAndSave(user.uid, currentMonth.year, currentMonth.month, existingData, filteredNetData, forceRefresh: forceRefresh);
        }
      }

      // Move to next month
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    }
  }

  Future<Map<String, List<StudyItem>>> _getMonthDataFromFirestore(String uid, int year, int month) async {
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
    final Map<String, List<StudyItem>> results = {};
    
    data.forEach((date, itemsJson) {
      final List<dynamic> list = itemsJson;
      results[date] = list.map((i) => StudyItem.fromJson(i)).toList();
    });

    return results;
  }

  Future<void> _mergeAndSave(
    String uid, 
    int year, 
    int month, 
    Map<String, List<StudyItem>> existing, 
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

    if (forceRefresh) {
      // If force refreshing, we want to clear the specific dates we just fetched 
      // so we can overwrite them with fresh data.
      for (var daily in incoming) {
        if (existing.containsKey(daily.date)) {
          existing.remove(daily.date);
          changed = true;
        }
      }
      print('DEBUG: [$sourceName] Force Refresh - Overwriting data for ${incoming.length} dates');
    }

    for (var daily in incoming) {
      final date = daily.date;
      final existingItems = existing[date] ?? [];
      final Map<String, int> urlToIndex = {
        for (int i = 0; i < existingItems.length; i++) existingItems[i].url: i
      };

      for (var incomingItem in daily.items) {
        if (urlToIndex.containsKey(incomingItem.url)) {
          // Check if we should update the item
          final index = urlToIndex[incomingItem.url]!;
          final existingItem = existingItems[index];
          bool itemChanged = false;
          
          // Update title if it changed
          if (existingItem.title != incomingItem.title) {
            print('DEBUG: [$sourceName] Title updated for ${incomingItem.url}:');
            print('   FROM: "${existingItem.title}"');
            print('   TO:   "${incomingItem.title}"');
            existingItem.title = incomingItem.title;
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
            print('DEBUG: [$sourceName] Updating subtitle for ${incomingItem.url}');
            existingItem.subtitle = incomingItem.subtitle;
            itemChanged = true;
          }

          if (itemChanged) {
            updatedCount++;
            changed = true;
          } else {
            duplicateCount++;
          }
        } else {
          existingItems.add(incomingItem);
          urlToIndex[incomingItem.url] = existingItems.length - 1;
          addedCount++;
          changed = true;
        }
      }
      existing[date] = existingItems;

      // Handle Quizzes
      if (daily.quizzes.isNotEmpty) {
        changed = true;
        print('DEBUG: [$sourceName] Saving ${daily.quizzes.length} quizzes for $date');
        // Quizzes are stored in a separate collection for easier status tracking
        final quizBatch = _db.batch();
        for (var quiz in daily.quizzes) {
          final quizId = quiz.title.hashCode.toString();
          final quizRef = monthRef.collection('quizzes').doc(quizId);
          quizBatch.set(quizRef, {
            ...quiz.toJson(),
            'date': date,
          }, SetOptions(merge: true));
        }
        await quizBatch.commit();
      }
    }

    print('DEBUG: [$sourceName] Sync Results - Added: $addedCount, Updated: $updatedCount, Duplicates: $duplicateCount');

    if (changed || existing.isEmpty) {
      final Map<String, dynamic> toSave = {};
      existing.forEach((date, items) {
        toSave[date] = items.map((i) => i.toJson()).toList();
      });

      await monthRef.set(toSave, SetOptions(merge: true));
    }
  }

  /// Retrieves all synced articles for this source from Firestore
  Future<Map<String, List<StudyItem>>> getAllSyncedArticles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months')
        .get();

    final Map<String, List<StudyItem>> allArticles = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      data.forEach((date, itemsJson) {
        if (itemsJson is List) {
          final items = itemsJson.map((i) => StudyItem.fromJson(i)).toList();
          allArticles.putIfAbsent(date, () => []).addAll(items);
        }
      });
    }

    return allArticles;
  }

  /// Retrieves all synced quizzes for this source from Firestore
  Future<Map<String, List<QuizDetail>>> getAllSyncedQuizzes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final snapshot = await _db
        .collection('users')
        .doc(user.uid)
        .collection('synced_articles')
        .doc(sourceId)
        .collection('months')
        .get();

    final Map<String, List<QuizDetail>> allQuizzes = {};

    for (var monthDoc in snapshot.docs) {
      final quizSnapshot = await monthDoc.reference.collection('quizzes').get();
      for (var quizDoc in quizSnapshot.docs) {
        final data = quizDoc.data();
        final date = data['date'] as String;
        final quiz = QuizDetail.fromJson(data);
        allQuizzes.putIfAbsent(date, () => []).add(quiz);
      }
    }

    return allQuizzes;
  }
}
