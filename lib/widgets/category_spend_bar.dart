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

  // Theme Constants
  static const Color gold = Color(0xFFFFD700);
  static const Color midnight = Color(0xFF121212);

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
                  color: Colors.white, // Updated for dark theme
                ),
              ),
            ),
            Text(
              'RM${amount.toStringAsFixed(2)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: gold, // Highlighted amount in gold
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: ratio,
            backgroundColor: gold.withOpacity(0.1), // Updated background
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${(ratio * 100).toStringAsFixed(1)}% of current month spending',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white54, // Updated for visibility
          ),
        ),
      ],
    );
  }

  static Color _colorForCategory(String category) {
    // Variations of gold/yellow for different categories
    switch (category) {
      case 'Food':
        return gold;
      case 'Transport':
        return const Color(0xFFFFE44D); // Lighter gold
      case 'Shopping':
        return const Color(0xFFD4AF37); // Metallic gold
      case 'Bills':
        return const Color(0xFFFFC107); // Amber gold
      default:
        return gold;
    }
  }
}