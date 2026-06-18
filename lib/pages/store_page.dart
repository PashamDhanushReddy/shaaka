import 'dart:async';

import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'product_details_page.dart';
import 'add_product_page.dart';
import 'search_page.dart';
import 'category_products_page.dart';
import '../models/auto_scroll_image.dart';
import '../widgets/shimmer_widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../utils/responsive.dart';

class StorePage extends StatefulWidget {
  final bool isVendorView;
  final int? vendorId;

  const StorePage({
    super.key,
    this.isVendorView = false,
    this.vendorId,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  Map<String, List<Product>> _categorizedProducts = {};
    String? _selectedCategory;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (_isListening) {
              setState(() => _isListening = false);
              _filterProducts(_searchController.text);
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
              _filterProducts(val.recognizedWords);
            });
            if (val.finalResult) {
              setState(() => _isListening = false);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _filterProducts(_searchController.text);
    }
  }

  final Map<String, String> _categoryEmojis = {
    'Vegetables': '🥦',
    'Fruits': '🍎',
    'Dairy': '🥛',
    'Bakery': '🍞',
    'Meat': '🥩',
    'Spices': '🌶️',
    'Grains': '🌾',
    'Beverages': '🥤',
    'Snacks': '🍿',
    'Others': '🛍️',
  };

  String _getCategoryEmoji(String category) {
    return _categoryEmojis[category] ?? '📦';
  }

  final PageController _carouselController = PageController();
  final PageController _bannerPageController = PageController(); // Auto-scroll full width for banner

  int _currentCarouselIndex = 0;
  int _currentBannerIndex = 0; // Added for banner indicators
  Timer? _carouselTimer;
  Timer? _bannerTimer; // Added for banner auto-scroll
  
