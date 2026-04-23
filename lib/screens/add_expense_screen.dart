import 'package:flutter/material.dart';
import '../models/expenses.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final AiService _aiService = AiService();
  
  String _selectedCategory = 'Food'; 
  bool _isPredicting = false;

  final List<String> _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];

  void _predictCategory() async {
    print("DEBUG: Using API Key: ${_aiService.apiKey.substring(0, 5)}...");
    final note = _noteController.text;
    if (note.isEmpty) return;

    setState(() => _isPredicting = true);

    try {
      final predicted = await _aiService.getAiResponse(
        "Categorize this expense: '$note'. Reply with ONLY the category name from this list: Food, Transport, Shopping, Bills, Others."
      );

      final cleanResult = predicted.trim().replaceAll('.', '');
      print("Predicted category: $cleanResult"); // Check this in terminal!
      if (_categories.contains(cleanResult)) {
        setState(() {
          _selectedCategory = cleanResult;
        });
      }else {
        // If it didn't match, let's at least show the raw result to debug
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("AI guessed: $cleanResult (No match)")),
        );
      }
    } catch (e) {
      debugPrint("AI Error: $e");
    } finally {
      setState(() => _isPredicting = false);
    }
  }

  void _saveExpense() {
    final double? amount = double.tryParse(_amountController.text);
    final String note = _noteController.text;

    if (amount != null && note.isNotEmpty) {
      final newExpense = Expense(
        amount: amount,
        note: note,
        category: _selectedCategory,
        date: DateTime.now(),
      );

      FirestoreService.addExpense(newExpense);
      
      _amountController.clear();
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense Saved!')),
      );
    }
  }

  void _quickAdd(double amount, String category) {
    final newExpense = Expense(
      amount: amount,
      note: "Quick Add", 
      category: category,
      date: DateTime.now(),
    );

    FirestoreService.addExpense(newExpense);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Quick Added RM${amount.toStringAsFixed(2)} for $category!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (RM)',
                  border: OutlineInputBorder(),
                  prefixText: 'RM ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'What did you buy?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _isPredicting ? null : _predictCategory,
                    icon: _isPredicting 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                    tooltip: "Auto-Categorize",
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Text("Category:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: _categories.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 30),
              
              const Center(child: Text("Quick Add", style: TextStyle(color: Colors.grey))),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _quickAdd(10.0, "Food"),
                    icon: const Icon(Icons.fastfood),
                    label: const Text("RM10 Food"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _quickAdd(5.0, "Transport"),
                    icon: const Icon(Icons.directions_bus),
                    label: const Text("RM5 Bus"),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Full Expense', style: TextStyle(fontSize: 16)),
              ),

              // --- NEW HISTORY SECTION START ---
              const SizedBox(height: 40),
              const Text("Recent History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              StreamBuilder<List<Expense>>(
                stream: FirestoreService.getExpenses(), 
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: Text("No expenses yet. Add one above!")),
                    );
                  }
                  
                  final expenses = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true, // Allows ListView to live inside SingleChildScrollView
                    physics: const NeverScrollableScrollPhysics(), // Scroll is handled by the parent
                    itemCount: expenses.length > 5 ? 5 : expenses.length, // Show latest 5
                    itemBuilder: (context, index) {
                      final item = expenses[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.shade50,
                          child: Icon(_getCategoryIcon(item.category), size: 18),
                        ),
                        title: Text(item.note),
                        subtitle: Text("${item.date.day}/${item.date.month}/${item.date.year}"),
                        trailing: Text(
                          "RM${item.amount.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onLongPress: () {
                          // Bonus: Delete on long press
                          _showDeleteDialog(item.id!, item.note);
                        },
                      );
                    },
                  );
                },
              ),
              // --- NEW HISTORY SECTION END ---
            ],
          ),
        ),
      ),
    );
  }

  // Helper to make the list look pretty with icons
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.restaurant;
      case 'Transport': return Icons.directions_car;
      case 'Shopping': return Icons.shopping_bag;
      case 'Bills': return Icons.receipt_long;
      default: return Icons.category;
    }
  }

  // Helper for deleting entries
  void _showDeleteDialog(String id, String note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Expense?"),
        content: Text("Are you sure you want to delete '$note'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirestoreService.deleteExpense(id);
              Navigator.pop(context);
            }, 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}