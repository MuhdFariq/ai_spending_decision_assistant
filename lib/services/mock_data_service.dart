// temporary mock data until backend integration is ready
class MockDataService {
  static double getRemainingBudget() {
    return 80.0;
  }

  static List<Map<String, dynamic>> getRecentExpenses() {
    return [
      {'title': 'Tealive', 'amount': 14.90, 'category': 'Food'},
      {'title': 'McD', 'amount': 18.50, 'category': 'Food'},
      {'title': 'Grab', 'amount': 12.00, 'category': 'Transport'},
      {'title': 'Steam Game', 'amount': 25.00, 'category': 'Entertainment'},
    ];
  }
}