class StudyItem {
  String title;
  String? subtitle; // Added subtitle
  final String url;
  final String? date;
  String? source; // Added source for grouping in dashboard

  StudyItem({
    required this.title,
    this.subtitle,
    required this.url,
    this.date,
    this.source,
  });

  factory StudyItem.fromJson(Map<String, dynamic> json) {
    String? subtitle = json['subtitle'] as String?;
    if (subtitle?.toLowerCase() == "null") subtitle = null;
    
    return StudyItem(
      title: json['title'] as String,
      subtitle: subtitle,
      url: json['url'] as String,
      date: json['date'] as String?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'url': url,
      'date': date,
      'source': source,
    };
  }
}

class DailyStudyData {
  final String date;
  final List<StudyItem> items;

  DailyStudyData({
    required this.date,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}
