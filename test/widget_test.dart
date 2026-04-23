import 'package:flutter_test/flutter_test.dart';

import 'package:ai_spending_decision_assistant/main.dart';
import 'package:ai_spending_decision_assistant/models/expenses.dart';
import 'package:ai_spending_decision_assistant/screens/home_shell.dart';

void main() {
  testWidgets('App shell shows dashboard and add expense navigation', (
    WidgetTester tester,
  ) async {
    final Stream<List<Expense>> expensesStream = Stream<List<Expense>>.value(
      <Expense>[
        Expense(
          amount: 25,
          category: 'Food',
          note: 'Lunch',
          date: DateTime.now(),
        ),
      ],
    );

    await tester.pumpWidget(
      MyApp(
        home: HomeShell(
          dashboardExpensesStream: expensesStream,
          addExpenseHistoryStream: Stream<List<Expense>>.value(<Expense>[]),
        ),
        enableAnalytics: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Financial health at a glance'), findsOneWidget);
    expect(find.text('Spent This Month'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);

    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();

    expect(find.text('Save Full Expense'), findsOneWidget);
  });
}
