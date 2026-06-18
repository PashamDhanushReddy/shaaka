import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAdding = false;

  /// Returns the lowest price available for this product across all units.
  double get _lowestPrice {
    final product = widget.product;

    if (product.variants.isNotEmpty) {
      return product.variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
    }

    final unit = product.unit.toLowerCase();
    final basePrice = product.price;

    List<double> prices;
    if (unit == 'kg') {
      prices = [basePrice * 0.25, basePrice * 0.5, basePrice * 1.0, basePrice * 2.0];
    } else if (unit == 'l' || unit == 'liter' || unit == 'litre') {
      prices = [basePrice * 0.25, basePrice * 0.5, basePrice * 1.0, basePrice * 2.0];
    } else if (unit == 'dozen') {
      prices = [basePrice * 0.5, basePrice * 1.0, basePrice * 2.0];
    } else {
      prices = [basePrice * 1.0, basePrice * 2.0, basePrice * 5.0];
    }

    return prices.reduce((a, b) => a < b ? a : b);
  }

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    
    final userId = await StorageService.getUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to add to cart')));
      }
      setState(() => _isAdding = false);
      return;
    }

    final result = await ApiService.addToCart(userId, widget.product.id, 1);
    
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Added to cart'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] is Map ? (result['error']['error'] ?? 'Failed') : result['error'].toString()),
          backgroundColor: Colors.red,
        ));
      }
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                       Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: widget.product.firstImageUrl != null
                            ? Image.network(
                                widget.product.firstImageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.broken_image_rounded,
                                    size: 30,
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  );
                                },
                              )
                            : Icon(
                                Icons.image_not_supported_rounded,
                                size: 30,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              ),
                        ),
                       ),
                       if (widget.product.stockQuantity == 0)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Out',
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.product.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).textTheme.titleLarge?.color, // Adapt to theme
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                 Flexible(
                   child: Text(
                      'From ₹${_lowestPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color, // Adapt to theme
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                 ),
                 const SizedBox(width: 6),
                 if (widget.onEdit != null)
                   InkWell(
                     onTap: widget.onEdit,
                     borderRadius: BorderRadius.circular(16),
                     child: const Padding(
                       padding: EdgeInsets.all(4.0),
                       child: Icon(Icons.edit, size: 24, color: AppTheme.primaryGreen),
                     ),
                   )
                 else if (widget.product.stockQuantity > 0)
                    InkWell(
                      onTap: _isAdding ? null : _addToCart,
                      borderRadius: BorderRadius.circular(16),
                      child: _isAdding 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.add_circle, size: 20, color: Theme.of(context).colorScheme.primary),
                    )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
