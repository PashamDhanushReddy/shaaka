import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/user_profile.dart';
import '../models/product.dart';
import '../models/cart_order_models.dart';
import 'cart_service.dart';

class ApiService {
  /// Base URL for the production Render backend.
  static const String baseUrl = 'https://shaaka-33pq.onrender.com/api';
  // For production: static const String baseUrl = 'https://your-backend.onrender.com/api';

  /// Requests an OTP code to be sent to the given [mobileNumber].
  /// Returns a Map containing a 'success' boolean and 'data'/'error' information.
  static Future<Map<String, dynamic>> requestOTP(String mobileNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile_number': mobileNumber}),
      );

      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Verifies the [otpCode] provided by the user for the given [mobileNumber].
  /// On success, this typically returns user status or session data.
  static Future<Map<String, dynamic>> verifyOTP(
      String mobileNumber, String otpCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile_number': mobileNumber,
          'otp_code': otpCode,
        }),
      );

      return {
        'success': response.statusCode == 200,
        'data': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Registers a new user with the provided [userData].
  /// The [userData] map should contain required registration fields (e.g., name, mobile, password).
  static Future<Map<String, dynamic>> register(
      Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': UserProfile.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Authenticates an existing user using their [mobileNumber] and [password].
  /// On success, returns the `UserProfile` data.
  static Future<Map<String, dynamic>> login(
      String mobileNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile_number': mobileNumber,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': UserProfile.fromJson(data['user']),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/$userId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': UserProfile.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> uploadImage(XFile imageFile, {String type = 'profile'}) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/image/'),
      );

      final bytes = await imageFile.readAsBytes();
      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
      request.fields['type'] = type;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['url'],
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
      int userId, Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/$userId/update/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': UserProfile.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> changePassword(
      int userId, String currentPassword, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/$userId/change-password/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> addProduct(Map<String, dynamic> productData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': Product.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> updateProduct(int productId, Map<String, dynamic> productData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/$productId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(productData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Product.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$productId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to delete product',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getProducts({String? query, String? ordering, int? limit}) async {
    try {
      String url = '$baseUrl/products/';
      Map<String, String> queryParams = {};
      
      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }
      if (ordering != null) {
        queryParams['ordering'] = ordering;
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Product> products = data.map((json) => Product.fromJson(json)).toList();
        
        if (limit != null && products.length > limit) {
          products = products.sublist(0, limit);
        }
        
        return {
          'success': true,
          'data': products,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getVendorProducts(int vendorId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/vendor/$vendorId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final products = data.map((json) => Product.fromJson(json)).toList();
        return {
          'success': true,
          'data': products,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getProductDetails(int productId) async {
      try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Product.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }


  static Future<Map<String, dynamic>> getProductReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/reviews/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final reviews = data.map((json) => ProductReview.fromJson(json)).toList();
        return {
          'success': true,
          'data': reviews,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> addReview(int productId, Map<String, dynamic> reviewData) async {
     try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/$productId/reviews/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reviewData),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': ProductReview.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> updateReview(int reviewId, Map<String, dynamic> reviewData) async {
     try {
      final response = await http.put(
        Uri.parse('$baseUrl/reviews/$reviewId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reviewData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': ProductReview.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> deleteReview(int reviewId) async {
     try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/$reviewId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to delete review',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getCart(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart/$userId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final cart = Cart.fromJson(jsonDecode(response.body));
        CartService.updateCount(cart.items.length);
        return {
          'success': true,
          'data': cart,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> addToCart(int userId, int productId, double unitValue, {int quantity = 1}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/$userId/add/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': productId,
          'quantity': quantity,
          'unit_value': unitValue,
        }),
      );

      if (response.statusCode == 200) {
        final cart = Cart.fromJson(jsonDecode(response.body));
        CartService.updateCount(cart.items.length);
        return {
          'success': true,
          'data': cart,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> updateCartItem(int userId, int itemId, double quantity) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cart/$userId/update/$itemId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final cart = Cart.fromJson(jsonDecode(response.body));
        CartService.updateCount(cart.items.length);
        return {
          'success': true,
          'data': cart,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> removeFromCart(int userId, int itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$userId/remove/$itemId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final cart = Cart.fromJson(jsonDecode(response.body));
        CartService.updateCount(cart.items.length);
        return {
          'success': true,
          'data': cart,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> clearCart(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$userId/clear/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final cart = Cart.fromJson(jsonDecode(response.body));
        CartService.updateCount(cart.items.length);
        return {
          'success': true,
          'data': cart,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }


  static Future<Map<String, dynamic>> placeOrder(int userId, Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$userId/place/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': Order.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> placeDirectOrder(int userId, Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$userId/place_direct/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': Order.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getOrders(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$userId/list/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final orders = data.map((json) => Order.fromJson(json)).toList();
        return {
          'success': true,
          'data': orders,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/detail/$orderId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Order.fromJson(jsonDecode(response.body)),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> cancelOrder(int userId, int orderId, {String reason = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$userId/cancel/$orderId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );

      dynamic decodedBody;
      try {
        decodedBody = jsonDecode(response.body);
      } catch (e) {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}. (The API might still be deploying)',
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': Order.fromJson(decodedBody),
        };
      } else {
        return {
          'success': false,
          'error': decodedBody,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getAutoScrollImages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/auto-scroll-images/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }


  static Future<Map<String, dynamic>> getUserAddresses(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/addresses/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> addUserAddress(int userId, Map<String, dynamic> addressData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/addresses/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(addressData),
      );

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserAddress(int userId, int addressId, Map<String, dynamic> addressData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(addressData),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> deleteUserAddress(int userId, int addressId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204) {
        return {
          'success': true,
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to delete address',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }


  static Future<Map<String, dynamic>> createDonation(
      int userId, Map<String, String> fields, XFile? image) async {
    try {
      final uri = Uri.parse('$baseUrl/donations/create/$userId/');
      final request = http.MultipartRequest('POST', uri);

      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      if (image != null) {
        String fieldName = 'item_image'; // Default
        if (fields['donation_type'] == 'Money') {
          fieldName = 'payment_screenshot';
        }
        
        request.files.add(
          await http.MultipartFile.fromPath(
            fieldName,
            image.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }


  static Future<Map<String, dynamic>> getWishlist(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/$userId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final products = data.map((json) => Product.fromJson(json)).toList();
        return {
          'success': true,
          'data': products,
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> toggleWishlist(int userId, int productId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist/toggle/$userId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'product_id': productId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> checkWishlist(int userId, int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/check/$userId/$productId/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

}
