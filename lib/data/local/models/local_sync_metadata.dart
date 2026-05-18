import 'package:isar/isar.dart';

part 'local_sync_metadata.g.dart';

@collection
class LocalSyncMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String documentId = ""; // uid_collection_originalDocId

  String collection = ""; 

  String originalDocId = ""; // The docId in Firestore

  String localData = "{}"; // JSON string

  String lastFetchedCloudCopy = "{}"; // JSON string

  int localUpdatedAt = 0; // timestamp in ms

  int cloudUpdatedAt = 0; // timestamp in ms

  int lastSyncedAt = 0; // timestamp in ms

  bool isDirty = false;

  int syncVersion = 0;
}
