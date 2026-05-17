import 'package:flutter_test/flutter_test.dart';
import 'package:upsc_ca_ui/core/utils/insights_ias_url_builder.dart';

void main() {
  group('InsightsIASUrlBuilder', () {
    test('buildUrl handles single digit day correctly (no leading zero)', () {
      final date = DateTime(2026, 5, 9);
      final url = InsightsIASUrlBuilder.buildUrl(date);
      expect(url, contains('/2026/05/9/'));
      expect(url, 'https://www.insightsonindia.com/2026/05/9/upsc-current-affairs-9-may-2026/');
    });

    test('buildUrl handles double digit day correctly', () {
      final date = DateTime(2026, 5, 12);
      final url = InsightsIASUrlBuilder.buildUrl(date);
      expect(url, contains('/2026/05/12/'));
      expect(url, 'https://www.insightsonindia.com/2026/05/12/upsc-current-affairs-12-may-2026/');
    });

    test('buildAlternativeUrls handles single digit day correctly (no leading zero)', () {
      final date = DateTime(2026, 5, 9);
      final urls = InsightsIASUrlBuilder.buildAlternativeUrls(date);
      
      for (var url in urls) {
        expect(url, contains('/2026/05/9/'));
      }
      
      expect(urls[0], 'https://www.insightsonindia.com/2026/05/9/insights-daily-current-affairs-pib-summary-9-may-2026/');
    });
  });
}
