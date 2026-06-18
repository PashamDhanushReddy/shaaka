import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/cart_order_models.dart';
import '../services/storage_service.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final result = await ApiService.getOrderDetails(widget.orderId);
    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _order = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'].toString()),
        ));
      }
    }
  }

  Future<void> _cancelOrder() async {
    final firstItem = _order!.items.isNotEmpty ? _order!.items.first : null;
    final itemName = firstItem != null 
        ? '${firstItem.productName}${_order!.items.length > 1 ? ' + ${_order!.items.length - 1} more' : ''}'
        : 'Order #${_order!.id}';

    final String? cancelReason = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => CancelOrderScreen(itemName: itemName),
      ),
    );

    if (cancelReason == null) return;

    setState(() => _isLoading = true);

    final userId = await StorageService.getUserId();
    if (userId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User session not found. Please log in again.')));
      }
      return;
    }

    final result = await ApiService.cancelOrder(userId, widget.orderId, reason: cancelReason);
    
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order cancelled successfully'),
          backgroundColor: Colors.green,
        ));
        setState(() {
          _order = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] is Map ? (result['error']['error'] ?? 'Failed') : result['error'].toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_order == null) return const Scaffold(body: Center(child: Text('Order not found')));

    final primaryColor = Theme.of(context).colorScheme.primary;

    Color statusColor;
    Color statusBgColor;
    if (_order!.status == 'Delivered') {
      statusColor = Colors.green;
      statusBgColor = Colors.green.withOpacity(0.1);
    } else if (_order!.status == 'Cancelled') {
      statusColor = Colors.red;
      statusBgColor = Colors.red.withOpacity(0.1);
    } else {
      statusColor = primaryColor;
      statusBgColor = primaryColor.withOpacity(0.1);
    }
    final firstItem = _order!.items.isNotEmpty ? _order!.items.first : null;
    final itemName = firstItem != null 
        ? '${firstItem.productName}${_order!.items.length > 1 ? ' + ${_order!.items.length - 1} more' : ''}'
        : 'Order #${_order!.id}';

    return Scaffold(
      appBar: AppBar(title: Text(itemName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                   Text(
                     'Status: ${_order!.status}', 
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor)
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'Placed on: ${DateFormat('MMM dd, yyyy h:mm a').format(_order!.createdAt)}',
                     style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Items Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _order!.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _order!.items[index];
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item.productImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.productImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                  ),
                                )
                              : const Icon(Icons.shopping_bag, color: Colors.grey, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName, 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text('Qty: ${item.quantity.toString().replaceAll(RegExp(r"([.]*0+)(?!.*\d)"), "")}', style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹${(item.priceAtPurchase * item.quantity).toStringAsFixed(2)}', 
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16)
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Method', style: TextStyle(fontSize: 16)),
                      Text(_order!.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${_order!.totalAmount.toStringAsFixed(2)}', 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Shipping Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_order!.shippingAddress, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${_order!.city}, ${_order!.state}', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(_order!.pincode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_order!.status == 'Placed' || _order!.status == 'Processing')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelOrder,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class CancelOrderScreen extends StatefulWidget {
  final String itemName;
  const CancelOrderScreen({super.key, required this.itemName});

  @override
  State<CancelOrderScreen> createState() => _CancelOrderScreenState();
}

class _CancelOrderScreenState extends State<CancelOrderScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedReason;

  final List<String> _cancelReasons = [
    'Ordered by mistake',
    'Found a better price elsewhere',
    'Delivery is taking too long',
    'Want to change delivery address',
    'Want to change payment method',
    'Ordered the wrong product',
    'Ordered the wrong quantity',
    'Product no longer needed',
    'Duplicate order placed',
    'Financial reasons / budget constraints',
    'Purchased from another seller',
    'Other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.itemName)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cancel Order',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Please select a reason for cancellation:'),
                      const SizedBox(height: 16),
                      ..._cancelReasons.map((String reason) {
                        return RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: _selectedReason,
                          contentPadding: EdgeInsets.zero,
                          activeColor: Theme.of(context).colorScheme.primary,
                          onChanged: (String? value) {
                            setState(() {
                              _selectedReason = value;
                              if (value != 'Other') {
                                _reasonController.text = value ?? '';
                              } else {
                                _reasonController.clear();
                              }
                            });
                          },
                        );
                      }),
                      if (_selectedReason == 'Other') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Please specify',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Reason is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _selectedReason == null ? null : () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.of(context).pop(_reasonController.text.trim());
                    }
                  },
                  child: const Text('Submit Cancellation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
