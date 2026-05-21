import 'package:isar_community/isar.dart';

part 'local_content.g.dart';

@collection
class LocalContent {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String contentId; // articleId or quizId

  late String type; // "article" or "quiz"
  late String year;
  late String month;
  late String date;
  late String sourceId;
  late String title;
  String? subtitle;
  String? url;

  late DateTime lastFetchedAt;
}
