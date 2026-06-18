import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../theme/app_theme.dart';
import 'product_details_page.dart';
import 'cart_page.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  
  String _sortBy = 'Relevance';
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  bool? _inStockOnly;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

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
  
  final List<String> _categories = [
    'Fruits',
    'Vegetables',
    'Dairy',
    'Grains',
    'Spices',
    'Veg starters',
    'Non Veg starters',
    'Biryani',
    'Pulao',
    'Veg thali',
    'Non veg Thali',
    'Sweets',
    'Snacks',
    'Dry fruits',
    'Tiffins',
    'Drinks',
    'Desserts',
    'Others'
  ];
  
  final List<String> _sortOptions = [
    'Relevance',
    'Price: Low to High',
    'Price: High to Low',
    'Rating: High to Low',
    'Newest First'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _filteredProducts = [];
    _performSearch(widget.query);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiService.getProducts(query: query);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _products = result['data'];
          _applyFiltersAndSort();
        } else {
          _error = result['error'] is Map
              ? (result['error']['error'] ?? 'Failed to load results')
              : result['error'].toString();
        }
      });
    }
  }
  
  void _applyFiltersAndSort() {
    List<Product> filtered = List.from(_products);
    
    if (_selectedCategory != null) {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }
    
    if (_inStockOnly == true) {
      filtered = filtered.where((p) => p.stockQuantity > 0).toList();
    }
    
    if (_minPrice != null) {
      filtered = filtered.where((p) => p.price >= _minPrice!).toList();
    }
    if (_maxPrice != null) {
      filtered = filtered.where((p) => p.price <= _maxPrice!).toList();
    }
    
    switch (_sortBy) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating: High to Low':
        filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'Newest First':
        filtered.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        break;
      default:
        break;
    }
    
    setState(() {
      _filteredProducts = filtered;
    });
  }
  
  void _showFilterDialog() {
    double? tempMinPrice = _minPrice;
    double? tempMaxPrice = _maxPrice;
    String? tempCategory = _selectedCategory;
    bool? tempInStock = _inStockOnly;
    
    final minPriceController = TextEditingController(
      text: tempMinPrice?.toStringAsFixed(0) ?? '',
    );
    final maxPriceController = TextEditingController(
      text: tempMaxPrice?.toStringAsFixed(0) ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: tempCategory,
                    decoration: const InputDecoration(
                      hintText: 'All Categories',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._categories.map((cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tempCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    'Price Range (₹)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minPriceController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Min',
                            hintText: '0',
                          ),
                          onChanged: (value) {
                            if (value.trim().isEmpty) {
                              tempMinPrice = null;
                            } else {
                              tempMinPrice = double.tryParse(value);
                            }
                          },
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: maxPriceController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Max',
                            hintText: '10000',
                          ),
                          onChanged: (value) {
                            if (value.trim().isEmpty) {
                              tempMaxPrice = null;
                            } else {
                              tempMaxPrice = double.tryParse(value);
                            }
                          },
                          onSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  SwitchListTile(
                    title: const Text('In Stock Only'),
                    value: tempInStock ?? false,
                    onChanged: (value) {
                      setDialogState(() {
                        tempInStock = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            tempCategory = null;
                            tempMinPrice = null;
                            tempMaxPrice = null;
                            tempInStock = false;
                            minPriceController.clear();
                            maxPriceController.clear();
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = tempCategory;
                            _minPrice = tempMinPrice;
                            _maxPrice = tempMaxPrice;
                            _inStockOnly = tempInStock;
                          });
                          _applyFiltersAndSort();
                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort By',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._sortOptions.map((option) => RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _sortBy,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                    });
                    _applyFiltersAndSort();
                    Navigator.pop(context);
                  }
                },
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  void _onSearchSubmitted(String value) {
      if (value.trim().isNotEmpty) {
          _performSearch(value);
      }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _selectedCategory != null ||
        _minPrice != null ||
        _maxPrice != null ||
        _inStockOnly == true;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for products...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, 
                        color: _isListening ? Colors.red : Colors.grey),
                      onPressed: _listen,
                   ),
                   if (_searchController.text.isNotEmpty)
                    IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                          if (_isListening) {
                            _speech.stop();
                            setState(() => _isListening = false);
                          }
                        },
                      )
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _onSearchSubmitted,
          ),
        ),
        actions: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showSortDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, // slightly reduced padding
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sort_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _sortBy,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showFilterDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, // slightly reduced padding
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: hasActiveFilters
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                              : Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasActiveFilters
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: hasActiveFilters ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: hasActiveFilters
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).textTheme.bodyMedium!.color!,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter',
                              style: TextStyle(
                                color: hasActiveFilters
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).textTheme.bodyMedium!.color!,
                                fontWeight: hasActiveFilters
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (hasActiveFilters) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.search_off_outlined,
                                      size: 48,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No products found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your filters or search query',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                      color: Theme.of(context).textTheme.bodyMedium!.color!,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final screenWidth = constraints.maxWidth;
                              final isSmallScreen = screenWidth < 360;
                              final isVerySmallScreen = screenWidth < 320;
                              double aspectRatio;
                              if (isVerySmallScreen) {
                                aspectRatio = 0.58; // More height for very small screens
                              } else if (isSmallScreen) {
                                aspectRatio = 0.64; // More height for small screens
                              } else {
                                aspectRatio = 0.68; // More height for normal screens
                              }
                              
                              return GridView.builder(
                                padding: const EdgeInsets.all(16),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: aspectRatio,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 200 + (index * 50),
                                ),
                                curve: AppAnimations.defaultCurve,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.scale(
                                      scale: 0.95 + (value * 0.05),
                                      child: child,
                                    ),
                                  );
                                },
                                child: ProductCard(
                                  product: _filteredProducts[index],
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailsPage(
                                          product: _filteredProducts[index],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
