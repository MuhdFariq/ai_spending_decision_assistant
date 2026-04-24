import 'package:flutter/material.dart';

class CategorySpendBar extends StatelessWidget {
  const CategorySpendBar({
    super.key,
    required this.category,
    required this.amount,
    required this.totalSpent,
  });

  final String category;
  final double amount;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double ratio = totalSpent <= 0
        ? 0
        : (amount / totalSpent).clamp(0, 1).toDouble();
    final Color accentColor = _colorForCategory(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                category,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              'RM${amount.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: ratio,
            backgroundColor: accentColor.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(ratio * 100).toStringAsFixed(1)}% of current month spending',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
      ],
    );
  }

  static Color _colorForCategory(String category) {
    switch (category) {
      case 'Food':
        return Colors.deepPurple;
      case 'Transport':
        return Colors.deepPurple.shade400;
      case 'Shopping':
        return Colors.deepPurple.shade300;
      case 'Bills':
        return Colors.deepPurple.shade500;
      default:
        return Colors.deepPurple;
    }
  }
}
