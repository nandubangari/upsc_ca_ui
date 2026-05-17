import 'package:isar/isar.dart';

part 'local_sync_metadata.g.dart';

@collection
class LocalSyncMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String documentId; // uid_collection_originalDocId

  late String collection; 

  late String originalDocId; // The docId in Firestore

  late String localData; // JSON string

  late String lastFetchedCloudCopy; // JSON string

  late int localUpdatedAt; // timestamp in ms

  late int cloudUpdatedAt; // timestamp in ms

  late int lastSyncedAt; // timestamp in ms

  late bool isDirty;

  late int syncVersion;
}
