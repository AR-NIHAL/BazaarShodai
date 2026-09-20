/// Domain model representing a single line item in the shopping cart.
class CartItemModel {
  final String productId;
  final String title;
  final String image;
  final double price;
  final double? originalPrice;
  final int quantity;
  final String unit;
  final String sellerId;
  final String sellerName;
  final int stock;

  const CartItemModel({
    required this.productId,
    required this.title,
    required this.image,
    required this.price,
    this.originalPrice,
    required this.quantity,
    this.unit = '1 kg',
    required this.sellerId,
    required this.sellerName,
    this.stock = 999,
  });

  /// Total price for this line item (effective unit price * quantity)
  double get totalPrice => price * quantity;

  /// Original price total before discounts
  double get totalOriginalPrice => (originalPrice ?? price) * quantity;

  /// Total savings on this line item
  double get savings => hasDiscount ? (originalPrice! - price) * quantity : 0.0;

  /// True if the item is currently on a discount
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  CartItemModel copyWith({
    String? productId,
    String? title,
    String? image,
    double? price,
    double? originalPrice,
    int? quantity,
    String? unit,
    String? sellerId,
    String? sellerName,
    int? stock,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      title: title ?? this.title,
      image: image ?? this.image,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      stock: stock ?? this.stock,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'image': image,
      'price': price,
      'originalPrice': originalPrice,
      'quantity': quantity,
      'unit': unit,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'stock': stock,
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: map['productId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      image: map['image'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unit: map['unit'] as String? ?? '1 kg',
      sellerId: map['sellerId'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? 'Verified Vendor',
      stock: (map['stock'] as num?)?.toInt() ?? 999,
    );
  }
}
