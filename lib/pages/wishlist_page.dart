import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/product_card.dart';
import '../theme/app_theme.dart';
import 'product_details_page.dart';
import '../widgets/shimmer_widgets.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Product> _wishlistProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);
    
    final userId = await StorageService.getUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await ApiService.getWishlist(userId);
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _wishlistProducts = (result['data'] as List).cast<Product>();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wishlist: ${result['error']}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _navigateToProduct(Product product) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsPage(product: product),
      ),
    );
    _loadWishlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: AppTheme.warmWhite,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const WishlistShimmer()
          : _wishlistProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Your wishlist is empty',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save items you like to view them later.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadWishlist,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 items per row
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _wishlistProducts.length,
                    itemBuilder: (context, index) {
                      final product = _wishlistProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => _navigateToProduct(product),
                      );
                    },
                  ),
                ),
    );
  }
}
