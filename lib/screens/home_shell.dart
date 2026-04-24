import 'package:flutter/material.dart';

import '../models/expenses.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.dashboardExpensesStream,
    this.addExpenseHistoryStream,
  });

  final Stream<List<Expense>>? dashboardExpensesStream;
  final Stream<List<Expense>>? addExpenseHistoryStream;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = <Widget>[
    DashboardScreen(expensesStream: widget.dashboardExpensesStream),
    AddExpenseScreen(expensesStream: widget.addExpenseHistoryStream),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add Expense',
          ),
        ],
      ),
    );
  }
}