import 'package:flutter/material.dart';
import '../services/explainability_service.dart';
import '../services/mock_data_service.dart';

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

  late final double remainingBudget;
  String result = '';

  @override
  void initState() {
    super.initState();
    remainingBudget = MockDataService.getRemainingBudget();
  }

  void _checkAffordability() {
    final item = _itemController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (item.isEmpty || amount == null) {
      setState(() {
        result = ExplainabilityService.formatResponse(
          answer: 'Please enter a valid item name and amount.',
          reason: 'The system needs both fields to evaluate affordability.',
          basedOn: 'input validation rules.',
        );
      });
      return;
    }
    // calculate remaining budget after this purchase
    final remainingAfterPurchase = remainingBudget - amount;

    // simple affordability check based on how much of the budget is used
    if (amount <= remainingBudget * 0.25) {
      setState(() {
        result = ExplainabilityService.formatResponse(
          answer: 'Yes - you can afford $item.',
          reason:
              'This expense is small compared to your remaining budget and does not significantly impact your finances.',
          basedOn:
              'RM${remainingBudget.toStringAsFixed(2)} current budget, RM${amount.toStringAsFixed(2)} expense, leaving RM${remainingAfterPurchase.toStringAsFixed(2)}.',
        );
      });
    } else if (amount <= remainingBudget) {
      setState(() {
        result = ExplainabilityService.formatResponse(
          answer: 'Be careful - you can afford $item, but it takes a noticeable share of your budget.',
          reason:
              'This purchase takes a noticeable portion of your remaining budget and may limit future spending.',
          basedOn:
              'RM${remainingBudget.toStringAsFixed(2)} current budget, RM${amount.toStringAsFixed(2)} expense, leaving RM${remainingAfterPurchase.toStringAsFixed(2)}.',
        );
      });
    } else {
      setState(() {
        result = ExplainabilityService.formatResponse(
          answer: 'No - you may not be able to afford $item right now.',
          reason:
              'This expense exceeds your current remaining budget and may lead to overspending.',
          basedOn:
              'RM${remainingBudget.toStringAsFixed(2)} current budget, RM${amount.toStringAsFixed(2)} expense, resulting in a deficit of RM${(-remainingAfterPurchase).toStringAsFixed(2)}.',
        );
      });
    }
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
                'Enter an expense name and amount to check whether it fits your current budget.',
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
                labelText: 'Expense name',
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
                labelText: 'Amount',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _checkAffordability,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Check Affordability'),
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
                child: Text(
                  result,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}