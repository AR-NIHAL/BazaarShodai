import 'package:cloud_firestore/cloud_firestore.dart';

/// Domain entity representing a product in BazaarShodai's marketplace.
class ProductModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final double? originalPrice;
  final int stock;
  final String category;
  final String unit;
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.stock,
    required this.category,
    this.unit = '1 kg',
    required this.imageUrls,
    required this.sellerId,
    required this.sellerName,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFeatured = false,
    this.createdAt,
  });

  /// Check if the product has a valid promotional discount.
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  /// Calculate discount percentage rounded to nearest integer.
  int get discountPercentage {
    if (!hasDiscount || originalPrice == null || originalPrice == 0) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  /// Whether this product is currently out of stock.
  bool get isOutOfStock => stock <= 0;

  /// Returns the primary display image URL, or an empty string if none provided.
  String get primaryImage => imageUrls.isNotEmpty ? imageUrls.first : '';

  factory ProductModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    }

    final rawPrice = map['price'];
    final double parsedPrice = (rawPrice is num) ? rawPrice.toDouble() : 0.0;

    final rawOriginalPrice = map['originalPrice'];
    final double? parsedOriginalPrice =
        (rawOriginalPrice is num) ? rawOriginalPrice.toDouble() : null;

    final rawStock = map['stock'];
    final int parsedStock = (rawStock is num) ? rawStock.toInt() : 0;

    final rawRating = map['rating'];
    final double parsedRating = (rawRating is num) ? rawRating.toDouble() : 0.0;

    final rawReviewCount = map['reviewCount'];
    final int parsedReviewCount = (rawReviewCount is num) ? rawReviewCount.toInt() : 0;

    List<String> parsedImageUrls = [];
    if (map['imageUrls'] != null && map['imageUrls'] is List) {
      parsedImageUrls = List<String>.from(
        (map['imageUrls'] as List).map((e) => e.toString()),
      );
    }

    return ProductModel(
      id: documentId ?? (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: parsedPrice,
      originalPrice: parsedOriginalPrice,
      stock: parsedStock,
      category: map['category'] as String? ?? '',
      unit: map['unit'] as String? ?? '1 kg',
      imageUrls: parsedImageUrls,
      sellerId: map['sellerId'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? '',
      rating: parsedRating,
      reviewCount: parsedReviewCount,
      isFeatured: map['isFeatured'] as bool? ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'stock': stock,
      'category': category,
      'unit': unit,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? originalPrice,
    int? stock,
    String? category,
    String? unit,
    List<String>? imageUrls,
    String? sellerId,
    String? sellerName,
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.price == price &&
        other.originalPrice == originalPrice &&
        other.stock == stock &&
        other.category == category &&
        other.unit == unit &&
        other.sellerId == sellerId &&
        other.sellerName == sellerName &&
        other.rating == rating &&
        other.reviewCount == reviewCount &&
        other.isFeatured == isFeatured;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      price.hashCode ^
      stock.hashCode ^
      category.hashCode ^
      unit.hashCode ^
      sellerId.hashCode;

  @override
  String toString() =>
      'ProductModel(id: $id, title: $title, price: $price, originalPrice: $originalPrice, stock: $stock, category: $category, unit: $unit)';
}
