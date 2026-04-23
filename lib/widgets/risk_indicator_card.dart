import 'package:flutter/material.dart';

import '../services/budget_service.dart';

class RiskIndicatorCard extends StatelessWidget {
  const RiskIndicatorCard({super.key, required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final _RiskCardStyle style = _styleFor(metrics.riskLevel);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: style.baseColor.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.deepPurple.shade50,
              child: Icon(style.icon, color: style.baseColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${style.label} ${BudgetService.getRiskLabel(metrics.riskLevel)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: style.baseColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _messageFor(metrics),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _messageFor(DashboardMetrics metrics) {
    switch (metrics.riskLevel) {
      case SpendingRiskLevel.safe:
        return 'Your current spending pace stays well under the monthly limit.';
      case SpendingRiskLevel.warning:
        return 'You are slightly above the safe daily pace. Keep the next few days tight.';
      case SpendingRiskLevel.overspending:
        return 'At the current rate, your budget is likely to run out before month end.';
    }
  }

  static _RiskCardStyle _styleFor(SpendingRiskLevel riskLevel) {
    switch (riskLevel) {
      case SpendingRiskLevel.safe:
        return const _RiskCardStyle(
          label: 'Status:',
          baseColor: Colors.deepPurple,
          icon: Icons.verified_outlined,
        );
      case SpendingRiskLevel.warning:
        return const _RiskCardStyle(
          label: 'Status:',
          baseColor: Color(0xFF7E57C2),
          icon: Icons.warning_amber_rounded,
        );
      case SpendingRiskLevel.overspending:
        return const _RiskCardStyle(
          label: 'Status:',
          baseColor: Color(0xFF5E35B1),
          icon: Icons.error_outline,
        );
    }
  }
}

class _RiskCardStyle {
  const _RiskCardStyle({
    required this.label,
    required this.baseColor,
    required this.icon,
  });

  final String label;
  final Color baseColor;
  final IconData icon;
}
