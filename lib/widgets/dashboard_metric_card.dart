import 'package:flutter/material.dart';

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
    required this.accentColor,
    required this.icon,
  });

  final String label;
  final String value;
  final String caption;
  final Color accentColor;
  final IconData icon;

  // Theme Constants
  static const Color gold = Color(0xFFFFD700);
  static const Color charcoal = Color(0xFF1E1E1E);
  static const Color midnight = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double width = (MediaQuery.sizeOf(context).width - 44) / 2;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width, maxWidth: width),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: charcoal, // Swapped white for charcoal
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)), // Added subtle border
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000), // Darker shadow for depth
              blurRadius: 16,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: accentColor.withOpacity(0.12), // Dynamic accent (Gold)
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                label, 
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70), // Lightened text
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: gold, // Values in signature gold
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white38, // Subdued captions
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}