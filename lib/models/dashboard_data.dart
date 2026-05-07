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
  final String? completedAt;

  QuizDetail({
    required this.source,
    required this.title,
    this.isCompleted = false,
    this.url,
    this.completedAt,
  });

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    return QuizDetail(
      source: json['source'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      url: json['url'] as String?,
      completedAt: json['completedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'title': title,
      'isCompleted': isCompleted,
      'url': url,
      'completedAt': completedAt,
    };
  }

  QuizDetail copyWith({
    String? source,
    String? title,
    bool? isCompleted,
    String? url,
    String? completedAt,
  }) {
    return QuizDetail(
      source: source ?? this.source,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      url: url ?? this.url,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class ArticleDetail {
  final String title;
  final String? subtitle;
  final bool isCompleted;
  final String? url;
  final String? source;
  final String? completedAt; // Added to track when it was read

  ArticleDetail({
    required this.title,
    this.subtitle,
    this.isCompleted = false,
    this.url,
    this.source,
    this.completedAt,
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
      completedAt: json['completedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'isCompleted': isCompleted,
      'url': url,
      'source': source,
      'completedAt': completedAt,
    };
  }

  ArticleDetail copyWith({
    String? title,
    String? subtitle,
    bool? isCompleted,
    String? url,
    String? source,
    String? completedAt,
  }) {
    return ArticleDetail(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isCompleted: isCompleted ?? this.isCompleted,
      url: url ?? this.url,
      source: source ?? this.source,
      completedAt: completedAt ?? this.completedAt,
    );
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

  bool get isFullyCompleted => (totalArticles + totalQuizzes) > 0 && 
                               (articlesDone + quizzesDone) == (totalArticles + totalQuizzes);

  DateTime get isoDate {
    try {
      return DateTime.parse(_toIsoDate(date));
    } catch (_) {
      return DateTime(2000);
    }
  }

  String _toIsoDate(String dateStr) {
    try {
      return DateTime.parse(dateStr).toIso8601String().split('T')[0];
    } catch (_) {
      try {
        final parts = dateStr.split(' ');
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final monthStr = parts[1].toUpperCase();
          final year = parts[2];
          final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
          final monthIdx = months.indexOf(monthStr) + 1;
          if (monthIdx > 0) return '$year-${monthIdx.toString().padLeft(2, '0')}-$day';
        }
      } catch (_) {}
      return "0000-00-00";
    }
  }

  DashboardTask copyWith({
    String? date,
    int? articlesDone,
    int? totalArticles,
    int? quizzesDone,
    int? totalQuizzes,
    TaskType? type,
    int? dueDays,
    String? lastCompleted,
    List<RepetitionData>? repetitions,
    List<QuizDetail>? quizzes,
    List<ArticleDetail>? articles,
  }) {
    return DashboardTask(
      date: date ?? this.date,
      articlesDone: articlesDone ?? this.articlesDone,
      totalArticles: totalArticles ?? this.totalArticles,
      quizzesDone: quizzesDone ?? this.quizzesDone,
      totalQuizzes: totalQuizzes ?? this.totalQuizzes,
      type: type ?? this.type,
      dueDays: dueDays ?? this.dueDays,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      repetitions: repetitions ?? this.repetitions,
      quizzes: quizzes ?? this.quizzes,
      articles: articles ?? this.articles,
    );
  }
}

class DashboardData {
  final int daysLeft;
  final List<DashboardTask> todayTasks;
  final List<DashboardTask> inProgressTasks;
  final List<DashboardTask> notStartedTasks;
  final List<DashboardTask> completedTasks;

  DashboardData({
    required this.daysLeft,
    required this.todayTasks,
    this.inProgressTasks = const [],
    required this.notStartedTasks,
    required this.completedTasks,
  });

  /// 🟢 Returns all tasks across all sections, sorted by date (latest first).
  List<DashboardTask> get allTasks {
    final List<DashboardTask> combined = [
      ...todayTasks,
      ...inProgressTasks,
      ...notStartedTasks,
      ...completedTasks,
    ];
    
    // Sort by date (latest first) to ensure consistent ordering everywhere
    combined.sort((a, b) {
      final isoA = _toIso(a.date);
      final isoB = _toIso(b.date);
      return isoB.compareTo(isoA);
    });
    
    return combined;
  }

  String _toIso(String dateStr) {
    try {
      return DateTime.parse(dateStr).toIso8601String().split('T')[0];
    } catch (_) {
      try {
        // Handle "DD MMM YYYY" format
        final parts = dateStr.split(' ');
        if (parts.length == 3) {
          final day = parts[0].padLeft(2, '0');
          final monthStr = parts[1].toUpperCase();
          final year = parts[2];
          
          final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
          final monthIdx = months.indexOf(monthStr) + 1;
          if (monthIdx > 0) {
            return '$year-${monthIdx.toString().padLeft(2, '0')}-$day';
          }
        }
      } catch (_) {}
      return "0000-00-00";
    }
  }

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      daysLeft: json['daysLeft'] as int,
      todayTasks: (json['todayTasks'] as List)
          .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
          .toList(),
      inProgressTasks: json['inProgressTasks'] != null
          ? (json['inProgressTasks'] as List)
              .map((t) => DashboardTask.fromJson(t as Map<String, dynamic>))
              .toList()
          : [],
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
      'inProgressTasks': inProgressTasks.map((t) => t.toJson()).toList(),
      'notStartedTasks': notStartedTasks.map((t) => t.toJson()).toList(),
      'completedTasks': completedTasks.map((t) => t.toJson()).toList(),
    };
  }
}
