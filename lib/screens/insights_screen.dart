import 'package:flutter/material.dart';
import '../services/insight_service.dart';
import '../services/auth_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final InsightService _insightService = InsightService();
  final AuthService _authService = AuthService();

  // Controllers for the "What-If" Simulation
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _patternResult = "Tap 'Refresh' to see your spending patterns.";
  String _simulationResult = "";
  bool _isAnalyzing = false;
  bool _isSimulating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "AI Financial Insights",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("The 'What-If' Lab", Icons.science),
            _buildWhatIfCard(),
            const SizedBox(height: 24),

            _buildSectionHeader("Spending Patterns", Icons.psychology),
            _buildPatternCard(),
            const SizedBox(height: 100), // Space for scrolling
          ],
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
      ],
    );
  }

  Widget _buildWhatIfCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _itemNameController,
              decoration: const InputDecoration(
                labelText: "What do you want to buy?",
                hintText: "e.g. New Shoes",
              ),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Price (RM)",
                hintText: "e.g. 150",
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSimulating ? null : _runSimulation,
              icon: _isSimulating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _isSimulating ? "Simulating..." : "Check Consequence",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
            if (_simulationResult.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                _simulationResult,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatternCard() {
    return Card(
      elevation: 2,
      color: Colors.indigo.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_patternResult, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _isAnalyzing ? null : _fetchPatterns,
              icon: Icon(
                _isAnalyzing ? Icons.hourglass_empty : Icons.refresh,
                color: Colors.teal,
              ),
              label: Text(
                _isAnalyzing ? "Analyzing..." : "Refresh Insights",
                style: const TextStyle(color: Colors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC METHODS ---

  Future<void> _fetchPatterns() async {
    setState(() => _isAnalyzing = true);
    String userId = _authService.currentUserId ?? "";
    String result = await _insightService.getBehaviorInsights(userId);
    setState(() {
      _patternResult = result;
      _isAnalyzing = false;
    });
  }

  Future<void> _runSimulation() async {
    if (_itemNameController.text.isEmpty || _priceController.text.isEmpty)
      return;

    setState(() => _isSimulating = true);

    // For now, using a hardcoded currentBalance of 500.
    // Later, you will get this from Member B's service.
    String result = await _insightService.getScenarioSimulation(
      itemName: _itemNameController.text,
      itemPrice: double.tryParse(_priceController.text) ?? 0.0,
      currentBalance: 500.0,
    );

    setState(() {
      _simulationResult = result;
      _isSimulating = false;
    });
  }
}
