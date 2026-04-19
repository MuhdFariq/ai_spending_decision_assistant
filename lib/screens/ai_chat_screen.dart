import 'package:flutter/material.dart';

import '../services/glm_service.dart';
import '../services/insight_service.dart';
import '../services/mock_data_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  late final double remainingBudget;
  late final List<Map<String, dynamic>> recentExpenses;

  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text': 'Hi! Ask me about your spending, budget, or affordability.',
    },
  ];

  @override
  void initState() {
    super.initState();
    remainingBudget = MockDataService.getRemainingBudget();
    recentExpenses = MockDataService.getRecentExpenses();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _messageController.clear();
      _isLoading = true;

      // show temporary "thinking" message while waiting for response
      _messages.add({
        'sender': 'ai',
        'text': 'Analyzing your budget...',
      });
    });

    final prompt = GLMService.buildPrompt(
      userQuestion: text,
      remainingBudget: remainingBudget,
      expenses: recentExpenses,
    );

    debugPrint('GLM PROMPT:\n$prompt');

    // try GLM first (only works when API is configured)
    final canUseGLM = GLMService.isConfigured();

    final glmResponse = canUseGLM
        ? await GLMService.getAIResponse(
            userQuestion: text,
            remainingBudget: remainingBudget,
            expenses: recentExpenses,
          )
        : null;

    // fallback to local rule-based logic if GLM is unavailable
    final aiResponse = glmResponse ??
        InsightService.generateFallbackResponse(
          text: text,
          remainingBudget: remainingBudget,
          recentExpenses: recentExpenses,
        );

    setState(() {
      _isLoading = false;

      // remove the temporary loading message before showing actual response
      _messages.removeLast();
      _messages.add({
        'sender': 'ai',
        'text': aiResponse,
      });
    });
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
                  onPressed: _isLoading ? null : _sendMessage,
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