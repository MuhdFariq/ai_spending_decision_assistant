import 'explainability_service.dart';

class InsightService {
  static String generateFallbackResponse({
    required String text,
    required double remainingBudget,
    required List<Map<String, dynamic>> recentExpenses,
  }) {
    final lowerText = text.toLowerCase();

    final totalRecentSpending = recentExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + ((expense['amount'] as num?)?.toDouble() ?? 0.0),
    );

    final categoryTotals = <String, double>{};
    for (final expense in recentExpenses) {
      final category = expense['category']?.toString() ?? 'Other';
      final amount = ((expense['amount'] as num?)?.toDouble() ?? 0.0);
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategory =
        sortedCategories.isNotEmpty ? sortedCategories.first.key : 'recent spending';
    final topAmount =
        sortedCategories.isNotEmpty ? sortedCategories.first.value : 0.0;

    double? requestedAmount;

    // Supports: "RM20", "rm 20", and "can I afford 20"
    final amountMatch = RegExp(
      r'(?:rm\s*)?(\d+(\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(text);

    if (amountMatch != null) {
      requestedAmount = double.tryParse(amountMatch.group(1)!);
    }

    if (lowerText.contains('afford')) {
      if (requestedAmount == null) {
        return ExplainabilityService.formatResponse(
          answer: 'I need the purchase amount to judge affordability.',
          reason: 'The question asks about affordability, but no RM amount was detected.',
          basedOn: 'Remaining budget RM${remainingBudget.toStringAsFixed(2)}.',
        );
      }

      final balanceAfter = remainingBudget - requestedAmount;

      if (requestedAmount > remainingBudget) {
        return ExplainabilityService.formatResponse(
          answer: 'No, this purchase is not affordable right now.',
          reason:
              'RM${requestedAmount.toStringAsFixed(2)} is higher than your remaining budget of RM${remainingBudget.toStringAsFixed(2)}.',
          basedOn:
              'Purchase RM${requestedAmount.toStringAsFixed(2)}, remaining budget RM${remainingBudget.toStringAsFixed(2)}.',
        );
      }

      if (balanceAfter < remainingBudget * 0.25) {
        return ExplainabilityService.formatResponse(
          answer: 'Be careful, you can afford it but it leaves little room.',
          reason:
              'After spending RM${requestedAmount.toStringAsFixed(2)}, you would only have RM${balanceAfter.toStringAsFixed(2)} left.',
          basedOn:
              'Purchase RM${requestedAmount.toStringAsFixed(2)}, remaining budget RM${remainingBudget.toStringAsFixed(2)}.',
        );
      }

      return ExplainabilityService.formatResponse(
        answer: 'Yes, this purchase looks affordable.',
        reason:
            'After spending RM${requestedAmount.toStringAsFixed(2)}, you would still have RM${balanceAfter.toStringAsFixed(2)} remaining.',
        basedOn:
            'Purchase RM${requestedAmount.toStringAsFixed(2)}, remaining budget RM${remainingBudget.toStringAsFixed(2)}.',
      );
    }

    if (lowerText.contains('why') && lowerText.contains('overspend')) {
      return ExplainabilityService.formatResponse(
        answer: 'Your spending pressure is mainly from $topCategory.',
        reason:
            '$topCategory is your highest recent category at RM${topAmount.toStringAsFixed(2)}, which reduces your remaining flexibility even if you are not fully over budget.',
        basedOn:
            'Remaining budget RM${remainingBudget.toStringAsFixed(2)}, recent spending RM${totalRecentSpending.toStringAsFixed(2)}.',
      );
    }

    if (lowerText.contains('reduce') ||
        lowerText.contains('cut down') ||
        lowerText.contains('save')) {
      return ExplainabilityService.formatResponse(
        answer: 'Reduce $topCategory spending first.',
        reason:
            '$topCategory is your largest recent spending category at RM${topAmount.toStringAsFixed(2)}, so reducing it will have the biggest immediate impact.',
        basedOn:
            'Category totals from ${recentExpenses.length} recent expense records.',
      );
    }

    return ExplainabilityService.formatResponse(
      answer: 'Your spending is within budget, but your remaining buffer is limited.',
      reason:
          'You have RM${remainingBudget.toStringAsFixed(2)} remaining, while recent spending totals RM${totalRecentSpending.toStringAsFixed(2)}.',
      basedOn:
          'Current budget and ${recentExpenses.length} recent expenses.',
    );
  }
}