  List<AutoScrollImage> _topBanners = [];
  List<AutoScrollImage> _bottomBanners = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (widget.isVendorView) {
      await _loadProducts(); // Vendors don't need banners
    } else {
      await Future.wait([
        _loadProducts(),
        _loadBanners(),
      ]);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBanners() async {
    final result = await ApiService.getAutoScrollImages();
    print("AutoScroll Api Result: $result");
    if (mounted && result['success'] == true) {
      final List<dynamic> rawData = result['data'];
      final List<AutoScrollImage> allBanners = [];
      for (var item in rawData) {
        if (item is Map<String, dynamic>) {
          allBanners.add(AutoScrollImage.fromJson(item));
        }
      }
      print("Parsed banners count: ${allBanners.length}");
      setState(() {
        _topBanners = allBanners.where((b) => b.placement == 'top').toList();
        _bottomBanners = allBanners.where((b) => b.placement == 'bottom').toList();
      });
      print("Top Banners: ${_topBanners.length}, Bottom: ${_bottomBanners.length}");
      _startAutoScroll();
      _startBannerAutoScroll();
    } else {
        print("Failed to load banners or widget unmounted.");
    }
  }

  void _startAutoScroll() {
    _carouselTimer?.cancel();
    if (_topBanners.isEmpty) return;
    
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_carouselController.hasClients && _topBanners.isNotEmpty) {
        int nextPage = _currentCarouselIndex + 1;
        if (nextPage >= _topBanners.length) {
          nextPage = 0;
        }
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    if (_bottomBanners.isEmpty) return;

    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_bannerPageController.hasClients && _bottomBanners.isNotEmpty) {
        int nextPage = (_bannerPageController.page?.round() ?? 0) + 1;
        if (nextPage >= _bottomBanners.length) {
          nextPage = 0;
        }
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _carouselTimer?.cancel();
    _bannerTimer?.cancel(); // Cancel banner timer
    _carouselController.dispose();
    _bannerPageController.dispose(); // Dispose banner controller
    super.dispose();
  }

  Future<void> _loadProducts() async {
    Map<String, dynamic> result;
    if (widget.isVendorView) {
        int? id = widget.vendorId;
        if (id == null) {
            id = await StorageService.getUserId();
        }
        
        if (id != null) {
             result = await ApiService.getVendorProducts(id);
        } else {
            result = {'success': false, 'error': 'User not logged in'};
        }
    } else if (widget.vendorId != null) {
         result = await ApiService.getVendorProducts(widget.vendorId!);
    } else {
        result = await ApiService.getProducts();
    }

    if (mounted) {
      setState(() {
        if (result['success'] == true) {
          _products = result['data'];
          _filteredProducts = _products;
          
          _categorizedProducts = {};
          for (var product in _products) {
             if (product.category.isNotEmpty) {
                if (!_categorizedProducts.containsKey(product.category)) {
                  _categorizedProducts[product.category] = [];
                }
                _categorizedProducts[product.category]!.add(product);
             }
          }
          if (_searchController.text.isNotEmpty) {
             _filterProducts(_searchController.text);
          }
          _processSpecialCategories();
        } else {
          _error = result['error'] is Map 
              ? (result['error']['error'] ?? 'Failed to load products') 
              : result['error'].toString();
        }
      });
    }
  }

  List<Product> _newProducts = [];
  List<Product> _topProducts = [];

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _products;
      });
      return;
    }

    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _processSpecialCategories() {
    List<Product> sortedByNew = List.from(_products)..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    _newProducts = sortedByNew.take(5).toList();

    List<Product> sortedByRating = List.from(_products)..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    _topProducts = sortedByRating.take(5).toList();
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const StoreShimmer();
    }

    if (_error != null) {
      return Center(
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isVendorView
                      ? Icons.inventory_2_outlined
                      : Icons.store_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isVendorView
                    ? 'You haven\'t added any products yet.'
                    : 'No items in the market.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (!widget.isVendorView)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Material(
              color: Colors.transparent,
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Search for fresh products...',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            color: AppTheme.warmWhite,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search my products...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 15,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
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
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterProducts('');
                          if (_isListening) {
                            _speech.stop();
                            setState(() => _isListening = false);
                          }
                        },
                      ),
                  ],
                )
              ),
              onChanged: _filterProducts,
            ),
          ),

        Expanded(
          child: Responsive.centeredWebContainer(
            context,
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                if (!widget.isVendorView && _searchController.text.isEmpty && _topBanners.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 220, // Keep existing carousel height
                          child: Stack(
                            children: [
                              PageView.builder(
                                controller: _carouselController,
                                itemCount: _topBanners.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentCarouselIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  return Transform.scale(
                                    scale: 1.08, // Zoom in slightly to crop out any edge watermarks
                                    child: Image.network(
                                      _topBanners[index].image,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _topBanners.asMap().entries.map((entry) {
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: _currentCarouselIndex == entry.key ? 20.0 : 8.0,
                                      height: 8.0,
                                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.white.withOpacity(_currentCarouselIndex == entry.key ? 0.9 : 0.4),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Shop by Category',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                if (_searchController.text.isNotEmpty || widget.isVendorView)
                   SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: Responsive.getGridCrossAxisCount(context, mobile: 2, tablet: 3, desktop: 5),
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return ProductCard(
                              product: _filteredProducts[index],
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailsPage(product: _filteredProducts[index]),
                                  ),
                                ).then((_) => _loadProducts());
                              },
                              onEdit: widget.isVendorView ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AddProductPage(product: _filteredProducts[index]),
                                  ),
                                ).then((value) {
                                  if (value == true) {
                                    _loadProducts();
                                  }
                                });
                              } : null,
                            );
                          },
                          childCount: _filteredProducts.length,
                        ),
                      ),
                    )
                else if (!widget.isVendorView)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: Responsive.getGridCrossAxisCount(context, mobile: 4, tablet: 6, desktop: 8), 
                        childAspectRatio: 0.7, // Adjusted for narrower items
                        crossAxisSpacing: 10, // Slightly reduced spacing
                        mainAxisSpacing: 16,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final category = _categorizedProducts.keys.elementAt(index);
                          final products = _categorizedProducts[category]!;
                          String? imageUrl;
                          if (products.isNotEmpty && products.first.images.isNotEmpty) {
                             imageUrl = products.first.images.first.imageUrl;
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CategoryProductsPage(
                                    category: category,
                                    products: products,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.softBeige.withOpacity(0.3), // Light bg
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      child: imageUrl != null 
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(imageUrl, fit: BoxFit.cover),
                                          )
                                        : Center(
                                            child: Text(
                                              _getCategoryEmoji(category),
                                              style: const TextStyle(fontSize: 32),
                                            ),
                                          ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _categorizedProducts.keys.length,
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(child: SizedBox(height: 4)),

                  if (!widget.isVendorView && _newProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection('New Arrivals ✨', _newProducts),
                    ),

                  if (!widget.isVendorView && _topProducts.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection('Top Rated ⭐', _topProducts),
                    ),

                  if (!widget.isVendorView && _bottomBanners.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      height: 180, // Increased height slightly
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _bannerPageController,
                            itemCount: _bottomBanners.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentBannerIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16), // Consistent side padding
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _bottomBanners[index].image,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _bottomBanners.asMap().entries.map((entry) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: _currentBannerIndex == entry.key ? 20.0 : 8.0,
                                  height: 8.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.white.withOpacity(
                                        _currentBannerIndex == entry.key ? 0.9 : 0.4),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                      child: Divider(),
                    ),
                  ),

                  if (!widget.isVendorView)
                  for (var category in _categorizedProducts.keys)
                    if (_categorizedProducts[category]!.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildCategorySection(category, _categorizedProducts[category]!),
                      ),
                      
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
  Widget _buildCategorySection(String category, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _getCategoryEmoji(category),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CategoryProductsPage(
                        category: category,
                        products: products,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 185, // Height for ProductCard + Padding
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 110, // Fixed width for horizontal card
                child: ProductCard(
                  product: products[index],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(product: products[index]),
                      ),
                    ).then((_) => _loadProducts());
                  },
                  onEdit: widget.isVendorView ? () {
                       Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => AddProductPage(product: products[index]))
                      ).then((value) {
                           if (value == true) _loadProducts();
                      });
                  } : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildHorizontalSection(String title, List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 185,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 110,
                child: ProductCard(
                  product: products[index],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductDetailsPage(product: products[index]),
                      ),
                    ).then((_) => _loadProducts());
                  },
                  onEdit: widget.isVendorView ? () { /*...*/ } : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
