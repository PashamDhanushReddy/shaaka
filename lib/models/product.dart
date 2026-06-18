class ProductImage {
  final int id;
  final String imageUrl;

  ProductImage({required this.id, required this.imageUrl});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      imageUrl: json['image_url'],
    );
  }
}

class ProductReview {
  final int id;
  final int userId;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ProductReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'],
      userId: json['user'],
      userName: json['user_name'] ?? 'Anonymous',
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ProductVariant {
  final int id;
  final double quantity;
  final String unit;
  final double price;
  final double stockQuantity;

  ProductVariant({
    required this.id,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.stockQuantity,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'],
      quantity: double.tryParse(json['quantity'].toString()) ?? 0.0,
      unit: json['unit'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      stockQuantity: double.tryParse(json['stock_quantity'].toString()) ?? 0.0,
    );
  }
}

class Product {
  final int id;
  final int vendorId;
  final String vendorName;
  final String name;
  final String? description;
  final String category;
  final double price;
  final String unit;
  final double stockQuantity;
  final double averageRating;
  final int ratingCount;
  final List<ProductImage> images;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.stockQuantity,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.images = const [],
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['id'].toString()) ?? 0,
      vendorId: int.tryParse(json['vendor'].toString()) ?? 0,
      vendorName: json['vendor_name'] ?? 'Unknown Vendor',
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      unit: json['unit'] ?? '',
      stockQuantity: double.tryParse(json['stock_quantity'].toString()) ?? 0.0,
      averageRating: double.tryParse(json['average_rating'].toString()) ?? 0.0,
      ratingCount: int.tryParse(json['rating_count'].toString()) ?? 0,
      images: (json['images'] as List?)
              ?.map((i) => ProductImage.fromJson(i))
              .toList() ??
          [],
      variants: (json['variants'] as List?)
              ?.map((v) => ProductVariant.fromJson(v))
              .toList() ??
          [],
    );
  }
  
  String? get firstImageUrl => images.isNotEmpty ? images.first.imageUrl : null;
}
