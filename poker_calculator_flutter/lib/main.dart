import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const PokerCalculatorApp());
}

class PokerCalculatorApp extends StatelessWidget {
  const PokerCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poker Calculator',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const PokerCalculatorPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PokerCalculatorPage extends StatefulWidget {
  const PokerCalculatorPage({super.key});

  @override
  State<PokerCalculatorPage> createState() => _PokerCalculatorPageState();
}

class _PokerCalculatorPageState extends State<PokerCalculatorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Get API URL
  // This uses build-time configuration via --dart-define=API_URL=...
  // The deployment script rebuilds the frontend with the correct backend URL
  String get _apiUrl {
    // Get API URL from build-time environment variable
    // Set during Docker build with: --build-arg API_URL=...
    // Which becomes: --dart-define=API_URL=...
    const apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }
    
    // Fallback to localhost for local development
    return 'http://localhost:8080';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Poker Calculator'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Evaluate Hand', icon: Icon(Icons.assessment)),
            Tab(text: 'Compare Hands', icon: Icon(Icons.compare_arrows)),
            Tab(text: 'Probability', icon: Icon(Icons.calculate)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          EvaluateHandTab(apiUrl: _apiUrl),
          CompareHandsTab(apiUrl: _apiUrl),
          ProbabilityTab(apiUrl: _apiUrl),
        ],
      ),
    );
  }
}

// Evaluate Hand Tab
class EvaluateHandTab extends StatefulWidget {
  final String apiUrl;
  const EvaluateHandTab({super.key, required this.apiUrl});

  @override
  State<EvaluateHandTab> createState() => _EvaluateHandTabState();
}

