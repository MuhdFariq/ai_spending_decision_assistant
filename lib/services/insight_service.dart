import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expenses.dart';
import '../models/budgets.dart';
import 'ai_service.dart';
import 'budget_service.dart';

class InsightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AiService ai_service = AiService();

  Future<String> getBehaviorInsights(String userId) async {
    try {
      // Calculate the date 30 days ago
      DateTime thirtyDaysAgo = DateTime.now().subtract(
        const Duration(days: 30),
      );

      // Query expenses for the user in the last 30 days
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
          )
          .orderBy('date', descending: true)
          .get();

      //check if there are any expenses
      if (query.docs.isEmpty) {
        return "No expenses recorded in the last 30 days.";
      }

      // Convert query results to a list of Expense objects
      List<Expense> expenses = query.docs.map((doc) {
        return Expense.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // summarize the expenses for the AI
      String summary = _summarizeExpenses(expenses);

      //Ask Z.ai for the 3 specific spending habits or patterns based on the summary
      String prompt =
          """
      Analyze these student expenses from the last 30 days and identify 3 specific spending habits or patterns.
      Look for:
      -Weekend vs weekday trends.
      -Frequent categories or sudden spikes in spending.
      -Time-based habits (e.g., late-night spending).
      -Or anything else interesting pattern you can find!

      Expense Data:
      $summary

      Format the output as 3 clear bullet points. Keep it conversational and helpful.
      """;

      return await ai_service.getAiResponse(prompt);
    } catch (e) {
      return "Error generating insight: $e";
    }
  }

  // method to convert list into a readable string for the AI
  String _summarizeExpenses(List<Expense> expenses) {
    StringBuffer buffer = StringBuffer();
    for (var e in expenses) {
      String formattedDate = "${e.date.day}/${e.date.month}";
      buffer.writeln(
        "$formattedDate | ${e.category} | RM${e.amount} | ${e.note}",
      );
    }
    return buffer.toString();
  }

  /// Simulates a purchase and returns an AI consequence report
  Future<String> getScenarioSimulation({
    required double itemPrice,
    required double currentBalance,
    required String itemName,
  }) async {
    try {
      //Method to fetch the data of current balance from budget service

      // 1. Calculate the 'Future' state
      double remainingBalance = currentBalance - itemPrice;

      // 2. Calculate days left in the month
      DateTime now = DateTime.now();
      DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
      int daysLeft = lastDayOfMonth.difference(now).inDays;
      if (daysLeft == 0) daysLeft = 1; // Avoid division by zero

      // Calculate daily allowance after the purchase
      double dailyAllowanceAfterPurchase = remainingBalance / daysLeft;

      // 3. Prepare the prompt for Z.ai
      String prompt =
          """
      User wants to buy: $itemName
      Price: RM$itemPrice
      Current Balance: RM$currentBalance
      Days left in month: $daysLeft days
      
      If they buy this, their remaining balance will be RM$remainingBalance.
      This means they will only have RM${dailyAllowanceAfterPurchase.toStringAsFixed(2)} per day for the rest of the month.
      
      Provide a 'consequence report'. Tell them if it's a safe move or a risky one. 
      Be realistic and helpful for a student in Malaysia.
      """;

      // 4. Get the AI response in ai_service
      return await ai_service.getAiResponse(prompt);
    } catch (e) {
      return "Simulation failed: $e";
    }
  }

  /// Analyzes budget vs actual spending to suggest re-allocations
  Future<String> getBudgetOptimization({
    required Map<String, double>
    budgetedLimits, // e.g., {'Food': 400, 'Transport': 150}
    required Map<String, double>
    actualSpending, // e.g., {'Food': 450, 'Transport': 80}
  }) async {
    try {
      // 1. Create a comparison string for the AI
      StringBuffer comparison = StringBuffer();
      comparison.writeln("Category | Budgeted | Actually Spent");

      //Method to fetch the data from budget service

      //Method to calculate the total spent in each category and compare it with the budgeted limits

      budgetedLimits.forEach((category, limit) {
        double spent = actualSpending[category] ?? 0.0;
        comparison.writeln("$category | RM$limit | RM$spent");
      });

      // 2. Prepare the prompt
      String prompt =
          """
      You are an expert financial optimizer. Based on the student's monthly performance below, 
      suggest ONE specific budget re-allocation to help them stay balanced.
      
      Performance Data:
      ${comparison.toString()}
      
      Requirements:
      - If they overspend in one category but underspend in another, suggest moving funds.
      - If they are overspending everywhere, suggest a general cutback.
      - Keep the tone encouraging and brief (max 3 sentences).
      """;

      // 3. Call Z.ai
      return await ai_service.getAiResponse(prompt);
    } catch (e) {
      return "Optimization calculation failed: $e";
    }
  }

  /// Compares performance between two months to validate progress
  Future<String> getHistoricalValidation({
    required double lastMonthSavings,
    required double currentMonthSavings,
    required int adviceFollowedCount,
  }) async {
    try {
      //Method to fetch last month and current month savings from firestore/budget service and adviceFollowedCount from firestore service

      double improvementPercentage = 0;
      if (lastMonthSavings > 0) {
        improvementPercentage =
            ((currentMonthSavings - lastMonthSavings) / lastMonthSavings) * 100;
      }

      String prompt =
          """
      You are a motivational financial coach. Compare these two months of performance for a student:
      - Last Month Savings: RM$lastMonthSavings
      - Current Month Savings: RM$currentMonthSavings
      - Times they followed AI advice: $adviceFollowedCount
      
      Improvement in savings: ${improvementPercentage.toStringAsFixed(1)}%
      
      Provide a brief (2-3 sentence) validation message. 
      - If they improved, congratulate them and link it to the AI advice.
      - If they did worse, give them a gentle 'keep going' message with a tip.
      """;

      return await ai_service.getAiResponse(prompt);
    } catch (e) {
      return "Validation failed: $e";
    }
  }
}
