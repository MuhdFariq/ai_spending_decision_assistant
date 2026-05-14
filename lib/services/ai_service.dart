import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AiService {
  static String get _apiKey => dotenv.get('GEMINI_API_KEY');
  
  // UPDATED: Using the current stable v1 endpoint and Gemini 2.5 Flash
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent';

  Future<String> _getRawGeminiResponse(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [{"text": prompt}]
          }
        ],
        "generationConfig": {
          "temperature": 0.1, // Keeps classification accurate
          "maxOutputTokens": 800,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Ensure the path to the text is correct for the v1 response structure
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      throw Exception("Unexpected API Response structure");
    } else {
      debugPrint("Full Error Body: ${response.body}");
      throw Exception("Gemini API Error: ${response.statusCode}");
    }
  }

  // FEATURE 1: Prediction (The Magic Wand)
  Future<String> predictCategory(String note) async {
    if (note.isEmpty) return 'Others';

    final prompt = "Classify this expense: '$note'. Reply with ONLY one word from these: Food, Transport, Shopping, Bills, Others.";

    try {
      final res = await _getRawGeminiResponse(prompt);
      final clean = res.trim().replaceAll('.', '');
      
      if (clean.contains('Food')) return 'Food';
      if (clean.contains('Transport')) return 'Transport';
      if (clean.contains('Shopping')) return 'Shopping';
      if (clean.contains('Bills')) return 'Bills';
      
      return 'Others';
    } catch (e) {
      debugPrint("Predict Error: $e");
      return 'Others';
    }
  }

  // FEATURE 2: Spending Assistant (The Chatbot)
  Future<Map<String, String>> getChatResponse({
    required String userQuestion,
    required double remainingBudget,
    required List<Map<String, dynamic>> expenses,
  }) async {
    final expenseContext = expenses.map((e) => "- ${e['title']}: RM${e['amount']} (${e['category']})").join("\n");

    final prompt = """
      You are a Financial Assistant.
      Budget: RM${remainingBudget.toStringAsFixed(2)}
      Expenses:
      $expenseContext

      Question: $userQuestion

      Return ONLY a JSON object (no markdown, no backticks):
      {"answer": "...", "reason": "...", "basedOn": "..."}
    """;

    try {
      final rawResponse = await _getRawGeminiResponse(prompt);
      
      // Clean up potential markdown if the AI includes it
      final cleanJson = rawResponse
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> decoded = jsonDecode(cleanJson);
      return {
        'answer': decoded['answer'] ?? "I'm not sure.",
        'reason': decoded['reason'] ?? "Data analysis incomplete.",
        'basedOn': decoded['basedOn'] ?? "Your profile.",
        'source': 'gemini_direct'
      };
    } catch (e) {
      return {
        'answer': "I hit a snag calculating that.",
        'reason': "Connection error with Gemini API.",
        'basedOn': "System Logs",
        'source': 'fallback'
      };
    }
  }

  // FEATURE 3: Affordability Analysis
  Future<Map<String, String>> getAffordabilityAnalysis({
    required String itemName,
    required double amount,
    required double remainingBudget,
    required List<Map<String, dynamic>> expenses,
  }) async {
    final expenseContext = expenses.take(5).map((e) => "- ${e['title']}: RM${e['amount']}").join("\n");

    final prompt = """
      You are a student financial advisor. 
      User wants to buy: $itemName for RM${amount.toStringAsFixed(2)}.
      Remaining Budget: RM${remainingBudget.toStringAsFixed(2)}.
      Recent Expenses:
      $expenseContext

      Analyze if they can afford this. Consider if it's a luxury or a necessity.
      Return ONLY a JSON object:
      {"answer": "Yes/No/Be Careful", "reason": "...", "basedOn": "..."}
    """;

    try {
      final rawResponse = await _getRawGeminiResponse(prompt);
      final cleanJson = rawResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleanJson);

      return {
        'answer': decoded['answer'] ?? "Analysis unavailable.",
        'reason': decoded['reason'] ?? "AI could not generate a reason.",
        'basedOn': decoded['basedOn'] ?? "Current budget status.",
        'source': 'gemini'
      };
    } catch (e) {
      // Return a structured error so the UI fallback can take over
      return {
        'answer': 'Error',
        'reason': e.toString(),
        'basedOn': 'System error',
        'source': 'error'
      };
    }
  }
}