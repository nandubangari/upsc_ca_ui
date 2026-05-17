import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> calculateIncrementalUpdate(String path, Map<String, dynamic> local, Map<String, dynamic> cloud) {
  final Map<String, dynamic> updates = {};

  local.forEach((key, value) {
    final currentPath = path.isEmpty ? key : "$path.$key";
    if (!cloud.containsKey(key)) {
      updates[currentPath] = value;
    } else if (value is Map<String, dynamic> && cloud[key] is Map<String, dynamic>) {
      updates.addAll(calculateIncrementalUpdate(currentPath, value, cloud[key]));
    } else if (value != cloud[key]) {
      updates[currentPath] = value;
    }
  });

  return updates;
}

void main() {
  group('Incremental Update Logic', () {
    test('Should detect new top-level field', () {
      final local = {'name': 'Nandu', 'age': 25};
      final cloud = {'name': 'Nandu'};
      final diff = calculateIncrementalUpdate("", local, cloud);
      expect(diff, {'age': 25});
    });

    test('Should detect changed top-level field', () {
      final local = {'name': 'Nandu New'};
      final cloud = {'name': 'Nandu'};
      final diff = calculateIncrementalUpdate("", local, cloud);
      expect(diff, {'name': 'Nandu New'});
    });

    test('Should detect nested change using dot notation', () {
      final local = {
        'completed': {
          '2026_05': {
            'articles': {'art_001': true, 'art_002': true}
          }
        }
      };
      final cloud = {
        'completed': {
          '2026_05': {
            'articles': {'art_001': true}
          }
        }
      };
      final diff = calculateIncrementalUpdate("", local, cloud);
      expect(diff, {'completed.2026_05.articles.art_002': true});
    });

    test('Should return empty if identical', () {
      final local = {'a': {'b': 1}};
      final cloud = {'a': {'b': 1}};
      final diff = calculateIncrementalUpdate("", local, cloud);
      expect(diff, isEmpty);
    });
  });
}
