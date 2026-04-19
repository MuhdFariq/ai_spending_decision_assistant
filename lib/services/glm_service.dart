class GLMService {
  // Later: put your real values here
  static const String baseUrl = '';
  static const String apiKey = '';
  static const String modelName = '';

  static Future<String?> getAIResponse({
    required String userQuestion,
    required double remainingBudget,
    required List<Map<String, dynamic>> expenses,
  }) async {
    final prompt = buildPrompt(
      userQuestion: userQuestion,
      remainingBudget: remainingBudget,
      expenses: expenses,
    );

    // TEMP:
    // No real API call yet, so return null and let fallback logic run.
    //
    // Later this function will:
    // 1. send prompt to GLM
    // 2. parse response
    // 3. return AI text
    // 4. return null on failure
    return null;
  }

  static String buildPrompt({
    required String userQuestion,
    required double remainingBudget,
    required List<Map<String, dynamic>> expenses,
  }) {
    final expenseList = expenses
        .map((e) => "- ${e['title']} RM${e['amount']} (${e['category']})")
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
    // TEMP placeholder.
    // Later, adapt this to the real GLM response shape.
    //
    // Example idea:
    // return data['choices']?[0]?['message']?['content'];

    return null;
  }

  static bool isConfigured() {
    return baseUrl.isNotEmpty && apiKey.isNotEmpty && modelName.isNotEmpty;
  }
}