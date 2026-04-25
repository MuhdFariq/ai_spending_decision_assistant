import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expenses.dart'; // Make sure this path is correct!

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a new expense
  static Future<void> addExpense(Expense expense) async {
    await _firestore.collection('expenses').add(expense.toMap());
  }

  // Get a list of expenses for the Dashboard (Member B)
  // Member B needs this for the Dashboard!
  static Stream<List<Expense>> getExpenses() {
    return _firestore
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Member D needs this for AI insights!
  static Future<double> getTotalByCategory(String category) async {
    final query = await _firestore
        .collection('expenses')
        .where('category', isEqualTo: category)
        .get();
    
    double total = 0;
    for (var doc in query.docs) {
      total += (doc.data()['amount'] ?? 0);
    }
    return total;
  }

  static Future<void> deleteExpense(String id) async {
    await _firestore.collection('expenses').doc(id).delete();
  }
}