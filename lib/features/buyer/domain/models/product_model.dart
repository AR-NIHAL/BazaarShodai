import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a selectable weight or package tier for a product.
class ProductWeightOption {
  final String label; // e.g. "1.0 - 1.2 kg", "500 gm", "2 kg"
  final String? tag; // e.g. "POPULAR", "JUMBO", "MEDIUM", "BEST VALUE"
  final double price; // specific price for this tier
  final String? subtitle; // e.g. "Approx. weight per piece" or "Save 10%"

  const ProductWeightOption({
    required this.label,
    this.tag,
    required this.price,
    this.subtitle,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        if (tag != null) 'tag': tag,
        'price': price,
        if (subtitle != null) 'subtitle': subtitle,
      };

  factory ProductWeightOption.fromMap(Map<String, dynamic> map) {
    return ProductWeightOption(
      label: map['label'] as String? ?? '',
      tag: map['tag'] as String?,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      subtitle: map['subtitle'] as String?,
    );
  }
}

/// Domain entity representing a product in BazaarShodai's marketplace.
class ProductModel {
  final String id;
  final String title;
  final String? bengaliTitle;
  final String description;
  final double price;
  final double? originalPrice;
  final int stock;
  final String category;
  final String unit;
  final List<String> imageUrls;
  final String? videoUrl;
  final String? origin;
  final String? harvestTime;
  final String sellerId;
  final String sellerName;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final List<ProductWeightOption>? weightOptions;
  final List<String>? cutOptions;
  final String? labCertificateId;
  final String? farmerExperience;
  final String? farmerQuote;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.title,
    this.bengaliTitle,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.stock,
    required this.category,
    this.unit = '1 kg',
    required this.imageUrls,
    this.videoUrl,
    this.origin,
    this.harvestTime,
    required this.sellerId,
    required this.sellerName,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFeatured = false,
    this.weightOptions,
    this.cutOptions,
    this.labCertificateId,
    this.farmerExperience,
    this.farmerQuote,
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

  /// Dynamic fallback for Bengali title if not stored in Firestore
  String get effectiveBengaliTitle {
    if (bengaliTitle != null && bengaliTitle!.trim().isNotEmpty) {
      return bengaliTitle!;
    }
    final lower = title.toLowerCase();
    if (lower.contains('hilsa') || lower.contains('ইলিশ')) {
      return 'তাজা পদ্মা নদীর রূপালী ইলিশ';
    }
    if (lower.contains('tomato') || lower.contains('টমেটো')) {
      return 'দেশি টাটকা লাল টমেটো';
    }
    if (lower.contains('mustard') || lower.contains('সরিষা')) {
      return 'খাঁটি ঘানি ভাঙা সরিষার তেল';
    }
    if (lower.contains('egg') || lower.contains('ডিম')) {
      return 'খামারের তাজা দেশি মুরগির ডিম';
    }
    return 'টাটকা স্থানীয় খাদ্যপণ্য';
  }

  /// Dynamic fallback for origin & harvest region
  String get effectiveOrigin {
    if (origin != null && origin!.trim().isNotEmpty) return origin!;
    final cat = category.toLowerCase();
    if (cat.contains('fish')) return 'Padma Direct · Chandpur Mohona Confluence';
    if (cat.contains('veg')) return 'Bogura Organic Farm · Jessore Direct';
    if (cat.contains('oil') || cat.contains('spice')) {
      return 'Sirajganj Mustard Fields · Ghani Cold-Press';
    }
    if (cat.contains('egg') || cat.contains('dairy')) {
      return 'Narsingdi Free-Range Farm';
    }
    return '$sellerName Direct Harvest';
  }

