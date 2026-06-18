import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cart_order_models.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/product_card.dart';
import '../theme/app_theme.dart';
import 'checkout_page.dart';
import '../utils/responsive.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> with SingleTickerProviderStateMixin {
  late Product _product;
  ProductReview? _userReview;
  int? _currentUserId;
  List<ProductReview> _reviews = [];
  bool _isLoadingReviews = false;
  
  late TabController _tabController;

  CartItem? _cartItem;
  bool _isLoadingCart = false;

  List<Product> _similarProducts = [];
  bool _isLoadingSimilar = false;

  double _quantityStep = 1.0;
  String _selectedUnitName = '';
  List<Map<String, dynamic>> _variants = [];
  double _currentPrice = 0.0;
  double _currentStock = 0.0;

  bool _isWishlisted = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to update FAB visibility
    });
    
    print('ProductDetailsPage initState - Product: ${_product.name}');
    _calculateVariants(); // Calculate variants first
    _initialize();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculateVariants() {
    _variants = [];
    
    if (_product.variants.isNotEmpty) {
       _variants = _product.variants.map((v) => {
         'step': v.quantity,
         'name': '${v.quantity} ${v.unit}',
         'price': v.price,
         'stock': v.stockQuantity,
       }).toList();
       
       _variants.sort((a, b) => (a['step'] as double).compareTo(b['step'] as double));

    } else {
      final unit = _product.unit.toLowerCase();

      if (unit == 'kg') {
        _variants = [
          {'step': 0.25, 'name': '250g', 'price': _product.price * 0.25, 'stock': _product.stockQuantity},
          {'step': 0.5, 'name': '500g', 'price': _product.price * 0.5, 'stock': _product.stockQuantity},
          {'step': 1.0, 'name': '1kg', 'price': _product.price * 1.0, 'stock': _product.stockQuantity},
          {'step': 2.0, 'name': '2kg', 'price': _product.price * 2.0, 'stock': _product.stockQuantity},
        ];
      } else if (unit == 'l' || unit == 'liter' || unit == 'litre') {
        _variants = [
          {'step': 0.25, 'name': '250ml', 'price': _product.price * 0.25, 'stock': _product.stockQuantity},
          {'step': 0.5, 'name': '500ml', 'price': _product.price * 0.5, 'stock': _product.stockQuantity},
          {'step': 1.0, 'name': '1L', 'price': _product.price * 1.0, 'stock': _product.stockQuantity},
          {'step': 2.0, 'name': '2L', 'price': _product.price * 2.0, 'stock': _product.stockQuantity},
        ];
      } else if (unit == 'dozen') {
        _variants = [
          {'step': 0.5, 'name': '6 pcs', 'price': _product.price * 0.5, 'stock': _product.stockQuantity},
          {'step': 1.0, 'name': '1 dozen', 'price': _product.price * 1.0, 'stock': _product.stockQuantity},
          {'step': 2.0, 'name': '2 dozen', 'price': _product.price * 2.0, 'stock': _product.stockQuantity},
        ];
      } else {
        _variants = [
          {'step': 1.0, 'name': '1 $unit', 'price': _product.price, 'stock': _product.stockQuantity},
          {'step': 2.0, 'name': '2 $unit', 'price': _product.price * 2.0, 'stock': _product.stockQuantity},
          {'step': 5.0, 'name': '5 $unit', 'price': _product.price * 5.0, 'stock': _product.stockQuantity},
        ];
      }
    }

    if (_variants.isNotEmpty) {
      _quantityStep = _variants.first['step'];
      _selectedUnitName = _variants.first['name'];
      _currentPrice = _variants.first['price'];
      _currentStock = _variants.first['stock'];
    }
  }

  Future<void> _initialize() async {
    _currentUserId = await StorageService.getUserId();
    _checkCart();
    _checkWishlist();
    _loadSimilarProducts();
    _loadReviews();
  }

  Future<void> _checkWishlist() async {
    if (_currentUserId == null) {
      print('[Wishlist] _checkWishlist skipped: userId is null');
      return;
    }
    print('[Wishlist] Checking wishlist for user=$_currentUserId, product=${_product.id}');
    final result = await ApiService.checkWishlist(_currentUserId!, _product.id);
    print('[Wishlist] checkWishlist result: $result');
    if (mounted && result['success'] == true) {
      setState(() {
        _isWishlisted = result['data']['is_wishlisted'] ?? false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    final userId = await StorageService.getUserId();
    print('[Wishlist] _toggleWishlist called. userId=$userId, productId=${_product.id}');
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to modify wishlist')));
      return;
    }

    setState(() {
      _isWishlisted = !_isWishlisted;
    });

    final result = await ApiService.toggleWishlist(userId, _product.id);
    print('[Wishlist] toggleWishlist result: $result');
    if (mounted) {
      if (result['success'] == true) {
        String msg = result['data']['status'] == 'added' ? 'Added to Wishlist' : 'Removed from Wishlist';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
      } else {
        setState(() {
          _isWishlisted = !_isWishlisted;
        });
        _showError(result['error']);
      }
    }
  }

  Future<void> _loadSimilarProducts() async {
    setState(() => _isLoadingSimilar = true);
    final result = await ApiService.getProducts();
    if (mounted && result['success'] == true) {
      setState(() {
        _similarProducts = ((result['data'] as List).cast<Product>()).take(4).toList();
        _isLoadingSimilar = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    final result = await ApiService.getProductReviews(_product.id);
    if (mounted && result['success'] == true) {
      setState(() {
        _reviews = result['data'];
        if (_currentUserId != null) {
          try {
            _userReview = _reviews.firstWhere((r) => r.userId == _currentUserId);
          } catch (e) {
            _userReview = null;
          }
        }
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _checkCart() async {
    if (_currentUserId == null) return;
    
    final result = await ApiService.getCart(_currentUserId!);
    if (mounted && result['success'] == true) {
      final Cart cart = result['data'];
      try {
        setState(() {
          _cartItem = cart.items.firstWhere((item) => 
              item.productId == _product.id && item.unitValue == _quantityStep
          );
        });
      } catch (e) {
        setState(() => _cartItem = null);
      }
    }
  }

  Future<void> _addToCart() async {
    final userId = await StorageService.getUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to add items to cart')));
      return;
    }

    final currentCartQty = _cartItem?.quantity ?? 0;
    if (currentCartQty + 1 > _currentStock) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('Cannot add more. Stock limit: $_currentStock'), 
           backgroundColor: Colors.red
       ));
       return;
    }

    setState(() => _isLoadingCart = true);
    final result = await ApiService.addToCart(userId, _product.id, _quantityStep, quantity: 1);
    setState(() => _isLoadingCart = false);

    if (mounted) {
      if (result['success'] == true) {
        final Cart cart = result['data'];
        setState(() {
           _cartItem = cart.items.firstWhere((item) => 
               item.productId == _product.id && item.unitValue == _quantityStep
           );
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Cart!'), backgroundColor: Colors.green));
      }
    }
  }

  Future<void> _buyNow() async {
    final userId = await StorageService.getUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to buy items')));
      return;
    }

    if (_currentStock <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Item is out of stock.'), 
          backgroundColor: Colors.red
      ));
      return;
    }

    final directOrderData = {
      'product_id': _product.id,
      'quantity': 1.0,
      'unit_value': _quantityStep,
    };

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPage(directOrderData: directOrderData)
      )
    );
  }

  Future<void> _showAddReviewDialog() async {
     if (_currentUserId == null) {
          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to review')));
          return;
     }

     if (_currentUserId == _product.vendorId) {
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot review your own product')));
        return;
     }

     if (_userReview != null) {
       _showEditReviewDialog();
       return;
     }

     final commentController = TextEditingController();
     int rating = 5;

     showDialog(
       context: context,
       builder: (context) {
         return StatefulBuilder(
           builder: (context, setStateDialog) {
             return Dialog(
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: AppTheme.warmWhite,
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                       'Write a Review',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     const SizedBox(height: 24),
                     FittedBox(
                       fit: BoxFit.scaleDown,
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: List.generate(5, (index) {
                           return Material(
                             color: Colors.transparent,
                             child: InkWell(
                               onTap: () => setStateDialog(() => rating = index + 1),
                               borderRadius: BorderRadius.circular(24),
                               child: Padding(
                                 padding: const EdgeInsets.all(8.0),
                                 child: Icon(
                                   index < rating
                                       ? Icons.star_rounded
                                       : Icons.star_border_rounded,
                                   color: const Color(0xFFD4A574),
                                   size: 40,
                                 ),
                               ),
                             ),
                           );
                         }),
                       ),
                     ),
                     const SizedBox(height: 24),
                     TextField(
                       controller: commentController,
                       decoration: const InputDecoration(
                         labelText: 'Comment (Optional)',
                       ),
                       maxLines: 3,
                     ),
                     const SizedBox(height: 24),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         TextButton(
                           onPressed: () => Navigator.pop(context),
                           child: Text(
                             'Cancel',
                             style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!),
                           ),
                         ),
                         const SizedBox(width: 12),
                         ElevatedButton(
                           onPressed: () async {
                             Navigator.pop(context);
                             _submitReview(_currentUserId!, rating,
                                 commentController.text.trim());
                           },
                           child: const Text('Submit'),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
             );
           }
         );
       }
     );
  }

  Future<void> _showEditReviewDialog() async {
     final commentController = TextEditingController(text: _userReview!.comment);
     int rating = _userReview!.rating;

     showDialog(
       context: context,
       builder: (context) {
         return StatefulBuilder(
           builder: (context, setStateDialog) {
             return Dialog(
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: AppTheme.warmWhite,
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                       'Edit Your Review',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     const SizedBox(height: 24),
                     FittedBox(
                       fit: BoxFit.scaleDown,
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: List.generate(5, (index) {
                           return Material(
                             color: Colors.transparent,
                             child: InkWell(
                               onTap: () => setStateDialog(() => rating = index + 1),
                               borderRadius: BorderRadius.circular(24),
                               child: Padding(
                                 padding: const EdgeInsets.all(8.0),
                                 child: Icon(
                                   index < rating
                                       ? Icons.star_rounded
                                       : Icons.star_border_rounded,
                                   color: const Color(0xFFD4A574),
                                   size: 40,
                                 ),
                               ),
                             ),
                           );
                         }),
                       ),
                     ),
                     const SizedBox(height: 24),
                     TextField(
                       controller: commentController,
                       decoration: const InputDecoration(
                         labelText: 'Comment (Optional)',
                       ),
                       maxLines: 3,
                     ),
                     const SizedBox(height: 24),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         TextButton(
                           onPressed: () {
                             Navigator.pop(context);
                             _deleteReview();
                           },
                           style: TextButton.styleFrom(
                             foregroundColor: Theme.of(context).colorScheme.error,
                           ),
                           child: const Text('Delete'),
                         ),
                         const SizedBox(width: 12),
                         TextButton(
                           onPressed: () => Navigator.pop(context),
                           child: Text(
                             'Cancel',
                             style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!),
                           ),
                         ),
                         const SizedBox(width: 12),
                         ElevatedButton(
                           onPressed: () async {
                             Navigator.pop(context);
                             _updateReview(rating, commentController.text.trim());
                           },
                           child: const Text('Update'),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
             );
           }
         );
       }
     );
  }

  Future<void> _submitReview(int userId, int rating, String comment) async {
       final result = await ApiService.addReview(_product.id, {
           'user': userId,
           'rating': rating,
           'comment': comment,
       });

       if (!mounted) return;

       if (result['success'] == true) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Submitted!'), backgroundColor: Colors.green));
           _refreshProductAndReviews();
       } else {
            _showError(result['error']);
       }
  }

  Future<void> _updateReview(int rating, String comment) async {
       if (_userReview == null) return;
       
       final result = await ApiService.updateReview(_userReview!.id, {
           'rating': rating,
           'comment': comment,
       });

       if (!mounted) return;

       if (result['success'] == true) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Updated!'), backgroundColor: Colors.green));
           _refreshProductAndReviews();
       } else {
            _showError(result['error']);
       }
  }

  Future<void> _deleteReview() async {
       if (_userReview == null) return;

       final result = await ApiService.deleteReview(_userReview!.id);

       if (!mounted) return;

       if (result['success'] == true) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Deleted!'), backgroundColor: Colors.grey));
           _userReview = null; 
           _refreshProductAndReviews();
       } else {
            _showError(result['error']);
       }
  }

  Future<void> _refreshProductAndReviews() async {
      final productResult = await ApiService.getProductDetails(_product.id);
      if (productResult['success'] == true) {
           setState(() {
               _product = productResult['data'];
           });
      }
      _loadReviews();
  }
  
  void _showError(dynamic error) {
      String errorMessage = error is Map 
        ? (error['non_field_errors']?[0] ?? error['error'] ?? 'Operation failed') 
        : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
  }

  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    print('ProductDetailsPage build called');
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leading: Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: _isWishlisted ? Colors.red : Colors.grey[700],
              ),
              onPressed: _toggleWishlist,
            ),
          ),
        ],
      ),
      body: Responsive.centeredWebContainer(
        context,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: Stack(
                children: [
                  _product.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: _product.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              _product.images[index].imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppTheme.softBeige,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    size: 64,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.3),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : Container(
                          color: AppTheme.warmWhite,
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.3),
                            ),
                          ),
                        ),
                  if (_product.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _product.images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? AppTheme.accentTerracotta
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            
            Container(
              color: AppTheme.warmWhite,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${_currentPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.softBeige,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<double>(
                        value: _quantityStep,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen),
                        items: _variants.map((variant) {
                          return DropdownMenuItem<double>(
                            value: variant['step'],
                            child: Text(
                              variant['name'],
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _quantityStep = value;
                              final selectedVariant = _variants.firstWhere((v) => v['step'] == value);
                              _selectedUnitName = selectedVariant['name'];
                              _currentPrice = selectedVariant['price'];
                              _currentStock = selectedVariant['stock'];
                              _cartItem = null; // Reset current cart viewing state to check for new unit
                            });
                            _checkCart(); // Check if this new unit variant is in cart
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Text(
                        'Status: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _currentStock > 0 
                            ? AppTheme.successGreen.withOpacity(0.1) 
                            : AppTheme.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentStock > 0 ? 'In Stock' : 'Out of Stock',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _currentStock > 0 
                              ? AppTheme.successGreen 
                              : AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vendor: ${_product.vendorName}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            Container(
              color: AppTheme.warmWhite,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.accentTerracotta,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.accentTerracotta,
                tabs: const [
                  Tab(text: "Description"),
                  Tab(text: "Reviews"),
                ],
              ),
            ),

            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                 if (_tabController.index == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _product.description ?? 'No description available.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                 } else {
                    return Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          if (_isLoadingReviews)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            )
                          else if (_reviews.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.rate_review_outlined,
                                        size: 40,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No reviews yet',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Be the first to review!',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).textTheme.bodyMedium!.color!,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _reviews.length,
                              itemBuilder: (context, index) {
                                final review = _reviews[index];
                                final isUserReview = _currentUserId != null &&
                                    review.userId == _currentUserId;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  color: isUserReview
                                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                                      : AppTheme.warmWhite,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: isUserReview
                                              ? Theme.of(context).colorScheme.primary
                                              : AppTheme.accentTerracotta,
                                          child: Text(
                                            review.userName.isNotEmpty
                                                ? review.userName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      review.userName +
                                                          (isUserReview
                                                              ? ' (You)'
                                                              : ''),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (starIndex) => Icon(
                                                    starIndex < review.rating
                                                        ? Icons.star_rounded
                                                        : Icons.star_border_rounded,
                                                    size: 16,
                                                    color: const Color(0xFFD4A574),
                                                  ),
                                                ),
                                              ),
                                              if (review.comment != null &&
                                                  review.comment!.isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Text(
                                                  review.comment!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                    color: Theme.of(context).textTheme.bodyMedium!.color!,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ],
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
                    );
                 }
              },
            ),
            
            if (_similarProducts.isNotEmpty) ...[
               const SizedBox(height: 24),
               Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 20.0),
                 child: Text(
                   'Similar Products',
                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
               const SizedBox(height: 16),
               SizedBox(
                 height: 260, // Height for ProductCard
                 child: ListView.separated(
                   padding: const EdgeInsets.symmetric(horizontal: 20),
                   scrollDirection: Axis.horizontal,
                   itemCount: _similarProducts.length,
                   separatorBuilder: (context, index) => const SizedBox(width: 16),
                   itemBuilder: (context, index) {
                     final product = _similarProducts[index];
                     return SizedBox(
                       width: 160,
                       child: ProductCard(
                         product: product,
                         onTap: () {
                           Navigator.push(
                             context, 
                             MaterialPageRoute(
                               builder: (context) => ProductDetailsPage(product: product)
                             )
                           );
                         },
                       ),
                     );
                   },
                 ),
               ),
               const SizedBox(height: 80), // Bottom padding
            ],
          ],
        ),
      ),
      ),
      floatingActionButton: (_tabController.index == 1 && 
              _currentUserId != null &&
              _currentUserId != _product.vendorId)
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: AppAnimations.slow,
              curve: AppAnimations.bounceCurve,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: FloatingActionButton.extended(
                    onPressed: _showAddReviewDialog,
                    backgroundColor: AppTheme.accentTerracotta,
                    icon: Icon(
                      _userReview != null
                          ? Icons.edit_outlined
                          : Icons.rate_review_outlined,
                    ),
                    label: Text(_userReview != null
                        ? 'Edit'
                        : 'Write a Review'),
                  ),
                );
              },
            ) : null,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warmWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: (_currentUserId != null && _currentUserId == _product.vendorId)
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null, // Disabled
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.grey[600],
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[600],
                    ),
                    child: const Text('Your Product'),
                  ),
                )
              : Row(
                  children: [
                    if (_cartItem == null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _product.stockQuantity <= 0 ? null : _addToCart,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: _product.stockQuantity <= 0 
                                    ? Colors.grey 
                                    : Theme.of(context).colorScheme.primary),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(_product.stockQuantity <= 0 ? 'Out of Stock' : 'Add to Cart'),
                        ),
                      )
                    else 
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('In Cart: ${_cartItem!.quantity}'),
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _product.stockQuantity <= 0 ? null : _buyNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentTerracotta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Buy Now'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
