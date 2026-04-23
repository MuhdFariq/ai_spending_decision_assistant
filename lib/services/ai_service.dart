import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static String get _apiKey => dotenv.get('ZAI_API_KEY', fallback: '');

  static const String _baseUrl = 'https://api.ilmu.ai/anthropic/v1/messages';

  Future<String> getAiResponse(String prompt) async {
    if (_apiKey.isEmpty) throw Exception('API key missing');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'ilmu-glm-5.1', 
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      } else {
        throw Exception('AI Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<String> predictCategory(String note) async {
    if (note.isEmpty) return 'Others';

    final prompt =
        """
    Categorize this expense note: "$note". 
    Reply with ONLY ONE word from this list: Food, Transport, Shopping, Bills, Others.
    """;

    final response = await getAiResponse(prompt);

    // Clean the response (remove dots, spaces, or extra text)
    final cleanResponse = response.trim().replaceAll('.', '');

    final validCategories = [
      'Food',
      'Transport',
      'Shopping',
      'Bills',
      'Others',
    ];
    if (validCategories.contains(cleanResponse)) {
      return cleanResponse;
    }
    return 'Others';
  }
}
