class GLMService {
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
    // placeholder for real GLM API call (to be implemented later)
    return null;
  }

  static bool isConfigured() {
    return baseUrl.isNotEmpty && apiKey.isNotEmpty && modelName.isNotEmpty;
  }
}