import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_ca_ui/shared/models/task_completion.dart';
import 'package:upsc_ca_ui/core/utils/date_formatter.dart';

void main() {
  group('Repetition Calculation Logic', () {
    final intervals = [1, 7, 30, 120, 300];
    const taskDay = "2026-05-01";
    final today = DateTime(2026, 5, 16);
    final todayStr = DateFormatter.toIso(today);

    test('First completion (Round 1) - Correct interval and nextDueDate', () {
      const existingRounds = 0;
      final nextRound = existingRounds + 1;
      final intervalIndex = existingRounds;
      
      final int? intervalUsed = intervalIndex < intervals.length ? intervals[intervalIndex] : null;
      final String? nextDueDate = intervalUsed != null 
          ? DateFormatter.toIso(today.add(Duration(days: intervalUsed))) 
          : null;

      expect(nextRound, 1);
      expect(intervalUsed, 1);
      expect(nextDueDate, "2026-05-17");
    });

    test('Second completion (Round 2) - Correct interval and nextDueDate', () {
      const existingRounds = 1;
      final nextRound = existingRounds + 1;
      final intervalIndex = existingRounds;
      
      final int? intervalUsed = intervalIndex < intervals.length ? intervals[intervalIndex] : null;
      final String? nextDueDate = intervalUsed != null 
          ? DateFormatter.toIso(today.add(Duration(days: intervalUsed))) 
          : null;

      expect(nextRound, 2);
      expect(intervalUsed, 7);
      expect(nextDueDate, "2026-05-23");
    });

    test('Final completion (exhausted intervals) - isFullyDone should be true', () {
      const existingRounds = 5; // [1, 7, 30, 120, 300] already used
      final nextRound = existingRounds + 1;
      final intervalIndex = existingRounds;
      
      final int? intervalUsed = intervalIndex < intervals.length ? intervals[intervalIndex] : null;
      final String? nextDueDate = intervalUsed != null 
          ? DateFormatter.toIso(today.add(Duration(days: intervalUsed))) 
          : null;

      final completion = TaskCompletion(
        taskDay: taskDay,
        completedDate: todayStr,
        round: nextRound,
        intervalUsed: intervalUsed,
        nextDueDate: nextDueDate,
        isFullyDone: nextDueDate == null,
      );

      expect(nextRound, 6);
      expect(intervalUsed, isNull);
      expect(nextDueDate, isNull);
      expect(completion.isFullyDone, isTrue);
    });

    test('Empty intervals - isFullyDone immediately true', () {
      final emptyIntervals = <int>[];
      const existingRounds = 0;
      
      final int? intervalUsed = existingRounds < emptyIntervals.length ? emptyIntervals[existingRounds] : null;
      final String? nextDueDate = intervalUsed != null 
          ? DateFormatter.toIso(today.add(Duration(days: intervalUsed))) 
          : null;

      expect(intervalUsed, isNull);
      expect(nextDueDate, isNull);
    });
  });
}
