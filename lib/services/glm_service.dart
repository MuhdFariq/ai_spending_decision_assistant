import 'explainability_service.dart';

class GLMService {
  // Keep empty until real credentials are provided.
  static const String baseUrl = '';
  static const String apiKey = '';
  static const String modelName = '';

  static Future<String?> getAIResponse({
    required String userQuestion,
    required double remainingBudget,
    required List<Map<String, dynamic>> expenses,
  }) async {
    buildPrompt(
      userQuestion: userQuestion,
      remainingBudget: remainingBudget,
      expenses: expenses,
    );

    // Integration point for real GLM request.
    // Intentionally returns null for now so fallback logic remains active.
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

  static String? extractTextFromApiResponse(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty) {
      final firstChoice = choices.first;
      if (firstChoice is Map<String, dynamic>) {
        final message = firstChoice['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      }
    }

    final outputText = data['output_text'];
    if (outputText is String && outputText.trim().isNotEmpty) {
      return outputText.trim();
    }

    return null;
  }

  // Helpers below prepare integration without performing network calls yet.
  static Uri? buildEndpointUri() {
    if (baseUrl.isEmpty) return null;
    return Uri.tryParse(baseUrl);
  }

  static Map<String, String> buildHeaders() {
    return {
      'Content-Type': 'application/json',
      if (apiKey.isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };
  }

  static Map<String, dynamic> buildRequestPayload({
    required String userQuestion,
    required double remainingBudget,
    required List<Map<String, dynamic>> expenses,
  }) {
    final prompt = buildPrompt(
      userQuestion: userQuestion,
      remainingBudget: remainingBudget,
      expenses: expenses,
    );

    return {
      'model': modelName,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.4,
    };
  }

  static bool isConfigured() {
    return baseUrl.isNotEmpty && apiKey.isNotEmpty && modelName.isNotEmpty;
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