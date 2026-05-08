import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Quote {
  final String text;
  final String author;

  Quote({required this.text, required this.author});
}

class QuoteService {
  Future<Quote> getRandomQuote() async {
    try {
      AppLogger.d('DEBUG: [QuoteService] Fetching random quote...');
      final response = await http.get(Uri.parse('https://zenquotes.io/api/random'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final quoteData = data[0];
          return Quote(
            text: quoteData['q'] ?? "Believe you can and you're halfway there.",
            author: quoteData['a'] ?? "Theodore Roosevelt",
          );
        }
      }
      AppLogger.d('DEBUG: [QuoteService] Failed to fetch quote: ${response.statusCode}');
    } catch (e) {
      AppLogger.e('Error fetching quote', e);
    }
    // Fallback
    return Quote(
      text: "The future belongs to those who believe in the beauty of their dreams.", 
      author: "Eleanor Roosevelt"
    );
  }
}


