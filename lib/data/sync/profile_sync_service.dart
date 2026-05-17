import 'firestore_sync_service.dart';

class ProfileSyncService extends FirestoreSyncService {
  ProfileSyncService() : super(collectionName: 'profile');

  // Basic sync logic inherited from FirestoreSyncService.
  // Profile specific logic is handled in ProfileService using ProfileData model.
}
