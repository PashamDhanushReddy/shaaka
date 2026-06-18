import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/cart_order_models.dart';
import 'order_detail_page.dart';
import '../widgets/shimmer_widgets.dart';

class MyOrdersPage extends StatefulWidget {
  final bool showBackButton;
  const MyOrdersPage({super.key, this.showBackButton = false});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId = await StorageService.getUserId();
    if (userId == null) return;

    final result = await ApiService.getOrders(userId);
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _orders = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatusText(Order order) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (order.status == 'Delivered') {
      return Text(
        'Delivered ${DateFormat('d MMMM').format(order.createdAt)}', 
        style: TextStyle(color: Colors.grey[700], fontSize: 14),
      );
    } else if (order.status == 'Cancelled') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cancelled', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
          const SizedBox(height: 2),
          Text(
            order.isPaid ? 'Your refund has been initiated.' : 'Your order has been cancelled.', 
            style: TextStyle(color: Colors.grey[600], fontSize: 13)
          ),
        ],
      );
    } else if (order.status == 'Processing' || order.status == 'Shipped') {
      return Text(
        order.status == 'Shipped' ? 'Arriving Soon' : 'Preparing for Dispatch',
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 15),
      );
    } else {
      return Text(
        'Ordered ${DateFormat('d MMMM').format(order.createdAt)}',
        style: TextStyle(color: Colors.grey[700], fontSize: 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false, // customized leading override
        leading: widget.showBackButton 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                   Navigator.of(context).popUntil((route) => route.isFirst);
                },
              )
            : null,
      ),
      body: _isLoading
          ? const OrderListShimmer()
          : _orders.isEmpty
              ? const Center(child: Text('No orders yet'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final firstItem = order.items.isNotEmpty ? order.items.first : null;
                    final itemName = firstItem != null 
                        ? '${firstItem.productName}${order.items.length > 1 ? ' + ${order.items.length - 1} more' : ''}'
                        : 'Order #${order.id}';
                    
                    return GestureDetector(
                      onTap: () {
                         Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailPage(orderId: order.id),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: firstItem?.productImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        firstItem!.productImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.shopping_bag, color: Colors.grey, size: 40),
                            ),
                            const SizedBox(width: 16),
                            
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  _buildStatusText(order),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
