import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../services/budget_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  // Midnight Gold Palette
  final Color gold = const Color(0xFFFFD700);
  final Color charcoal = const Color(0xFF1E1E1E);
  final Color midnight = const Color(0xFF121212);

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
      'reason': 'I can explain recommendations using your budget and recent expenses.',
      'basedOn': 'Your current budget profile.',
      'source': 'system',
    },
  ];

  @override
  void initState() {
    super.initState();
    remainingBudget = 0;
    recentExpenses = [];
  }

  // LOGIC PRESERVED FROM SOURCE
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // 1. Update UI to show user message and loading state
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

    Map<String, String>? finalAiMessage;

    try {
      // 2. Fetch fresh financial data
      // We get the stream from Firestore and take the first available snapshot
      final expenseSnap = await FirestoreService.getExpenses().first;
      
      // 3. Use BudgetService to calculate current metrics (Remaining Budget, etc.)
      final metrics = BudgetService.buildDashboardMetrics(expenseSnap);

      // 4. Prepare a simplified list of recent expenses for the AI context
      final recentExpensesForAI = metrics.monthExpenses
          .take(5) // Just the top 5 to keep the prompt small and fast
          .map((e) => {
                'title': e.note,
                'amount': e.amount,
                'category': e.category,
              })
          .toList();

      // 5. Call the Unified AI Service
      // This replaces GLMService and talks directly to the ILMU API
      finalAiMessage = await AiService().getChatResponse(
        userQuestion: text,
        remainingBudget: metrics.remainingBudget,
        expenses: recentExpensesForAI,
      );

    } catch (e) {
      debugPrint("Chat Error: $e");
      // Fallback UI message if something goes wrong
      finalAiMessage = {
        'sender': 'ai',
        'answer': 'I encountered a connection issue.',
        'reason': 'The AI service is currently unreachable.',
        'basedOn': 'System Status',
        'source': 'error',
      };
    } finally {
      // 6. Final UI Update
      if (mounted) {
        setState(() {
          // Remove the "Loading..." bubble
          if (_messages.isNotEmpty && _messages.last['source'] == 'loading') {
            _messages.removeLast();
          }
          
          _isLoading = false;
          
          // Add the actual AI response to the chat list
          if (finalAiMessage != null) {
            _messages.add(finalAiMessage!);
          }
        });
      }
    }
  }

  // REFINED CHAT BUBBLE STRUCTURE
  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['sender'] == 'user';
    final isLoading = message['source'] == 'loading';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? gold : charcoal,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          border: !isUser ? Border.all(color: gold.withOpacity(0.2)) : null,
        ),
        child: isUser
            ? Text(
                message['text'] ?? '',
                style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
              )
            : isLoading 
                ? _buildLoadingIndicator(message['text'] ?? '')
                : _buildAiResponseContent(message),
      ),
    );
  }

  Widget _buildLoadingIndicator(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: gold)),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(color: gold.withOpacity(0.8), fontSize: 13, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildAiResponseContent(Map<String, String> message) {
    final answer = message['answer'];
    final reason = message['reason'];
    final basedOn = message['basedOn'];

    if (answer == null) {
      return Text(message['text'] ?? '', style: const TextStyle(color: Colors.white, height: 1.4));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(answer, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const Divider(color: Colors.white10, height: 20),
        Text("WHY", style: TextStyle(color: gold.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 10)),
        Text(reason!, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        const SizedBox(height: 12),
        Text("BASED ON", style: TextStyle(color: gold.withOpacity(0.7), fontWeight: FontWeight.bold, fontSize: 10)),
        Text(basedOn!, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: charcoal,
      labelStyle: TextStyle(color: gold, fontSize: 12),
      side: BorderSide(color: gold.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: _isLoading ? null : () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: midnight,
      appBar: AppBar(
        title: const Text('Spending Assistant'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. INSTRUCTION BOX
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: charcoal.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: const Text(
                'Ask about your overspending, specific RM amounts, or budget reductions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white60),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 2. SUGGESTION ROW
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSuggestionChip('Why am I overspending?'),
                const SizedBox(width: 8),
                _buildSuggestionChip('Can I afford RM20?'),
                const SizedBox(width: 8),
                _buildSuggestionChip('What should I reduce?'),
              ],
            ),
          ),

          // 3. CHAT MESSAGES
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),

          // 4. INPUT AREA
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
              color: charcoal,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: midnight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(16)),
                    child: Icon(Icons.send_rounded, color: Colors.black, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}