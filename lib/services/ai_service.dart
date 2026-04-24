import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  String get apiKey => _apiKey;

  static String get _apiKey =>
      dotenv.get('ZAI_API_KEY', fallback: 'Key not found');
  static const String _baseUrl =
      'https://api.ilmu.ai/anthropic/v1/messages';

  Future<String> getAiResponse(String prompt) async {
    if (_apiKey.isEmpty)
      return "Error: API Key is missing. Check your .env file.";

    try {
      final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        // Auth field must be ANTHROPIC_AUTH_TOKEN style 
        'x-api-key': _apiKey, 
        'anthropic-version': '2023-06-01', // Required for this format
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'ilmu-glm-5.1', // 
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

      print("DEBUG Status: ${response.statusCode}");
      print("DEBUG Body: ${response.body}");

      if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Anthropic format returns data['content'][0]['text']
      return data['content'][0]['text']; 
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
