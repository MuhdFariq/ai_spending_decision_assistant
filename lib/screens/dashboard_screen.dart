import 'package:flutter/material.dart';

import '../models/expenses.dart';
import '../services/budget_service.dart';
import '../services/firestore_service.dart';
import '../widgets/category_spend_bar.dart';
import '../widgets/dashboard_metric_card.dart';
import '../widgets/risk_indicator_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.monthlyBudget = BudgetService.defaultMonthlyBudget,
    this.expensesStream,
  });

  final double monthlyBudget;
  final Stream<List<Expense>>? expensesStream;

  // Theme Constants
  static const Color gold = Color(0xFFFFD700);
  static const Color charcoal = Color(0xFF1E1E1E);
  static const Color midnight = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: midnight, // Changed from default
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(color: gold)),
        backgroundColor: charcoal,
        iconTheme: const IconThemeData(color: gold),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expensesStream ?? FirestoreService.getExpenses(),
        builder: (BuildContext context, AsyncSnapshot<List<Expense>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: gold));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load dashboard data right now.',
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final List<Expense> expenses = snapshot.data ?? <Expense>[];
          final DashboardMetrics metrics = BudgetService.buildDashboardMetrics(
            expenses,
            monthlyBudget: monthlyBudget,
          );
          final List<_DashboardAlert> alerts = _buildAlerts(metrics);
          final List<MapEntry<String, double>> sortedCategories =
              metrics.categorySpending.entries.toList()
                ..sort((left, right) => right.value.compareTo(left.value));

          return RefreshIndicator(
            onRefresh: () async {},
            color: gold,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  'Spending Decision Assistant',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white, // Changed
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tracking ${metrics.monthExpenses.length} expense${metrics.monthExpenses.length == 1 ? '' : 's'} this month against a demo budget of RM${monthlyBudget.toStringAsFixed(0)}.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white54, // Changed
                  ),
                ),
                const SizedBox(height: 20),
                RiskIndicatorCard(metrics: metrics),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    DashboardMetricCard(
                      label: 'Spent This Month',
                      value: _formatCurrency(metrics.totalSpent),
                      caption: 'Current month total',
                      accentColor: gold, // Changed
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    DashboardMetricCard(
                      label: 'Remaining Budget',
                      value: _formatCurrency(metrics.remainingBudget),
                      caption: metrics.remainingBudget >= 0
                          ? 'Still available'
                          : 'Over budget already',
                      accentColor: gold, // Changed
                      icon: Icons.savings_outlined,
                    ),
                    DashboardMetricCard(
                      label: 'Projected Balance',
                      value: _formatCurrency(metrics.projectedEndBalance),
                      caption: 'Month-end forecast',
                      accentColor: gold, // Changed
                      icon: Icons.trending_up,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Prediction',
                  subtitle: 'Formula-based outlook using current month spending pace.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        metrics.forecastMessage,
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white), // Changed
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _PredictionStat(
                              label: 'Daily average',
                              value: _formatCurrency(metrics.dailyAverageSpend),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PredictionStat(
                              label: 'Days until depleted',
                              value: metrics.daysUntilDepleted?.toString() ?? 'Safe',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Smart Alerts',
                  subtitle: 'Local alerts based on budget pace and remaining room.',
                  child: alerts.isEmpty
                      ? const Text(
                          'No active alerts. Spending is within the current budget pace.',
                          style: TextStyle(color: Colors.white60), // Changed
                        )
                      : Column(
                          children: alerts
                              .map(
                                (alert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _AlertTile(alert: alert),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Spending By Category',
                  subtitle: 'Current month category totals and share of spending.',
                  child: Column(
                    children: sortedCategories
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CategorySpendBar(
                              category: entry.key,
                              amount: entry.value,
                              totalSpent: metrics.totalSpent,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Budget vs Actual',
                  subtitle: 'Overall monthly budget usage only for now.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: _normalizedBudgetUsage(
                            spent: metrics.totalSpent,
                            budget: monthlyBudget,
                          ),
                          backgroundColor: midnight, // Changed
                          valueColor: const AlwaysStoppedAnimation<Color>(gold), // Changed
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${((metrics.totalSpent / monthlyBudget) * 100).clamp(0, 999).toStringAsFixed(1)}% of monthly budget used',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70), // Changed
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_DashboardAlert> _buildAlerts(DashboardMetrics metrics) {
    final List<_DashboardAlert> alerts = <_DashboardAlert>[];

    if (metrics.riskLevel == SpendingRiskLevel.overspending) {
      alerts.add(
        _DashboardAlert(
          title: 'Overspending risk',
          message: 'Projected month-end spend is RM${metrics.projectedMonthEndSpend.toStringAsFixed(2)}, above the current budget.',
          color: Colors.redAccent, // Red for danger, keeps gold for warning
          icon: Icons.warning_amber_rounded,
        ),
      );
    } else if (metrics.riskLevel == SpendingRiskLevel.warning) {
      alerts.add(
        _DashboardAlert(
          title: 'Approaching budget limit',
          message: 'Current pace is close to the monthly budget threshold.',
          color: gold,
          icon: Icons.error_outline,
        ),
      );
    }

    if (metrics.remainingBudget <= metrics.monthlyBudget * 0.2) {
      alerts.add(
        _DashboardAlert(
          title: 'Low remaining budget',
          message: 'Only ${_formatCurrency(metrics.remainingBudget)} remains for the rest of the month.',
          color: gold,
          icon: Icons.notifications_active_outlined,
        ),
      );
    }

    return alerts;
  }

  static double _normalizedBudgetUsage({required double spent, required double budget}) {
    if (budget <= 0) return 1;
    return (spent / budget).clamp(0, 1).toDouble();
  }

  static String _formatCurrency(double amount) {
    final String prefix = amount < 0 ? '-RM' : 'RM';
    return '$prefix${amount.abs().toStringAsFixed(2)}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // charcoal
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white, // Changed
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white54), // Changed
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _PredictionStat extends StatelessWidget {
  const _PredictionStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF121212), // midnight
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38)),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFFD700), // Gold
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final _DashboardAlert alert;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: alert.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: alert.color.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(alert.icon, color: alert.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    alert.title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: alert.color),
                  ),
                  const SizedBox(height: 4),
                  Text(alert.message, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAlert {
  const _DashboardAlert({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String title;
  final String message;
  final Color color;
  final IconData icon;
}