class InsightsIASUrlBuilder {
  /// Input: DateTime(2026, 5, 2)
  /// Output: https://www.insightsonindia.com/2026/05/02/upsc-current-affairs-2-may-2026
  static String buildUrl(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString();

    final dayForSlug = date.day;
    final monthName = _monthName(date.month);

    return "https://www.insightsonindia.com/$year/$month/$day/upsc-current-affairs-$dayForSlug-$monthName-$year/";
  }

  static List<String> buildAlternativeUrls(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString();
    final dayForSlug = date.day;
    final monthName = _monthName(date.month);
    final monthNameShort = monthName.substring(0, 3);

    return [
      "https://www.insightsonindia.com/$year/$month/$day/insights-daily-current-affairs-pib-summary-$dayForSlug-$monthName-$year/",
      "https://www.insightsonindia.com/$year/$month/$day/upsc-current-affairs-$day-$monthName-$year/",
      "https://www.insightsonindia.com/$year/$month/$day/upsc-current-affairs-$day-$monthNameShort-$year/",
    ];
  }

  /// Month converter
  static String _monthName(int month) {
    const months = [
      "january", "february", "march", "april",
      "may", "june", "july", "august",
      "september", "october", "november", "december"
    ];
    return months[month - 1];
  }
}
