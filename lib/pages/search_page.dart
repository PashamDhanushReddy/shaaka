import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/product.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import 'search_results_page.dart';
import 'product_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<String> _recentSearches = [];
  List<Product> _trendingProducts = [];
  bool _isLoadingTrending = true;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    _loadRecentSearches();
    _loadTrendingProducts();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (_isListening) {
              setState(() => _isListening = false);
              if (_searchController.text.isNotEmpty) {
                 _performSearch(_searchController.text);
              }
            }
          }
        },
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          pauseFor: const Duration(seconds: 2),
          onResult: (val) {
            setState(() {
              _searchController.text = val.recognizedWords;
            });
            if (val.finalResult && _searchController.text.isNotEmpty) {
              setState(() => _isListening = false);
              _performSearch(_searchController.text);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    }
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList('recent_searches') ?? [];
    
    searches.remove(query);
    searches.insert(0, query);
    if (searches.length > 10) {
      searches = searches.sublist(0, 10);
    }
    
    await prefs.setStringList('recent_searches', searches);
    _loadRecentSearches();
  }

  Future<void> _loadTrendingProducts() async {
    final result = await ApiService.getProducts(ordering: '-rating_count', limit: 6);
    if (mounted) {
      setState(() {
        _isLoadingTrending = false;
        if (result['success'] == true) {
          _trendingProducts = result['data'];
        }
      });
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    _saveSearch(query);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(query: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search for products...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, 
                      color: _isListening ? Colors.red : Colors.grey),
                    onPressed: _listen,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      if (_isListening) {
                        _speech.stop();
                        setState(() => _isListening = false);
                      }
                    },
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _performSearch,
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_recentSearches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: const Text('Recent Searches',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: _recentSearches.map((search) {
                          return GestureDetector(
                            onTap: () => _performSearch(search),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[200],
                                  child: const Icon(Icons.history, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    search,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(thickness: 0.5),
                ],

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text('Trending Products',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (_isLoadingTrending)
                     const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (_trendingProducts.isEmpty)
                     const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("No trending products yet."))
                else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          childAspectRatio: 3.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                      ),
                      itemCount: _trendingProducts.length,
                      itemBuilder: (context, index) {
                          final product = _trendingProducts[index];
                          return GestureDetector(
                          onTap: () {
                               Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => ProductDetailsPage(product: product))
                              );
                          },
                          child: Container(
                              decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Row(
                              children: [
                                  Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.grey[200],
                                  child: product.firstImageUrl != null 
                                      ? Image.network(product.firstImageUrl!, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 20))
                                      : const Icon(Icons.trending_up, size: 20, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                  child: Text(
                                      product.name,
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                  ),
                                  ),
                              ],
                              ),
                          ),
                          );
                      },
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
