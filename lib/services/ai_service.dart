import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static String get _apiKey =>
      dotenv.get('ZAI_API_KEY', fallback: 'Key not found');
  static const String _baseUrl =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';

  Future<String> getAiResponse(String prompt) async {
    if (_apiKey.isEmpty)
      return "Error: API Key is missing. Check your .env file.";

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'glm-4-flash', // The free/fast model
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "AI Error: ${response.statusCode}";
      }
    } catch (e) {
      return "Connection Error: $e";
    }
  }

  // Member C: Specialized function for auto-categorization
  Future<String> predictCategory(String note) async {
    if (note.isEmpty) return 'Others';

    // We give the AI a very specific instruction (a "System Prompt")
    final prompt = """
    Categorize this expense note: "$note". 
    Reply with ONLY ONE word from this list: Food, Transport, Shopping, Bills, Others.
    """;

    final response = await getAiResponse(prompt);
    
    // Clean the response (remove dots, spaces, or extra text)
    final cleanResponse = response.trim().replaceAll('.', '');
    
    // Make sure the AI didn't hallucinate a category not in our list
    final validCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];
    if (validCategories.contains(cleanResponse)) {
      return cleanResponse;
    }
    return 'Others';
  }
}
