import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/colors.dart';
import 'restaurant_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const _historyKey = 'recent_searches';
  static const _maxHistory = 8;
  List<String> _recentSearches = [];

  final List<String> _popularSearches = [
    'Pizza',
    'Burger',
    'Biryani',
    'North Indian',
    'Fast Food',
  ];

  // Voice search
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  final List<Map<String, dynamic>> _allItems = [
    {'name': 'Burger Palace', 'type': 'Restaurant', 'emoji': '🍔', 'color': Color(0xFFFFE0B2),
      'cuisine': 'Burgers • Fast Food', 'rating': '4.5', 'time': '25-30 min', 'price': '₹200 for two',
      'tag': 'BESTSELLER', 'discount': '20% OFF',
      'items': [
        {'name': 'Classic Burger', 'price': 120, 'emoji': '🍔', 'desc': 'Juicy beef patty'},
        {'name': 'French Fries', 'price': 80, 'emoji': '🍟', 'desc': 'Crispy golden fries'},
      ]},
    {'name': 'Pizza House', 'type': 'Restaurant', 'emoji': '🍕', 'color': Color(0xFFFFCDD2),
      'cuisine': 'Pizza • Italian', 'rating': '4.3', 'time': '30-35 min', 'price': '₹350 for two',
      'tag': 'NEW', 'discount': 'Free Delivery',
      'items': [
        {'name': 'Margherita Pizza', 'price': 250, 'emoji': '🍕', 'desc': 'Classic tomato cheese'},
        {'name': 'Garlic Bread', 'price': 90, 'emoji': '🥖', 'desc': 'Toasted garlic bread'},
      ]},
    {'name': 'Biryani Bros', 'type': 'Restaurant', 'emoji': '🍛', 'color': Color(0xFFC8E6C9),
      'cuisine': 'Biryani • North Indian', 'rating': '4.7', 'time': '40-45 min', 'price': '₹450 for two',
      'tag': 'TOP RATED', 'discount': '₹100 OFF',
      'items': [
        {'name': 'Chicken Biryani', 'price': 220, 'emoji': '🍛', 'desc': 'Aromatic basmati rice'},
        {'name': 'Seekh Kebab', 'price': 160, 'emoji': '🍢', 'desc': 'Spicy minced meat'},
      ]},
  ];

  List<Map<String, dynamic>> get _filtered => _query.isEmpty
      ? _allItems
      : _allItems
          .where((item) =>
              item['name'].toLowerCase().contains(_query.toLowerCase()) ||
              item['cuisine'].toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _initSpeech();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice search error: ${error.errorMsg}')),
        );
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Voice search not available on this device/browser')),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
          _searchController.selection = TextSelection.fromPosition(
              TextPosition(offset: _searchController.text.length));
          _query = result.recognizedWords;
        });
        if (result.finalResult) {
          setState(() => _isListening = false);
          _addToHistory(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_historyKey) ?? [];
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _recentSearches);
  }

  void _addToHistory(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.removeWhere((s) => s.toLowerCase() == trimmed.toLowerCase());
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > _maxHistory) {
        _recentSearches = _recentSearches.sublist(0, _maxHistory);
      }
    });
    _saveHistory();
  }

  void _removeFromHistory(String term) {
    setState(() => _recentSearches.remove(term));
    _saveHistory();
  }

  void _clearHistory() {
    setState(() => _recentSearches.clear());
    _saveHistory();
  }

  void _runSearch(String term) {
    _searchController.text = term;
    _searchController.selection =
        TextSelection.fromPosition(TextPosition(offset: term.length));
    setState(() => _query = term);
    _addToHistory(term);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (v) => _addToHistory(v),
              decoration: InputDecoration(
                hintText: _isListening ? 'Listening...' : 'Search restaurants, food...',
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : AppColors.primary,
                      ),
                      onPressed: _toggleListening,
                      tooltip: 'Voice search',
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isListening)
            Container(
              width: double.infinity,
              color: AppColors.primary.withOpacity(0.08),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.graphic_eq, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Listening... speak now',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ],
              ),
            ),
          Expanded(
            child: _query.isEmpty
                ? _buildSuggestions()
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('😕', style: TextStyle(fontSize: 60)),
                            const SizedBox(height: 16),
                            Text('No results found',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark)),
                            Text('Try a different search',
                                style: TextStyle(color: AppColors.textGrey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          return GestureDetector(
                            onTap: () {
                              _addToHistory(item['name']);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RestaurantDetailScreen(restaurant: item),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.shadow,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: item['color'],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(item['emoji'],
                                          style: const TextStyle(fontSize: 30)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item['name'],
                                            style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textDark)),
                                        Text(item['cuisine'],
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textGrey)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.star,
                                                color: AppColors.success,
                                                size: 14),
                                            Text(
                                                ' ${item['rating']}  •  ${item['time']}',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textGrey)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 14, color: AppColors.textGrey),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Searches',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              TextButton(
                onPressed: _clearHistory,
                child: Text('Clear All',
                    style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches
                .map((term) => _buildHistoryChip(term))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        Text('Popular Searches',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularSearches
              .map((term) => GestureDetector(
                    onTap: () => _runSearch(term),
                    child: Chip(
                      label: Text(term),
                      backgroundColor: AppColors.primary.withOpacity(0.08),
                      labelStyle: TextStyle(color: AppColors.primary),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildHistoryChip(String term) {
    return GestureDetector(
      onTap: () => _runSearch(term),
      child: Chip(
        avatar: Icon(Icons.history, size: 16, color: AppColors.textGrey),
        label: Text(term),
        backgroundColor: AppColors.white,
        side: BorderSide(color: AppColors.divider),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => _removeFromHistory(term),
      ),
    );
  }
}
