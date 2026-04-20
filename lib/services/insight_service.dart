import 'explainability_service.dart';

class InsightService {

  // simple rule-based responses used when AI API is not available
  static String generateFallbackResponse({
    required String text,
    required double remainingBudget,
    required List<Map<String, dynamic>> recentExpenses,
  }) {
    final lowerText = text.toLowerCase();

    final foodExpenses = recentExpenses
        .where((expense) => expense['category'] == 'Food')
        .toList();

    final totalRecentSpending = recentExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + (expense['amount'] as double),
    );

    if (lowerText.contains('why') && lowerText.contains('overspend')) {
      return ExplainabilityService.formatResponse(
        answer: 'You may be overspending mostly in food and entertainment.',
        reason:
            'You have ${foodExpenses.length} recent food purchases, and entertainment also takes a noticeable share of your recent spending.',
        basedOn:
            'RM${remainingBudget.toStringAsFixed(2)} remaining budget, RM${totalRecentSpending.toStringAsFixed(2)} recent spending, including items like ${recentExpenses[0]['title']} and ${recentExpenses[3]['title']}.',
      );
    }

    if (lowerText.contains('afford')) {
      return ExplainabilityService.formatResponse(
        answer: 'Be careful with this purchase.',
        reason:
            'Your remaining budget is RM${remainingBudget.toStringAsFixed(2)}, so extra spending gives you less room for upcoming needs.',
        basedOn:
            'Current remaining budget and ${recentExpenses.length} recent expenses.',
      );
    }

    if (lowerText.contains('reduce') ||
        lowerText.contains('cut down') ||
        lowerText.contains('save')) {
      return ExplainabilityService.formatResponse(
        answer: 'You should consider reducing food and entertainment spending first.',
        reason:
            'These categories appear most often in your recent transactions and are usually the easiest place to trim non-essential costs.',
        basedOn:
            'Recent categories include Food, Transport, and Entertainment, with Food appearing most frequently.',
      );
    }

    if (lowerText.contains('spending')) {
      return ExplainabilityService.formatResponse(
        answer: 'Your spending looks active, especially in day-to-day purchases.',
        reason:
            'Repeated small purchases can add up quickly, even when each one feels manageable.',
        basedOn:
            'Recent expenses such as ${recentExpenses[0]['title']}, ${recentExpenses[1]['title']}, and ${recentExpenses[2]['title']}.',
      );
    }

    return ExplainabilityService.formatResponse(
      answer:
          'I can help with overspending analysis, affordability checks, and ways to reduce spending.',
      reason: 'I can give better guidance when your question is more specific.',
      basedOn: 'Current mock budget and recent expense data.',
    );
  }
}