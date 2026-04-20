import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String? id;         // The unique ID from Firebase
  final double amount;      // RM value
  final String category;    // Food, Transport, etc.
  final String note;        // "Lunch at UM"
  final DateTime date;      // When it happened

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  // This converts Firebase data (Map) into a Flutter "Expense" object
  factory Expense.fromMap(Map<String, dynamic> data, String documentId) {
    return Expense(
      id: documentId,
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Uncategorized',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  // This converts our Flutter object into a Map to save to Firebase
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
    };
  }
}