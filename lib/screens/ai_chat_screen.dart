import 'package:flutter/material.dart';

import '../services/explainability_service.dart';
import '../services/glm_service.dart';
import '../services/insight_service.dart';
import '../services/mock_data_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {

  final List<String> _loadingMessages = [
  'Reviewing your recent spending...',
  'Checking your budget impact...',
  'Preparing your explanation...',
  ];
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  late final double remainingBudget;
  late final List<Map<String, dynamic>> recentExpenses;

  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'answer': 'Hi! Ask me about your spending, budget, or affordability.',
      'reason':
          'I can explain recommendations using your budget and recent expenses.',
      'basedOn': 'Your current mock budget profile.',
      'source': 'system',
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

      _messages.add({
        'sender': 'ai',
        'text': _loadingMessages[0],
        'source': 'loading',
      });
    });

    Map<String, String>? finalMessage;

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final glmResponse = await GLMService.getStructuredResponse(
        userQuestion: text,
        remainingBudget: remainingBudget,
        expenses: recentExpenses,
        featureType: 'chat',
      );

      if (glmResponse == null) {
        throw Exception('GLM response was null');
      }

      print('GLM RESPONSE RECEIVED: ${glmResponse.source} | ${glmResponse.answer}');

      finalMessage = {
        'sender': 'ai',
        'answer': glmResponse.answer,
        'reason': glmResponse.reason,
        'basedOn': glmResponse.basedOn,
        'source': glmResponse.source,
      };
    } catch (e) {
      print('GLM FAILED IN FLUTTER: $e');
      final fallbackResponse = InsightService.generateFallbackResponse(
        text: text,
        remainingBudget: remainingBudget,
        recentExpenses: recentExpenses,
      );

      final fallbackSections =
          ExplainabilityService.parseResponseSections(fallbackResponse);

      finalMessage = {
        'sender': 'ai',
        'answer':
            fallbackSections?['answer'] ??
            'I can help with spending and affordability guidance.',
        'reason': fallbackSections?['reason'] ?? 'Local fallback logic was used.',
        'basedOn':
            fallbackSections?['basedOn'] ??
            'Current mock budget and recent expense data.',
        'source': 'glm_failed',
      };
    } finally {
      if (!mounted) return;

      setState(() {
        if (_messages.isNotEmpty && _messages.last['source'] == 'loading') {
        _messages.removeLast();
      }

        _isLoading = false;

        if (finalMessage != null) {
          _messages.add(finalMessage!);
          print("FINAL MESSAGE: $finalMessage");
        }
      });
    }
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
        child: isUser
            ? Text(
                message['text'] ?? '',
                style: const TextStyle(fontSize: 16, height: 1.4),
              )
            : _buildAiResponseContent(message),
      ),
    );
  }

  Widget _buildAiResponseContent(Map<String, String> message) {
    final answer = message['answer'];
    final reason = message['reason'];
    final basedOn = message['basedOn'];
    final text = message['text'];
    final source = message['source'];

    if (answer == null || reason == null || basedOn == null) {
      return Text(
        text ?? '',
        style: const TextStyle(fontSize: 16, height: 1.4),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          answer,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Reason: ${reason.length > 180 ? '${reason.substring(0, 180)}...' : reason}',
          style: const TextStyle(fontSize: 15),
        ),
        const SizedBox(height: 8),
        Text('Based on: $basedOn', style: const TextStyle(fontSize: 15)),
        if (source != null && source.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            source == 'glm'
                ? 'AI response'
                : source == 'glm_failed'
                    ? 'AI fallback response'
                    : 'System response',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: _isLoading
          ? null
          : () {
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