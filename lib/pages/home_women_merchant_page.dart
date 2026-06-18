import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'store_page.dart';
import 'donations_page.dart';
import 'add_product_page.dart';
import 'cart_page.dart';
import 'my_orders_page.dart';

class HomeWomenMerchantPage extends StatefulWidget {
  const HomeWomenMerchantPage({super.key});

  @override
  State<HomeWomenMerchantPage> createState() => _HomeWomenMerchantPageState();
}
class _HomeWomenMerchantPageState extends State<HomeWomenMerchantPage> {
  int _selectedIndex = 0; // Default to first tab (Common Store)
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _fetchInitialCart();
  }

  Future<void> _fetchInitialCart() async {
    final userId = await StorageService.getUserId();
    if (userId != null) {
      await ApiService.getCart(userId);
    }
  }

  List<Widget> get _pages => <Widget>[
    StorePage(key: ValueKey('store_$_refreshKey'), isVendorView: false), // Common Store
    StorePage(key: ValueKey('my_business_$_refreshKey'), isVendorView: true), // My Business (My Products)
    CartPage(key: ValueKey('cart_$_refreshKey')),
    MyOrdersPage(key: ValueKey('orders_$_refreshKey')),
    const DonationsPage(), 
  ];

  void _refreshPages() {
    setState(() {
      _refreshKey++;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _refreshKey++; // Refresh when switching tabs
    });
  }

  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
            _refreshKey++;
          });
          return false;
        }
        final now = DateTime.now();
        if (_lastPressedAt == null || 
            now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
               Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Shaaka'),
            ],
          ),
          actions: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
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
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.store_outlined),
                activeIcon: Icon(Icons.store),
                label: 'Store',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                activeIcon: Icon(Icons.storefront),
                label: 'My Business',
              ),
              BottomNavigationBarItem(
                icon: ValueListenableBuilder<int>(
                  valueListenable: CartService.cartItemCountNotifier,
                  builder: (context, count, _) {
                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text(count.toString()),
                      child: const Icon(Icons.shopping_cart_outlined),
                    );
                  },
                ),
                activeIcon: ValueListenableBuilder<int>(
                  valueListenable: CartService.cartItemCountNotifier,
                  builder: (context, count, _) {
                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text(count.toString()),
                      child: const Icon(Icons.shopping_cart),
                    );
                  },
                ),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt),
                label: 'My Orders',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.volunteer_activism_outlined),
                activeIcon: Icon(Icons.volunteer_activism),
                label: 'Donations',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).textTheme.bodySmall!.color!,
            onTap: _onItemTapped,
            elevation: 8,
          ),
        ),
        floatingActionButton: _selectedIndex == 1
            ? TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppAnimations.medium,
                curve: AppAnimations.bounceCurve,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (context) => const AddProductPage(),
                              ),
                            )
                            .then((value) {
                          _refreshPages();
                        });
                      },
                      backgroundColor: AppTheme.accentTerracotta,
                      icon: Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add Product',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              )
            : null,
      ),
    );
  }
}