  /// Category-smart selectable weight options
  List<ProductWeightOption> get effectiveWeightOptions {
    if (weightOptions != null && weightOptions!.isNotEmpty) {
      return weightOptions!;
    }
    final cat = category.toLowerCase();
    if (cat.contains('fish') || cat.contains('meat')) {
      return [
        ProductWeightOption(
          label: '1.0 - 1.2 kg',
          tag: 'POPULAR',
          price: price,
          subtitle: 'Approx. weight per piece',
        ),
        ProductWeightOption(
          label: '1.3 - 1.5 kg',
          tag: 'JUMBO',
          price: (price * 1.3).roundToDouble(),
          subtitle: 'Large family size',
        ),
        ProductWeightOption(
          label: '800 - 950 g',
          tag: 'MEDIUM',
          price: (price * 0.82).roundToDouble(),
          subtitle: 'Medium portion',
        ),
      ];
    } else if (cat.contains('veg') || cat.contains('fruit')) {
      return [
        ProductWeightOption(
          label: '500 gm',
          tag: 'HALF',
          price: (price * 0.52).roundToDouble(),
          subtitle: 'Trial / Single Meal',
        ),
        ProductWeightOption(
          label: '1 kg',
          tag: 'POPULAR',
          price: price,
          subtitle: 'Daily Standard Pack',
        ),
        ProductWeightOption(
          label: '2 kg',
          tag: 'FAMILY',
          price: (price * 1.95).roundToDouble(),
          subtitle: 'Family Size · Save 5%',
        ),
        ProductWeightOption(
          label: '5 kg',
          tag: 'BULK',
          price: (price * 4.6).roundToDouble(),
          subtitle: 'Farm Sack · Save 10%',
        ),
      ];
    } else if (cat.contains('spice') || cat.contains('oil')) {
      return [
        ProductWeightOption(label: '250 ml', price: (price * 0.3).roundToDouble()),
        ProductWeightOption(
          label: '500 ml',
          tag: 'POPULAR',
          price: (price * 0.55).roundToDouble(),
        ),
        ProductWeightOption(label: '1 Litre', tag: 'SAVER', price: price),
        ProductWeightOption(
          label: '5 Litre',
          tag: 'BULK',
          price: (price * 4.7).roundToDouble(),
        ),
      ];
    } else if (cat.contains('dairy') || cat.contains('egg')) {
      if (title.toLowerCase().contains('egg') || unit.toLowerCase().contains('pc')) {
        return [
          ProductWeightOption(label: '6 pcs', price: (price * 0.52).roundToDouble()),
          ProductWeightOption(label: '12 pcs pack', tag: 'POPULAR', price: price),
          ProductWeightOption(
            label: '24 pcs crate',
            tag: 'SAVER',
            price: (price * 1.9).roundToDouble(),
          ),
        ];
      }
      return [
        ProductWeightOption(label: '500 ml', price: (price * 0.55).roundToDouble()),
        ProductWeightOption(label: '1 Litre', tag: 'POPULAR', price: price),
        ProductWeightOption(label: '2 Litre', tag: 'SAVER', price: (price * 1.9).roundToDouble()),
      ];
    }
    return [
      ProductWeightOption(label: unit.isNotEmpty ? unit : '1 kg', price: price),
    ];
  }

  /// Category-smart custom preparation/cut options
  List<String> get effectiveCutOptions {
    if (cutOptions != null && cutOptions!.isNotEmpty) {
      return cutOptions!;
    }
    final cat = category.toLowerCase();
    if (cat.contains('fish') || cat.contains('meat')) {
      return const [
        'Whole Fish (আস্ত মাছ - Uncut)',
        'Curry Cut (মাছের টুকরো - Cleaned)',
        'Head + Fish Steaks (পেটি ও গদা আলাদা)',
      ];
    } else if (cat.contains('veg') || cat.contains('fruit')) {
      return const [
        'Whole Fresh (স্বাভাবিক আস্ত)',
        'Pre-Cleaned & Sorted (বাছাইকৃত ও ধোয়া)',
      ];
    } else if (cat.contains('spice') || cat.contains('oil')) {
      return const [
        'Cold-Pressed (ঘানি ভাঙা)',
        'Traditional Pure (খাঁটি কাঁচা)',
      ];
    }
    return const [];
  }

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
    final int parsedReviewCount =
        (rawReviewCount is num) ? rawReviewCount.toInt() : 0;

