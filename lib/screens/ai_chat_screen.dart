import 'package:flutter/material.dart';
import '../services/explainability_service.dart';
import '../services/mock_data_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  late final double remainingBudget;
  late final List<Map<String, dynamic>> recentExpenses;

  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text':
          'Hi! Ask me about your spending, budget, or affordability.',
    },
  ];

  @override
  void initState() {
    super.initState();
    remainingBudget = MockDataService.getRemainingBudget();
    recentExpenses = MockDataService.getRecentExpenses();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});

      String aiResponse;
      final lowerText = text.toLowerCase();

      final foodExpenses = recentExpenses
          .where((expense) => expense['category'] == 'Food')
          .toList();

      final totalRecentSpending = recentExpenses.fold<double>(
        0.0,
        (sum, expense) => sum + (expense['amount'] as double),
      );

      if (lowerText.contains('why') && lowerText.contains('overspend')) {
        aiResponse = ExplainabilityService.formatResponse(
          answer: 'You may be overspending mainly on food and entertainment.',
          reason:
              'You have ${foodExpenses.length} recent food purchases, and entertainment spending is also taking a noticeable share of your recent expenses.',
          basedOn:
              'RM${remainingBudget.toStringAsFixed(2)} remaining budget, RM${totalRecentSpending.toStringAsFixed(2)} recent spending, including items like ${recentExpenses[0]['title']} and ${recentExpenses[3]['title']}.',
        );
      } else if (lowerText.contains('afford')) {
        aiResponse = ExplainabilityService.formatResponse(
          answer: 'You should be careful with this purchase.',
          reason:
              'Your remaining budget is RM${remainingBudget.toStringAsFixed(2)}, so any additional spending reduces flexibility for upcoming needs.',
          basedOn:
              'Current remaining budget and ${recentExpenses.length} recent expenses.',
        );
      } else if (lowerText.contains('reduce') ||
          lowerText.contains('cut down') ||
          lowerText.contains('save')) {
        aiResponse = ExplainabilityService.formatResponse(
          answer: 'You should consider reducing food and entertainment spending first.',
          reason:
              'These categories appear most often in your recent transactions and are the easiest place to cut smaller non-essential expenses.',
          basedOn:
              'Recent categories include Food, Transport, and Entertainment, with Food appearing most frequently.',
        );
      } else if (lowerText.contains('spending')) {
        aiResponse = ExplainabilityService.formatResponse(
          answer: 'Your spending looks active, especially in day-to-day purchases.',
          reason:
              'Smaller repeated purchases can add up quickly even if each one seems manageable.',
          basedOn:
              'Recent expenses such as ${recentExpenses[0]['title']}, ${recentExpenses[1]['title']}, and ${recentExpenses[2]['title']}.',
        );
      } else {
        aiResponse = ExplainabilityService.formatResponse(
          answer:
              'I can help with overspending analysis, affordability checks, and ways to reduce spending.',
          reason:
              'Your budgeting assistant works best when the question is specific.',
          basedOn: 'Current mock budget and recent expense data.',
        );
      }

      _messages.add({
        'sender': 'ai',
        'text': aiResponse,
      });
    });

    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['sender'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUser
                ? Colors.deepPurple.shade200
                : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message['text'] ?? '',
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Assistant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.deepPurple.shade100),
              ),
              child: const Text(
                'Ask questions like "Why am I overspending?", "Can I afford RM20?", or "What should I reduce?"',
                style: TextStyle(fontSize: 15),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestionChip('why am I overspending'),
                _buildSuggestionChip('can I afford RM20'),
                _buildSuggestionChip('what should I reduce'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your spending...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}