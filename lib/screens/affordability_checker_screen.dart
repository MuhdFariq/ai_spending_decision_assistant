import 'package:flutter/material.dart';
import '../services/explainability_service.dart';
import '../services/glm_service.dart';
import '../services/firestore_service.dart';
import '../services/budget_service.dart';

class AffordabilityCheckerScreen extends StatefulWidget {
  const AffordabilityCheckerScreen({super.key});

  @override
  State<AffordabilityCheckerScreen> createState() =>
      _AffordabilityCheckerScreenState();
}

class _AffordabilityCheckerScreenState
    extends State<AffordabilityCheckerScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  double remainingBudget = 0;
  String result = '';
  bool _isLoading = false;

  Future<void> _checkAffordability() async {
    final item = _itemController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (item.isEmpty || amount == null || amount <= 0 || _isLoading) {
      setState(() {
        result = ExplainabilityService.formatResponse(
          answer: 'Please enter a valid item name and amount.',
          reason: 'The system needs both fields and a positive amount to evaluate affordability.',
          basedOn: 'input validation rules.',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      result = '';
    });

    try {
      final expenses = await FirestoreService.getExpenses().first;
      final metrics = BudgetService.buildDashboardMetrics(expenses);
      remainingBudget = metrics.remainingBudget;

      final expenseMaps = metrics.monthExpenses.map((expense) {
        return {
          'title': expense.note,
          'amount': expense.amount,
          'category': expense.category,
        };
      }).toList();

      final backendResponse = await GLMService.getStructuredResponse(
        userQuestion: 'Can I afford $item for RM${amount.toStringAsFixed(2)}?',
        remainingBudget: remainingBudget,
        expenses: expenseMaps,
        featureType: 'affordability',
        amount: amount,
      );

      setState(() {
        _isLoading = false;
        if (backendResponse != null) {
          final label = backendResponse.source == 'glm' ? '[AI]' : '[Fallback]';
          result = '${backendResponse.asExplainabilityText()}\n\n$label';
        } else {
          result = '${_buildLocalFallbackResponse(item: item, amount: amount, currentBudget: remainingBudget)}\n\n[Fallback]';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        result = ExplainabilityService.formatResponse(
          answer: 'Unable to check affordability right now.',
          reason: 'The system could not load the latest expense data.',
          basedOn: 'Firestore expense records.',
        );
      });
    }
  }

  String _buildLocalFallbackResponse({
    required String item,
    required double amount,
    required double currentBudget,
  }) {
    final remainingAfterPurchase = currentBudget - amount;

    if (amount <= currentBudget * 0.25) {
      return ExplainabilityService.formatResponse(
        answer: 'Yes - you can afford $item.',
        reason:
            'This expense is small compared to your remaining budget and does not significantly impact your finances.',
        basedOn:
            'RM${currentBudget.toStringAsFixed(2)} current budget, RM${amount.toStringAsFixed(2)} expense, leaving RM${remainingAfterPurchase.toStringAsFixed(2)}.',
      );
    }

    if (amount <= currentBudget) {
      return ExplainabilityService.formatResponse(
        answer:
            'Be careful - you can afford $item, but it takes a noticeable share of your budget.',
        reason:
            'This purchase takes a noticeable portion of your remaining budget and may limit future spending.',
        basedOn:
            'RM${currentBudget.toStringAsFixed(2)} current budget, RM${amount.toStringAsFixed(2)} expense, leaving RM${remainingAfterPurchase.toStringAsFixed(2)}.',
      );
    }

    return ExplainabilityService.formatResponse(
      answer: 'No - you may not be able to afford $item right now.',
      reason:
          'This expense exceeds your current remaining budget and may lead to overspending.',
      basedOn:
          'RM${currentBudget.toStringAsFixed(2)} current budget, RM${amount.toStringAsFixed(2)} expense, resulting in a deficit of RM${(-remainingAfterPurchase).toStringAsFixed(2)}.',
    );
  }

  Widget _buildFormattedResult(String responseText) {
    final sections = ExplainabilityService.parseResponseSections(responseText);
    if (sections == null) {
      return Text(
        responseText,
        style: const TextStyle(fontSize: 16, height: 1.4),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                const TextSpan(
                  text: 'Answer: ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                TextSpan(
                  text: sections['answer'] ?? '',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Why: ${sections['reason'] ?? ''}',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on: ${sections['basedOn'] ?? ''}',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 10),

          if (responseText.contains('[AI]'))
            Text(
              'AI response',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),

          if (responseText.contains('[Fallback]'))
            Text(
              'AI fallback response',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Widget _buildQuickFillButton(String item, String amount) {
    return ActionChip(
      label: Text('$item - RM$amount'),
      onPressed: () {
        setState(() {
          _itemController.text = item;
          _amountController.text = amount;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Can I Afford This?'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: const Text(
                'Enter an item and amount to see if it fits your remaining budget.',
                style: TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickFillButton('Coffee', '10'),
                _buildQuickFillButton('Headphones', '50'),
                _buildQuickFillButton('Shoes', '120'),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _itemController,
              decoration: InputDecoration(
                labelText: 'Item name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (RM)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkAffordability,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isLoading ? 'Checking...' : 'Check if I can afford this',
              ),
            ),
            const SizedBox(height: 20),
            if (result.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildFormattedResult(result),
              ),
          ],
        ),
      ),
    );
  }
}