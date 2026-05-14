import 'package:flutter/material.dart';
import '../services/explainability_service.dart';
import '../services/firestore_service.dart';
import '../services/budget_service.dart';
import '../services/ai_service.dart';

class AffordabilityCheckerScreen extends StatefulWidget {
  const AffordabilityCheckerScreen({super.key});

  @override
  State<AffordabilityCheckerScreen> createState() =>
      _AffordabilityCheckerScreenState();
}

class _AffordabilityCheckerScreenState extends State<AffordabilityCheckerScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Midnight Gold Palette
  final Color gold = const Color(0xFFFFD700);
  final Color charcoal = const Color(0xFF1E1E1E);
  final Color midnight = const Color(0xFF121212);

  double remainingBudget = 0;
  String result = '';
  bool _isLoading = false;

  // Logic remains identical to your provided source
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

      final expenseMaps = metrics.monthExpenses.map((expense) => {
            'title': expense.note,
            'amount': expense.amount,
            'category': expense.category,
          }).toList();

      // NEW: Call the updated AiService instead of GLMService
      final aiResponse = await AiService().getAffordabilityAnalysis(
        itemName: item,
        amount: amount,
        remainingBudget: remainingBudget,
        expenses: expenseMaps,
      );

      setState(() {
        _isLoading = false;
        if (aiResponse['source'] != 'error') {
          // Success: Show Gemini's thoughts
          result = ExplainabilityService.formatResponse(
            answer: aiResponse['answer']!,
            reason: aiResponse['reason']!,
            basedOn: aiResponse['basedOn']!,
          ) + "\n\n[AI]";
        } else {
          // Error: Show your local math logic
          result = '${_buildLocalFallbackResponse(item: item, amount: amount, currentBudget: remainingBudget)}\n\n[Fallback]';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        result = '${_buildLocalFallbackResponse(item: item, amount: amount, currentBudget: remainingBudget)}\n\n[Fallback]';
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
        answer: "Yes - you can afford $item.",
        reason: 'This expense is small compared to your remaining budget.',
        basedOn: 'RM${currentBudget.toStringAsFixed(2)} budget, RM${amount.toStringAsFixed(2)} expense.',
      );
    }
    if (amount <= currentBudget) {
      return ExplainabilityService.formatResponse(
        answer: "Be careful - you can afford $item, but it's a significant share.",
        reason: 'This purchase takes a noticeable portion of your budget.',
        basedOn: 'RM${currentBudget.toStringAsFixed(2)} budget, RM${amount.toStringAsFixed(2)} expense.',
      );
    }
    return ExplainabilityService.formatResponse(
      answer: "No - you may not be able to afford $item right now.",
      reason: 'This exceeds your current remaining budget.',
      basedOn: 'Budget deficit: RM${(-remainingAfterPurchase).toStringAsFixed(2)}.',
    );
  }

  // REFINED RESULT UI
  Widget _buildFormattedResult(String responseText) {
    final sections = ExplainabilityService.parseResponseSections(responseText);
    if (sections == null) {
      return Text(responseText, style: const TextStyle(color: Colors.white));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: charcoal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: gold.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: gold, size: 20),
              const SizedBox(width: 8),
              Text("STRATATOUILLE ANALYSIS", style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Text(sections['answer'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text("WHY", style: TextStyle(color: gold.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 11)),
          Text(sections['reason'] ?? '', style: const TextStyle(fontSize: 15, color: Colors.white70, height: 1.4)),
          const SizedBox(height: 12),
          Text("BASED ON", style: TextStyle(color: gold.withOpacity(0.6), fontWeight: FontWeight.bold, fontSize: 11)),
          Text(sections['basedOn'] ?? '', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildQuickFillButton(String item, String amount) {
    return ActionChip(
      label: Text('$item - RM$amount'),
      backgroundColor: charcoal,
      labelStyle: TextStyle(color: gold, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: gold.withOpacity(0.3)),
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
      backgroundColor: midnight,
      appBar: AppBar(
        title: const Text('Affordability Checker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER SECTION
            Text("Can I afford this?", style: TextStyle(color: gold, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Check if a potential purchase fits into your current monthly recipe.",
              style: TextStyle(color: Colors.white60, fontSize: 15),
            ),
            const SizedBox(height: 24),

            // 2. INPUT CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: charcoal.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _itemController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Item Name',
                      labelStyle: TextStyle(color: gold.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.shopping_bag_outlined, color: gold.withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Amount (RM)',
                      labelStyle: TextStyle(color: gold.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: gold.withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _checkAffordability,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Ask Stratatouille', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // 3. QUICK FILL SECTION
            Text("QUICK SUGGESTIONS", style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildQuickFillButton('Coffee', '10'),
                _buildQuickFillButton('Headphones', '50'),
                _buildQuickFillButton('Shoes', '120'),
              ],
            ),

            const SizedBox(height: 32),

            // 4. RESULT SECTION
            if (result.isNotEmpty) _buildFormattedResult(result),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}