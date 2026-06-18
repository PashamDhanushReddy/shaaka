import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/cart_order_models.dart';
import '../theme/app_theme.dart';
import 'checkout_page.dart';
import 'wishlist_page.dart';
import '../widgets/shimmer_widgets.dart';
import '../utils/responsive.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Cart? _cart;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await StorageService.getUserId();
      if (userId == null) {
        setState(() {
          _error = 'Please login to view cart';
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.getCart(userId);
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _cart = result['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
             if (result['error'].toString().contains('not found')) {
               _cart = null; 
             } else {
               _error = result['error'].toString();
             }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, double newQuantity) async {
    if (newQuantity < 0) return;

    final userId = await StorageService.getUserId();
    if (userId == null) return;

    final result = await ApiService.updateCartItem(userId, item.id, newQuantity);
    if (result['success'] == true) {
      setState(() {
        _cart = result['data'];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] is Map ? result['error']['error'] : result['error'].toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    final userId = await StorageService.getUserId();
    if (userId == null) return;

    final result = await ApiService.removeFromCart(userId, item.id);
    if (result['success'] == true) {
      setState(() {
        _cart = result['data'];
      });
    } else {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'].toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WishlistPage()),
              );
            },
          ),
        ],
      ),
      body: Responsive.centeredWebContainer(
        context,
        child: _isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (_, i) => CartItemShimmer(index: i),
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
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : _cart == null || _cart!.items.isEmpty
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
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_cart_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Your cart is empty',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add some products to get started!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium!.color!,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cart!.items.length,
                            itemBuilder: (context, index) {
                              final item = _cart!.items[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: AppAnimations.medium,
                                curve: AppAnimations.defaultCurve,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: AppTheme.softBeige,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: item.productImageUrl != null
                                                ? Image.network(
                                                    item.productImageUrl!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) => Icon(
                                                      Icons.shopping_bag_outlined,
                                                      color: Theme.of(context).textTheme.bodySmall!.color!,
                                                    ),
                                                  )
                                                : Icon(
                                                    Icons.shopping_bag_outlined,
                                                    color: Theme.of(context).textTheme.bodySmall!.color!,
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Size: ${item.variantLabel ?? (item.unitValue < 1 && (item.unit == "kg" || item.unit == "l") ? "${(item.unitValue * 1000).toInt()}${item.unit == "kg" ? "g" : "ml"}" : "${item.unitValue} ${item.unit}")}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                  color: Theme.of(context).textTheme.bodySmall!.color!,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '₹${item.totalPrice.toStringAsFixed(2)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Material(
                                                    color: Theme.of(context).colorScheme.primary
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    child: InkWell(
                                                      onTap: () {
                                                        _updateQuantity(
                                                            item,
                                                            item.quantity - 1.0);
                                                      },
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                      child: Container(
                                                        width: 32,
                                                        height: 32,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Icon(
                                                          Icons.remove_rounded,
                                                          size: 18,
                                                          color:
                                                              Theme.of(context).colorScheme.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(horizontal: 12),
                                                    child: Text(
                                                      '${item.quantity.toInt()}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                    Material(
                                                      color: item.quantity >= item.stockQuantity 
                                                          ? Colors.grey.withOpacity(0.1)
                                                          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                      child: InkWell(
                                                        onTap: item.quantity >= item.stockQuantity 
                                                            ? () {
                                                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                  content: Text('Cannot add more. Stock limit: ${item.stockQuantity}'),
                                                                  duration: const Duration(seconds: 2),
                                                                  backgroundColor: Colors.red,
                                                                ));
                                                            }
                                                            : () {
                                                                _updateQuantity(
                                                                    item,
                                                                    item.quantity + 1.0);
                                                              },
                                                        borderRadius:
                                                            BorderRadius.circular(8),
                                                        child: Container(
                                                          width: 32,
                                                          height: 32,
                                                          alignment:
                                                              Alignment.center,
                                                          child: Icon(
                                                            Icons.add_rounded,
                                                            size: 18,
                                                            color: item.quantity >= item.stockQuantity
                                                                ? Colors.grey
                                                                : Theme.of(context).colorScheme.primary,
                                                          ),
                                                      ),
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Material(
                                                    color: Theme.of(context).colorScheme.error
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                    child: InkWell(
                                                      onTap: () => _removeItem(item),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                      child: Container(
                                                        width: 36,
                                                        height: 36,
                                                        alignment:
                                                            Alignment.center,
                                                        child: Icon(
                                                          Icons.delete_outline_rounded,
                                                          size: 20,
                                                          color: Theme.of(context).colorScheme.error,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.warmWhite,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, -4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Amount:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '₹${_cart!.totalPrice.toStringAsFixed(2)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: _AnimatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CheckoutPage(),
                                        ),
                                      );
                                    },
                                    isLoading: false,
                                    child: const Text(
                                      'Proceed to Checkout',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
      ),
    );
  }
}

class _AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;

  const _AnimatedButton({
    required this.onPressed,
    required this.isLoading,
    required this.child,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        if (widget.onPressed != null) {
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 - (_controller.value * 0.05),
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isPressed ? 2 : 4,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : widget.child,
            ),
          );
        },
      ),
    );
  }
}
