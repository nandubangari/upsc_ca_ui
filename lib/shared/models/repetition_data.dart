class RepetitionData {
  final int number;
  final DateTime date;
  final int totalQuestions;
  final int attempted;
  final int notAttempted;
  final int correct;
  final int wrong;
  final int totalMarks;

  RepetitionData({
    required this.number,
    required this.date,
    required this.totalQuestions,
    required this.attempted,
    required this.notAttempted,
    required this.correct,
    required this.wrong,
    required this.totalMarks,
  });

  double get accuracy => attempted > 0 ? (correct / attempted) * 100 : 0;
  int get score => correct * 4; // Assuming 4 marks per correct answer

  factory RepetitionData.fromJson(Map<String, dynamic> json) {
    return RepetitionData(
      number: json['number'] as int,
      date: DateTime.parse(json['date'] as String),
      totalQuestions: json['totalQuestions'] as int,
      attempted: json['attempted'] as int,
      notAttempted: json['notAttempted'] as int,
      correct: json['correct'] as int,
      wrong: json['wrong'] as int,
      totalMarks: json['totalMarks'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'date': date.toIso8601String(),
      'totalQuestions': totalQuestions,
      'attempted': attempted,
      'notAttempted': notAttempted,
      'correct': correct,
      'wrong': wrong,
      'totalMarks': totalMarks,
    };
  }
}
