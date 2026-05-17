import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/local_content.dart';
import 'models/local_sync_metadata.dart';

class IsarService {
  static late Isar _isar;

  static Isar get isar => _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        LocalContentSchema,
        LocalSyncMetadataSchema,
      ],
      directory: dir.path,
    );
  }
}