    List<String> parsedImageUrls = [];
    if (map['imageUrls'] != null && map['imageUrls'] is List) {
      parsedImageUrls = List<String>.from(
        (map['imageUrls'] as List).map((e) => e.toString()),
      );
    }

    List<ProductWeightOption>? parsedWeightOptions;
    if (map['weightOptions'] != null && map['weightOptions'] is List) {
      parsedWeightOptions = (map['weightOptions'] as List)
          .map((e) => ProductWeightOption.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    List<String>? parsedCutOptions;
    if (map['cutOptions'] != null && map['cutOptions'] is List) {
      parsedCutOptions = List<String>.from(
        (map['cutOptions'] as List).map((e) => e.toString()),
      );
    }

    return ProductModel(
      id: documentId ?? (map['id'] as String? ?? ''),
      title: map['title'] as String? ?? '',
      bengaliTitle: map['bengaliTitle'] as String?,
      description: map['description'] as String? ?? '',
      price: parsedPrice,
      originalPrice: parsedOriginalPrice,
      stock: parsedStock,
      category: map['category'] as String? ?? '',
      unit: map['unit'] as String? ?? '1 kg',
      imageUrls: parsedImageUrls,
      videoUrl: map['videoUrl'] as String?,
      origin: map['origin'] as String?,
      harvestTime: map['harvestTime'] as String?,
      sellerId: map['sellerId'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? '',
      rating: parsedRating,
      reviewCount: parsedReviewCount,
      isFeatured: map['isFeatured'] as bool? ?? false,
      weightOptions: parsedWeightOptions,
      cutOptions: parsedCutOptions,
      labCertificateId: map['labCertificateId'] as String?,
      farmerExperience: map['farmerExperience'] as String?,
      farmerQuote: map['farmerQuote'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      if (bengaliTitle != null) 'bengaliTitle': bengaliTitle,
      'description': description,
      'price': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'stock': stock,
      'category': category,
      'unit': unit,
      'imageUrls': imageUrls,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (origin != null) 'origin': origin,
      if (harvestTime != null) 'harvestTime': harvestTime,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
      if (weightOptions != null)
        'weightOptions': weightOptions!.map((o) => o.toMap()).toList(),
      if (cutOptions != null) 'cutOptions': cutOptions,
      if (labCertificateId != null) 'labCertificateId': labCertificateId,
      if (farmerExperience != null) 'farmerExperience': farmerExperience,
      if (farmerQuote != null) 'farmerQuote': farmerQuote,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  ProductModel copyWith({
    String? id,
    String? title,
    String? bengaliTitle,
    String? description,
    double? price,
    double? originalPrice,
    int? stock,
    String? category,
    String? unit,
    List<String>? imageUrls,
    String? videoUrl,
    String? origin,
    String? harvestTime,
    String? sellerId,
    String? sellerName,
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    List<ProductWeightOption>? weightOptions,
    List<String>? cutOptions,
    String? labCertificateId,
    String? farmerExperience,
    String? farmerQuote,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      bengaliTitle: bengaliTitle ?? this.bengaliTitle,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      origin: origin ?? this.origin,
      harvestTime: harvestTime ?? this.harvestTime,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      weightOptions: weightOptions ?? this.weightOptions,
      cutOptions: cutOptions ?? this.cutOptions,
      labCertificateId: labCertificateId ?? this.labCertificateId,
      farmerExperience: farmerExperience ?? this.farmerExperience,
      farmerQuote: farmerQuote ?? this.farmerQuote,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel &&
        other.id == id &&
        other.title == title &&
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
