enum TaskType { normal, revision }

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

class QuizDetail {
  final String source;
  final String title;
  final bool isCompleted;
  final String? url;

  QuizDetail({
    required this.source,
    required this.title,
    this.isCompleted = false,
    this.url,
  });

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    return QuizDetail(
      source: json['source'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'title': title,
      'isCompleted': isCompleted,
      'url': url,
    };
  }
}

class ArticleDetail {
  final String title;
  final String? subtitle; // Added subtitle
  final bool isCompleted;
  final String? url;
  final String? source; // Added source for grouping

  ArticleDetail({
    required this.title,
    this.subtitle,
    this.isCompleted = false,
    this.url,
    this.source,
  });

  factory ArticleDetail.fromJson(Map<String, dynamic> json) {
    String? subtitle = json['subtitle'] as String?;
    if (subtitle?.toLowerCase() == "null") subtitle = null;
    
    return ArticleDetail(
      title: json['title'] as String,
      subtitle: subtitle,
      isCompleted: json['isCompleted'] as bool? ?? false,
      url: json['url'] as String?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'isCompleted': isCompleted,
      'url': url,
      'source': source,
    };
  }
}

class DashboardTask {
  final String date;
  final int articlesDone;
  final int totalArticles;
  final int quizzesDone;
  final int totalQuizzes;
  final TaskType type;
  final int? dueDays;
  final String? lastCompleted;
  final List<RepetitionData>? repetitions;
  final List<QuizDetail> quizzes;
  final List<ArticleDetail> articles;

  DashboardTask({
    required this.date,
    required this.articlesDone,
    required this.totalArticles,
    required this.quizzesDone,
    required this.totalQuizzes,
    this.type = TaskType.normal,
    this.dueDays,
    this.lastCompleted,
    this.repetitions,
    this.quizzes = const [],
    this.articles = const [],
  });

  factory DashboardTask.fromJson(Map<String, dynamic> json) {
    return DashboardTask(
      date: json['date'] as String,
      articlesDone: json['articlesDone'] as int,
      totalArticles: json['totalArticles'] as int,
      quizzesDone: json['quizzesDone'] as int,
      totalQuizzes: json['totalQuizzes'] as int,
      type: TaskType.values.firstWhere((e) => e.name == (json['type'] ?? 'normal')),
      dueDays: json['dueDays'] as int?,
      lastCompleted: json['lastCompleted'] as String?,
      repetitions: json['repetitions'] != null
          ? (json['repetitions'] as List)
              .map((r) => RepetitionData.fromJson(r as Map<String, dynamic>))
              .toList()
          : null,
      quizzes: json['quizzes'] != null
          ? (json['quizzes'] as List)
              .map((q) => QuizDetail.fromJson(q as Map<String, dynamic>))
              .toList()
          : [],
      articles: json['articles'] != null
          ? (json['articles'] as List)
              .map((a) => ArticleDetail.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'articlesDone': articlesDone,
      'totalArticles': totalArticles,
      'quizzesDone': quizzesDone,
      'totalQuizzes': totalQuizzes,
      'type': type.name,
      'dueDays': dueDays,
      'lastCompleted': lastCompleted,
      'repetitions': repetitions?.map((r) => r.toJson()).toList(),
      'quizzes': quizzes.map((q) => q.toJson()).toList(),
      'articles': articles.map((a) => a.toJson()).toList(),
    };
  }
}

class DashboardData {
  final int daysLeft;
  final List<DashboardTask> todayTasks;
  final List<DashboardTask> notStartedTasks;
  final List<DashboardTask> completedTasks;

  DashboardData({
    required this.daysLeft,
    required this.todayTasks,
    required this.notStartedTasks,
    required this.completedTasks,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      daysLeft: json['daysLeft'] as int,
      todayTasks: (json['todayTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList(),
      notStartedTasks: (json['notStartedTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList(),
      completedTasks: (json['completedTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daysLeft': daysLeft,
      'todayTasks': todayTasks.map((t) => t.toJson()).toList(),
      'notStartedTasks': notStartedTasks.map((t) => t.toJson()).toList(),
      'completedTasks': completedTasks.map((t) => t.toJson()).toList(),
    };
  }
}
