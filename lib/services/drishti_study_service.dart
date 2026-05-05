import 'package:intl/intl.dart';
import '../models/study_item_model.dart';
import '../models/dashboard_data.dart';

class DrishtiStudyService {
  /// Returns the static Drishti IAS quiz URL for a specific date
  Future<DailyStudyData?> fetchByDate(String isoDate, {Function(String)? onStatusUpdate}) async {
    try {
      final quizzes = await fetchQuizzesByDate(isoDate);
      return DailyStudyData(
        date: isoDate,
        items: [],
        quizzes: quizzes,
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<QuizDetail>> fetchQuizzesByDate(String isoDate) async {
    final dt = DateTime.parse(isoDate);
    final formattedTitleDate = DateFormat('MMMM dd, yyyy').format(dt);

    return [
      QuizDetail(
        source: 'Drishti IAS',
        title: 'Daily Current Affairs Quiz ($formattedTitleDate)',
        url: 'https://www.drishtiias.com/quiz/quizlist/daily-current-affairs',
        isCompleted: false,
      )
    ];
  }
}
