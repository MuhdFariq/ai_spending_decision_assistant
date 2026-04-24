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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: StreamBuilder<List<Expense>>(
        stream: expensesStream ?? FirestoreService.getExpenses(),
        builder: (BuildContext context, AsyncSnapshot<List<Expense>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load dashboard data right now.',
                  style: theme.textTheme.bodyLarge,
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
              metrics.categorySpending.entries.toList()..sort((
                MapEntry<String, double> left,
                MapEntry<String, double> right,
              ) {
                return right.value.compareTo(left.value);
              });

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  'Spending Decision Assistant',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tracking ${metrics.monthExpenses.length} expense${metrics.monthExpenses.length == 1 ? '' : 's'} this month against a demo budget of RM${monthlyBudget.toStringAsFixed(0)}.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
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
                      accentColor: Colors.deepPurple,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    DashboardMetricCard(
                      label: 'Remaining Budget',
                      value: _formatCurrency(metrics.remainingBudget),
                      caption: metrics.remainingBudget >= 0
                          ? 'Still available'
                          : 'Over budget already',
                      accentColor: Colors.deepPurple,
                      icon: Icons.savings_outlined,
                    ),
                    DashboardMetricCard(
                      label: 'Projected Balance',
                      value: _formatCurrency(metrics.projectedEndBalance),
                      caption: 'Month-end forecast',
                      accentColor: Colors.deepPurple,
                      icon: Icons.trending_up,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Prediction',
                  subtitle:
                      'Formula-based outlook using current month spending pace.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        metrics.forecastMessage,
                        style: theme.textTheme.bodyLarge,
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
                              value:
                                  metrics.daysUntilDepleted?.toString() ??
                                  'Safe',
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
                  subtitle:
                      'Local alerts based on budget pace and remaining room.',
                  child: alerts.isEmpty
                      ? const Text(
                          'No active alerts. Spending is within the current budget pace.',
                        )
                      : Column(
                          children: alerts
                              .map(
                                (_DashboardAlert alert) => Padding(
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
                  subtitle:
                      'Current month category totals and share of spending.',
                  child: Column(
                    children: sortedCategories
                        .map(
                          (MapEntry<String, double> entry) => Padding(
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
                          backgroundColor: Colors.deepPurple.shade50,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.deepPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${((metrics.totalSpent / monthlyBudget) * 100).clamp(0, 999).toStringAsFixed(1)}% of monthly budget used',
                        style: theme.textTheme.bodyMedium,
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
          message:
              'Projected month-end spend is RM${metrics.projectedMonthEndSpend.toStringAsFixed(2)}, above the current budget.',
          color: Colors.deepPurple.shade700,
          icon: Icons.warning_amber_rounded,
        ),
      );
    } else if (metrics.riskLevel == SpendingRiskLevel.warning) {
      alerts.add(
        _DashboardAlert(
          title: 'Approaching budget limit',
          message: 'Current pace is close to the monthly budget threshold.',
          color: Colors.deepPurple.shade400,
          icon: Icons.error_outline,
        ),
      );
    }

    if (metrics.remainingBudget <= metrics.monthlyBudget * 0.2) {
      alerts.add(
        _DashboardAlert(
          title: 'Low remaining budget',
          message:
              'Only ${_formatCurrency(metrics.remainingBudget)} remains for the rest of the month.',
          color: Colors.deepPurple,
          icon: Icons.notifications_active_outlined,
        ),
      );
    }

    return alerts;
  }

  static double _normalizedBudgetUsage({
    required double spent,
    required double budget,
  }) {
    if (budget <= 0) {
      return 1;
    }
    return (spent / budget).clamp(0, 1).toDouble();
  }

  static String _formatCurrency(double amount) {
    final String prefix = amount < 0 ? '-RM' : 'RM';
    return '$prefix${amount.abs().toStringAsFixed(2)}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
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
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
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
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
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
        color: alert.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: alert.color.withValues(alpha: 0.25)),
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
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(alert.message),
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
