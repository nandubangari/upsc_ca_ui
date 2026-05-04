import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/study_item_model.dart';

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
        
        print('DEBUG: [$sourceName] Network fetch returned ${netData.fold(0, (sum, day) => sum + day.items.length)} total items for ${currentMonth.year}/${currentMonth.month}');

        // Ensure we ONLY save data that is on or after the startDate
        final filteredNetData = netData.where((d) {
          final itemDate = DateTime.tryParse(d.date);
          if (itemDate == null) return false;
          
          final normalizedItemDate = DateTime(itemDate.year, itemDate.month, itemDate.day);
          final normalizedStartDate = DateTime(startDate.year, startDate.month, startDate.day);
          
          return normalizedItemDate.isAtSameMomentAs(normalizedStartDate) || 
                 normalizedItemDate.isAfter(normalizedStartDate);
        }).toList();

        // 3. Merge and Save
        await _mergeAndSave(user.uid, currentMonth.year, currentMonth.month, existingData, filteredNetData, forceRefresh: forceRefresh);
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
    }

    print('DEBUG: [$sourceName] Sync Results - Added: $addedCount, Updated: $updatedCount, Duplicates: $duplicateCount');

    if (changed || existing.isEmpty) {
      final docId = '${year}_${month.toString().padLeft(2, '0')}';
      final Map<String, dynamic> toSave = {};
      existing.forEach((date, items) {
        toSave[date] = items.map((i) => i.toJson()).toList();
      });

      await _db
          .collection('users')
          .doc(uid)
          .collection('synced_articles')
          .doc(sourceId)
          .collection('months')
          .doc(docId)
          .set(toSave, SetOptions(merge: true));
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
        final List<dynamic> list = itemsJson;
        final items = list.map((i) => StudyItem.fromJson(i)).toList();
        allArticles.putIfAbsent(date, () => []).addAll(items);
      });
    }

    return allArticles;
  }
}