class _EvaluateHandTabState extends State<EvaluateHandTab> {
  final TextEditingController _holeCard1Controller = TextEditingController();
  final TextEditingController _holeCard2Controller = TextEditingController();
  final TextEditingController _communityCard1Controller = TextEditingController();
  final TextEditingController _communityCard2Controller = TextEditingController();
  final TextEditingController _communityCard3Controller = TextEditingController();
  final TextEditingController _communityCard4Controller = TextEditingController();
  final TextEditingController _communityCard5Controller = TextEditingController();

  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _evaluateHand() async {
    setState(() {
      _error = null;
      _isLoading = true;
      _result = null;
    });

    try {
      final holeCards = [
        _holeCard1Controller.text.trim().toUpperCase(),
        _holeCard2Controller.text.trim().toUpperCase(),
      ];

      final communityCards = [
        _communityCard1Controller.text.trim().toUpperCase(),
        _communityCard2Controller.text.trim().toUpperCase(),
        _communityCard3Controller.text.trim().toUpperCase(),
        _communityCard4Controller.text.trim().toUpperCase(),
        _communityCard5Controller.text.trim().toUpperCase(),
      ];

      // Validate inputs
      if (holeCards.any((card) => card.isEmpty) ||
          communityCards.any((card) => card.isEmpty)) {
        setState(() {
          _error = 'Please fill in all card fields';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('${widget.apiUrl}/poker/evaluate-hand');
      final body = jsonEncode({
        'hole_cards': holeCards,
        'community_cards': communityCards,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = data;
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to evaluate hand');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _holeCard1Controller.dispose();
    _holeCard2Controller.dispose();
    _communityCard1Controller.dispose();
    _communityCard2Controller.dispose();
    _communityCard3Controller.dispose();
    _communityCard4Controller.dispose();
    _communityCard5Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter 2 hole cards and 5 community cards',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Card format: HA (Heart-Ace), S7 (Spade-7), CT (Club-Ten), etc.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('Hole Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _holeCard1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 1 (e.g., HA)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _holeCard2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 2 (e.g., S7)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Community Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 1',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 2',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard3Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 3',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard4Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 4',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard5Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 5',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _evaluateHand,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Evaluate Hand'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Hand: ${_result!['best_hand']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Hand Value: ${_result!['hand_value']}'),
                    const SizedBox(height: 8),
                    Text('Best 5 Cards: ${(_result!['best_five_cards'] as List).join(', ')}'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Compare Hands Tab
class CompareHandsTab extends StatefulWidget {
  final String apiUrl;
  const CompareHandsTab({super.key, required this.apiUrl});

  @override
  State<CompareHandsTab> createState() => _CompareHandsTabState();
}

class _CompareHandsTabState extends State<CompareHandsTab> {
  final TextEditingController _p1Card1Controller = TextEditingController();
  final TextEditingController _p1Card2Controller = TextEditingController();
  final TextEditingController _p2Card1Controller = TextEditingController();
  final TextEditingController _p2Card2Controller = TextEditingController();
  final TextEditingController _communityCard1Controller = TextEditingController();
  final TextEditingController _communityCard2Controller = TextEditingController();
  final TextEditingController _communityCard3Controller = TextEditingController();
  final TextEditingController _communityCard4Controller = TextEditingController();
  final TextEditingController _communityCard5Controller = TextEditingController();

  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _compareHands() async {
    setState(() {
      _error = null;
      _isLoading = true;
      _result = null;
    });

    try {
      final p1HoleCards = [
        _p1Card1Controller.text.trim().toUpperCase(),
        _p1Card2Controller.text.trim().toUpperCase(),
      ];

      final p2HoleCards = [
        _p2Card1Controller.text.trim().toUpperCase(),
        _p2Card2Controller.text.trim().toUpperCase(),
      ];

      final communityCards = [
        _communityCard1Controller.text.trim().toUpperCase(),
        _communityCard2Controller.text.trim().toUpperCase(),
        _communityCard3Controller.text.trim().toUpperCase(),
        _communityCard4Controller.text.trim().toUpperCase(),
        _communityCard5Controller.text.trim().toUpperCase(),
      ];

      // Validate inputs
      if (p1HoleCards.any((card) => card.isEmpty) ||
          p2HoleCards.any((card) => card.isEmpty) ||
          communityCards.any((card) => card.isEmpty)) {
        setState(() {
          _error = 'Please fill in all card fields';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('${widget.apiUrl}/poker/compare-hands');
      final body = jsonEncode({
        'player1_hole_cards': p1HoleCards,
        'player1_community_cards': communityCards,
        'player2_hole_cards': p2HoleCards,
        'player2_community_cards': communityCards,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = data;
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to compare hands');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _p1Card1Controller.dispose();
    _p1Card2Controller.dispose();
    _p2Card1Controller.dispose();
    _p2Card2Controller.dispose();
    _communityCard1Controller.dispose();
    _communityCard2Controller.dispose();
    _communityCard3Controller.dispose();
    _communityCard4Controller.dispose();
    _communityCard5Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Compare two hands with shared community cards',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Player 1 Hole Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _p1Card1Controller,
                          decoration: const InputDecoration(
                            labelText: 'Card 1',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _p1Card2Controller,
                          decoration: const InputDecoration(
                            labelText: 'Card 2',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Player 2 Hole Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _p2Card1Controller,
                          decoration: const InputDecoration(
                            labelText: 'Card 1',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _p2Card2Controller,
                          decoration: const InputDecoration(
                            labelText: 'Card 2',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Community Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 1',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 2',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard3Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 3',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard4Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 4',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _communityCard5Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 5',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _compareHands,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Compare Hands'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Results:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Player 1:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Hand: ${_result!['player1_hand']['best_hand']}'),
                            Text('Value: ${_result!['player1_hand']['hand_value']}'),
                            Text('Cards: ${(_result!['player1_hand']['best_five_cards'] as List).join(', ')}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Player 2:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Hand: ${_result!['player2_hand']['best_hand']}'),
                            Text('Value: ${_result!['player2_hand']['hand_value']}'),
                            Text('Cards: ${(_result!['player2_hand']['best_five_cards'] as List).join(', ')}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _result!['winner'] == 0
                            ? Colors.grey.shade300
                            : (_result!['winner'] == 1 ? Colors.blue.shade200 : Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _result!['winner'] == 0
                            ? 'Tie!'
                            : 'Winner: Player ${_result!['winner']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Probability Tab
class ProbabilityTab extends StatefulWidget {
  final String apiUrl;
  const ProbabilityTab({super.key, required this.apiUrl});

  @override
  State<ProbabilityTab> createState() => _ProbabilityTabState();
}

class _ProbabilityTabState extends State<ProbabilityTab> {
  final TextEditingController _holeCard1Controller = TextEditingController();
  final TextEditingController _holeCard2Controller = TextEditingController();
  final TextEditingController _communityCard1Controller = TextEditingController();
  final TextEditingController _communityCard2Controller = TextEditingController();
  final TextEditingController _communityCard3Controller = TextEditingController();
  final TextEditingController _communityCard4Controller = TextEditingController();
  final TextEditingController _communityCard5Controller = TextEditingController();
  final TextEditingController _numPlayersController = TextEditingController(text: '2');
  final TextEditingController _numSimulationsController = TextEditingController(text: '10000');

  int _communityCardsCount = 0;
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _error;

  Future<void> _calculateProbability() async {
    setState(() {
      _error = null;
      _isLoading = true;
      _result = null;
    });

    try {
      final holeCards = [
        _holeCard1Controller.text.trim().toUpperCase(),
        _holeCard2Controller.text.trim().toUpperCase(),
      ];

      if (holeCards.any((card) => card.isEmpty)) {
        setState(() {
          _error = 'Please enter both hole cards';
          _isLoading = false;
        });
        return;
      }

      final communityCards = <String>[];
      final controllers = [
        _communityCard1Controller,
        _communityCard2Controller,
        _communityCard3Controller,
        _communityCard4Controller,
        _communityCard5Controller,
      ];

      for (int i = 0; i < _communityCardsCount; i++) {
        final card = controllers[i].text.trim().toUpperCase();
        if (card.isEmpty) {
          setState(() {
            _error = 'Please fill in all community card fields';
            _isLoading = false;
          });
          return;
        }
        communityCards.add(card);
      }

      final numPlayers = int.tryParse(_numPlayersController.text);
      if (numPlayers == null || numPlayers < 2) {
        setState(() {
          _error = 'Number of players must be at least 2';
          _isLoading = false;
        });
        return;
      }

      final numSimulations = int.tryParse(_numSimulationsController.text);
      if (numSimulations == null || numSimulations < 1) {
        setState(() {
          _error = 'Number of simulations must be at least 1';
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('${widget.apiUrl}/poker/calculate-probability');
      final body = jsonEncode({
        'hole_cards': holeCards,
        'community_cards': communityCards,
        'num_players': numPlayers,
        'num_simulations': numSimulations,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _result = data;
        });
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to calculate probability');
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _holeCard1Controller.dispose();
    _holeCard2Controller.dispose();
    _communityCard1Controller.dispose();
    _communityCard2Controller.dispose();
    _communityCard3Controller.dispose();
    _communityCard4Controller.dispose();
    _communityCard5Controller.dispose();
    _numPlayersController.dispose();
    _numSimulationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Calculate win probability using Monte Carlo simulation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Hole Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _holeCard1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 1',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _holeCard2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Card 2',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Number of Community Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('0 (Pre-flop)')),
              ButtonSegment(value: 3, label: Text('3 (Flop)')),
              ButtonSegment(value: 4, label: Text('4 (Turn)')),
              ButtonSegment(value: 5, label: Text('5 (River)')),
            ],
            selected: {_communityCardsCount},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _communityCardsCount = newSelection.first;
              });
            },
          ),
          if (_communityCardsCount > 0) ...[
            const SizedBox(height: 16),
            const Text('Community Cards:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                _communityCardsCount,
                (index) => SizedBox(
                  width: 100,
                  child: TextField(
                    controller: [
                      _communityCard1Controller,
                      _communityCard2Controller,
                      _communityCard3Controller,
                      _communityCard4Controller,
                      _communityCard5Controller,
                    ][index],
                    decoration: InputDecoration(
                      labelText: 'Card ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _numPlayersController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Players',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _numSimulationsController,
                  decoration: const InputDecoration(
                    labelText: 'Simulations',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _calculateProbability,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Calculate Probability'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Results:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Win Probability: ${(_result!['win_probability'] * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tie Probability: ${(_result!['tie_probability'] * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _result!['win_probability'],
                      minHeight: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}







