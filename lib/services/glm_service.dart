import 'dart:convert';

import 'package:http/http.dart' as http;

import 'explainability_service.dart';

class AiBrainResponse {
  const AiBrainResponse({
    required this.answer,
    required this.reason,
    required this.basedOn,
    required this.source,
  });

  final String answer;
  final String reason;
  final String basedOn;
  final String source;

  String asExplainabilityText() {
    return ExplainabilityService.formatResponse(
      answer: answer,
      reason: reason,
      basedOn: basedOn,
    );
  }
}

class GLMService {
  // Uses localhost for desktop/web; 10.0.2.2 supports Android emulator.
  static const List<String> _backendBaseUrls = <String>[
    'http://127.0.0.1:8000',
  ];

  static Future<String?> getAIResponse({
    required String userQuestion,
    required double remainingBudget,
    required List<Map<String, dynamic>> expenses,
    String featureType = 'chat',
    double amount = 0.0,
  }) async {
    final structured = await getStructuredResponse(
      userQuestion: userQuestion,
      remainingBudget: remainingBudget,
      expenses: expenses,
      featureType: featureType,
      amount: amount,
    );

    return structured?.asExplainabilityText();
  }

  static Future<AiBrainResponse?> getStructuredResponse({
    required String userQuestion,
    required double remainingBudget,
    required List<Map<String, dynamic>> expenses,
    String featureType = 'chat',
    double amount = 0.0,
  }) async {
    final payload = {
      'user_question': userQuestion,
      'remaining_budget': remainingBudget,
      'feature_type': featureType,
      'amount': amount,
      'recent_expenses': expenses,
    };

    for (final baseUrl in _backendBaseUrls) {
      final endpoint = Uri.tryParse('$baseUrl/ai/respond');
      if (endpoint == null) continue;

      try {
        final response = await http
            .post(
              endpoint,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode != 200) {
          continue;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }

        final answer = decoded['answer']?.toString().trim();
        final reason = decoded['reason']?.toString().trim();
        final basedOn = decoded['basedOn']?.toString().trim();
        final source = decoded['source']?.toString().trim() ?? 'fallback';

        if ((answer ?? '').isEmpty ||
            (reason ?? '').isEmpty ||
            (basedOn ?? '').isEmpty) {
          continue;
        }

        return AiBrainResponse(
          answer: answer!,
          reason: reason!,
          basedOn: basedOn!,
          source: source,
        );
      } catch (_) {
        // Swallow errors and try next endpoint.
      }
    }

    // Returning null keeps existing fallback behavior active.
    return null;
  }

  static String buildPrompt({
    required String userQuestion,
    required double remainingBudget,
    required List<Map<String, dynamic>> expenses,
  }) {
    // build prompt using current budget + recent expenses context
    final expenseList = expenses
        .map((e) => '- ${e['title']} RM${e['amount']} (${e['category']})')
        .join('\n');

    return '''
You are an AI financial assistant for budgeting and spending decisions.

User question:
$userQuestion

Current remaining budget:
RM${remainingBudget.toStringAsFixed(2)}

Recent expenses:
$expenseList

You must respond STRICTLY in this format:

Answer:
<clear answer or recommendation>

Reason:
<brief explanation tied to the user's spending context>

Based on:
<data reference using the given budget and expenses>
''';
  }

  static String ensureExplainabilityFormat({
    required String responseText,
    required double remainingBudget,
    required int recentExpenseCount,
  }) {
    final trimmed = responseText.trim();
    if (_hasRequiredSections(trimmed)) return trimmed;

    final safeAnswer = trimmed.isEmpty
        ? 'I recommend reviewing your spending before making this decision.'
        : trimmed;

    return ExplainabilityService.formatResponse(
      answer: safeAnswer,
      reason:
          'This recommendation uses your current budget context and recent spending activity.',
      basedOn:
          'RM${remainingBudget.toStringAsFixed(2)} remaining budget and $recentExpenseCount recent expenses.',
    );
  }

  static bool _hasRequiredSections(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('answer:') &&
        lowerText.contains('reason:') &&
        lowerText.contains('based on:');
  }
}