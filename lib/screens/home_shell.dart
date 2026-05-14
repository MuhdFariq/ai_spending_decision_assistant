import 'package:flutter/material.dart';

import '../models/expenses.dart';
import 'add_expense_screen.dart';
import 'dashboard_screen.dart';
import 'ai_chat_screen.dart';
import 'affordability_checker_screen.dart';

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

  // Theme Constants
  static const Color gold = Color(0xFFFFD700);
  static const Color charcoal = Color(0xFF1E1E1E);
  static const Color midnight = Color(0xFF121212);

  late final List<Widget> _screens = <Widget>[
    DashboardScreen(expensesStream: widget.dashboardExpensesStream),
    AddExpenseScreen(expensesStream: widget.addExpenseHistoryStream),
    const AiChatScreen(),
    const AffordabilityCheckerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: midnight, // Applied Midnight background
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: charcoal, // Applied Charcoal background
          indicatorColor: gold.withOpacity(0.2), // Subtle gold indicator
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: gold, fontWeight: FontWeight.bold);
            }
            return const TextStyle(color: Colors.white54);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: gold);
            }
            return const IconThemeData(color: Colors.white54);
          }),
        ),
        child: NavigationBar(
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
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'AI Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Afford',
            ),
          ],
        ),
      ),
    );
  }
}