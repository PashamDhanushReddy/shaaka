import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';
import 'my_orders_page.dart';
import 'address_form_page.dart';
import '../utils/responsive.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';


class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic>? directOrderData;

  const CheckoutPage({super.key, this.directOrderData});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<dynamic> _savedAddresses = [];
  dynamic _selectedAddress; // Map or Object
  bool _isLoading = true;
  String? _selectedPaymentMethod = 'COD';
  UserProfile? _userProfile;
  late Razorpay _razorpay;
  double _totalAmount = 0.0;
  
  static const String _razorpayKeyId = 'rzp_test_SQJUGMW1QfXb9q';

  
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment Success: ${response.paymentId}");
    _placeOrderFinal(isPaid: true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    debugPrint("Payment Error: ${response.code} - ${response.message}");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.red),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External Wallet: ${response.walletName}");
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _razorpay.clear(); // Clear razorpay listeners
    super.dispose();
  }

  Future<void> _loadData({dynamic newSelectedAddress}) async {
    setState(() => _isLoading = true);
    try {
      final userId = await StorageService.getUserId();
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final addressResult = await ApiService.getUserAddresses(userId);
      
      final profileResult = await ApiService.getProfile(userId);

      if (widget.directOrderData == null) {
        final cartResult = await ApiService.getCart(userId);
        if (cartResult['success'] == true) {
          _totalAmount = cartResult['data'].totalPrice;
        }
      } else {
        final prodId = widget.directOrderData!['product_id'];
        final prodResult = await ApiService.getProductDetails(prodId);
        if (prodResult['success'] == true) {
           final product = prodResult['data'];
           final qty = widget.directOrderData!['quantity'];
           final uv = widget.directOrderData!['unit_value'];
           
           if (widget.directOrderData!.containsKey('price')) {
               _totalAmount = (widget.directOrderData!['price'] * qty).toDouble();
           } else {
               _totalAmount = (product.price * qty * uv).toDouble(); 
           }
        }
      }

      if (mounted) {
         setState(() {
           if (profileResult['success'] == true) {
             _userProfile = profileResult['data'];
           }

           if (addressResult['success'] == true) {
              final data = addressResult['data'];
              final profileAddr = data['profile_address'];
              final saved = data['saved_addresses'] as List;
              
              _savedAddresses = [if (profileAddr != null) profileAddr, ...saved];
              
              if (newSelectedAddress != null) {
                 try {
                     _selectedAddress = _savedAddresses.firstWhere((a) => a['id'] == newSelectedAddress['id']);
                 } catch (e) {
                     _selectedAddress = newSelectedAddress;
                 }
              }
              else if (_savedAddresses.isNotEmpty) {
                try {
                  _selectedAddress = _savedAddresses.firstWhere((addr) => addr['is_default'] == true);
                } catch (e) {
                  _selectedAddress = _savedAddresses.first; 
                }
              }
           }
         });
      }
    } catch (e) {
      debugPrint("Error loading checkout data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNewAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressFormPage()),
    );

    if (result != null) {
      _loadData(newSelectedAddress: result); // Refresh addresses and select new one
    }
  }

  Future<void> _editAddress(Map<String, dynamic> address) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddressFormPage(initialData: address)),
    );

    if (result != null) {
      _loadData(newSelectedAddress: result); // Refresh addresses and select updated one
    }
  }

  Future<void> _deleteAddress(Map<String, dynamic> address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final userId = await StorageService.getUserId();
      if (address['id'] is int) {
         final result = await ApiService.deleteUserAddress(userId!, address['id']);
         if (result['success'] == true) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address deleted')));
            _loadData();
         } else {
            setState(() => _isLoading = false);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${result['error']}')));
         }
      } else {
         setState(() => _isLoading = false); // Should not happen for saved addresses
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {

       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a delivery address')));
       return;
    }

    if (_selectedPaymentMethod == 'Online') {
      _startRazorpayPayment();
    } else {
      _placeOrderFinal();
    }
  }

  void _startRazorpayPayment() {
    setState(() => _isLoading = true);
    
    var options = {
      'key': _razorpayKeyId,
      'amount': (_totalAmount * 100).toInt(), // Amount in paise
      'name': 'Shaaka',
      'description': 'Order Payment',
      'prefill': {
        'contact': _userProfile?.mobileNumber ?? '',
      },

      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _placeOrderFinal({bool isPaid = false}) async {
    setState(() => _isLoading = true);
    final userId = await StorageService.getUserId();
    if (userId == null) return;

    String shippingAddress = '';
    if (_selectedAddress['flat_house_building'] != null && _selectedAddress['flat_house_building'].isNotEmpty) {
      shippingAddress = '${_selectedAddress['flat_house_building']}, ${_selectedAddress['area_street_sector']}';
      if (_selectedAddress['landmark'] != null && _selectedAddress['landmark'].isNotEmpty) {
        shippingAddress += ' (Landmark: ${_selectedAddress['landmark']})';
      }
    } else {
      shippingAddress = _selectedAddress['address_line'] ?? '';
    }

    final city = _selectedAddress['town_city'] ?? _selectedAddress['city'] ?? '';

    final orderData = {
      'shipping_address': shippingAddress,
      'city': city,
      'state': _selectedAddress['state'],
      'pincode': _selectedAddress['pincode'],
      'payment_method': _selectedPaymentMethod,
      'is_paid': isPaid,
    };

    dynamic result;
    if (widget.directOrderData != null) {
      final directData = Map<String, dynamic>.from(widget.directOrderData!);
      directData.remove('price');
      if (directData.containsKey('unit_value')) {
        directData['unit_value'] = directData['unit_value'].toString();
      }
      if (directData.containsKey('quantity')) {
        directData['quantity'] = directData['quantity'].toString();
      }
      orderData.addAll(directData);
      result = await ApiService.placeDirectOrder(userId, orderData);
    } else {
      result = await ApiService.placeOrder(userId, orderData);
    }

    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Order Placed!'),
          content: const Icon(Icons.check_circle, color: Colors.green, size: 64),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close Checkout
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyOrdersPage(showBackButton: true)),
                );
              },
              child: const Text('Go to My Orders'),
            ),
          ],
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] is Map ? (result['error']['error'] ?? 'Failed') : result['error'].toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        elevation: 0,
      ),
      body: Responsive.centeredWebContainer(
        context,
        maxWidth: 600,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       const Text('Delivery Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       TextButton.icon(
                         onPressed: _addNewAddress,
                         icon: const Icon(Icons.add),
                         label: const Text("Add New"),
                       )
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  ..._savedAddresses.map((addr) {
                      final title = addr['full_name'] != null && addr['full_name'].isNotEmpty 
                          ? addr['full_name'] 
                          : addr['name'] ?? 'Address';
                          
                      String addressText = '';
                      if (addr['flat_house_building'] != null && addr['flat_house_building'].isNotEmpty) {
                        addressText = '${addr['flat_house_building']}, ${addr['area_street_sector']}';
                      } else {
                        addressText = addr['address_line'] ?? '';
                      }
                      
                      final city = addr['town_city'] ?? addr['city'] ?? '';
                      final state = addr['state'] ?? '';
                      final pincode = addr['pincode'] ?? '';
                      
                      String subtitle = addressText;
                      if (city.isNotEmpty || state.isNotEmpty || pincode.isNotEmpty) {
                        subtitle += "\n$city${city.isNotEmpty && state.isNotEmpty ? ', ' : ''}$state${(city.isNotEmpty || state.isNotEmpty) && pincode.isNotEmpty ? ' - ' : ''}$pincode";
                      }
                      if (addr['mobile_number'] != null && addr['mobile_number'].toString().isNotEmpty) {
                        subtitle += "\n${addr['mobile_number']}";
                      }
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            RadioListTile<dynamic>(
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(subtitle),
                              value: addr,
                              groupValue: _selectedAddress,
                              onChanged: (val) => setState(() => _selectedAddress = val),
                              activeColor: Colors.green,
                            ),
                            if (addr['id'] != 'profile') 
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit'),
                                      onPressed: () => _editAddress(addr),
                                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      icon: const Icon(Icons.delete, size: 16),
                                      label: const Text('Delete'),
                                      onPressed: () => _deleteAddress(addr),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                  }).toList(),
                  
                  const SizedBox(height: 24),
                  const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Cash on Delivery (COD)'),
                    value: 'COD',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val),
                  ),
                  RadioListTile<String>(
                    title: const Text('Online Payment (Razorpay)'),
                    value: 'Online',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Place Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
