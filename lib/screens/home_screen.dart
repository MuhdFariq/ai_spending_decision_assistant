import 'package:flutter/material.dart';

import 'affordability_checker_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Theme Constants
  static const Color gold = Color(0xFFFFD700);
  static const Color charcoal = Color(0xFF1E1E1E);
  static const Color midnight = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: midnight, // Applied Midnight background
      appBar: AppBar(
        title: const Text('AI Spending Assistant', style: TextStyle(color: gold)),
        backgroundColor: charcoal,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Welcome 👋',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Applied white for readability
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Make smarter financial decisions using AI insights.',
              style: TextStyle(
                fontSize: 16, 
                color: Colors.white70, // Applied subtle white
              ),
            ),
            const SizedBox(height: 30),
            _buildFeatureCard(
              context,
              title: 'AI Chat Assistant',
              description: 'Ask questions about your spending and get insights.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AiChatScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              context,
              title: 'Can I Afford This?',
              description: 'Check if a purchase fits your current budget.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AffordabilityCheckerScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: charcoal, // Applied Charcoal card background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gold.withOpacity(0.3)), // Applied Gold border
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: gold, // Applied Gold for feature titles
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70, // Applied subtle text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}