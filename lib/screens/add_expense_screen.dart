import 'package:flutter/material.dart';
import '../models/expenses.dart';
import '../services/firestore_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedCategory = 'Food'; 

  final List<String> _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];

  // This is the standard save function
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

  // This is the new Quick Add function
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
        child: SingleChildScrollView( // Added scroll just in case keyboard blocks the screen
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (RM)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'What did you buy?',
                  border: OutlineInputBorder(),
                ),
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
              
              // --- QUICK ADD SECTION ---
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

              // --- MAIN SAVE BUTTON ---
              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Full Expense', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}