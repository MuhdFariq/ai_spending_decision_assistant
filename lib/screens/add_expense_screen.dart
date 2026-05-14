import 'package:flutter/material.dart';
import '../models/expenses.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.expensesStream});
  final Stream<List<Expense>>? expensesStream;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  String _selectedCategory = 'Food'; 
  bool _isPredicting = false;
  final List<String> _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];

  // --- CLEAN MIDNIGHT GOLD PALETTE ---
  final Color gold = const Color(0xFFFFD700);
  final Color charcoal = const Color(0xFF1E1E1E);
  final Color midnight = const Color(0xFF121212);

  void _predictCategory() async {
    final note = _noteController.text;
    if (note.isEmpty) return;

    setState(() => _isPredicting = true);

    try {
      final ai = AiService();
      
      final predicted = await ai.predictCategory(note);

      setState(() {
        _selectedCategory = predicted; 
      });
      
    } catch (e) {
      debugPrint("Prediction Error: $e");
    } finally {
      setState(() => _isPredicting = false);
    }
  }

  Future<void> _saveExpense() async {
    final double? amount = double.tryParse(_amountController.text);
    final String note = _noteController.text;
    if (amount == null || amount <= 0 || note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and item'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final newExpense = Expense(
      amount: amount,
      note: note,
      category: _selectedCategory,
      date: DateTime.now(),
    );
    try {
      await FirestoreService.addExpense(newExpense);
      _amountController.clear();
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Expense Saved! ✨', style: TextStyle(color: Colors.black)),
          backgroundColor: gold,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We remove the hardcoded Colors.white to let the Theme take over
      appBar: AppBar(
        title: const Text('New Expense'),
        backgroundColor: Colors.transparent, // Blends with background
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- INPUT SECTION ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: charcoal,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: gold.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _amountController,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      labelStyle: TextStyle(color: gold),
                      prefixText: 'RM ',
                      prefixStyle: TextStyle(color: gold, fontSize: 24),
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const Divider(color: Colors.white10, height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'What did you buy?',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: _isPredicting ? null : _predictCategory,
                        icon: _isPredicting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.auto_awesome, size: 20, color: Colors.black),
                        style: IconButton.styleFrom(backgroundColor: gold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            const Text(" Category", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // --- CATEGORY CHIPS ---
            Wrap(
              spacing: 8,
              children: _categories.map((cat) {
                bool isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedCategory = cat),
                  selectedColor: gold,
                  checkmarkColor: Colors.black, 
                  showCheckmark: true,
                  labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                  backgroundColor: charcoal,
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // --- CONFIRM BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text('Confirm Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 40),
            const Text("Recent History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // --- HISTORY LIST ---
            StreamBuilder<List<Expense>>(
              stream: widget.expensesStream ?? FirestoreService.getExpenses(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final expenses = snapshot.data!.take(5).toList();
                return Column(
                  children: expenses.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(_getCategoryIcon(item.category), color: gold),
                      title: Text(item.note, style: const TextStyle(color: Colors.white)),
                      trailing: Text("RM${item.amount.toStringAsFixed(2)}", style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant_rounded;
      case 'Transport': return Icons.directions_bus_rounded;
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Bills': return Icons.receipt_long_rounded;
      default: return Icons.grid_view_rounded;
    }
  }
}