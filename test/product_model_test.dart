import 'package:bazaar_shodai/features/buyer/domain/models/category_model.dart';
import 'package:bazaar_shodai/features/buyer/domain/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductModel Domain Logic & Serialization', () {
    test('Calculates discount percentage and discount status correctly', () {
      final productWithDiscount = ProductModel(
        id: 'prod_1',
        title: 'Fresh Tomato 1kg',
        description: 'Harvested from Bogura',
        price: 60.0,
        originalPrice: 80.0,
        stock: 20,
        category: 'Vegetables',
        imageUrls: const ['https://example.com/tomato.jpg'],
        sellerId: 'seller_1',
        sellerName: 'Green Valley Organics',
      );

      expect(productWithDiscount.hasDiscount, isTrue);
      expect(productWithDiscount.discountPercentage, equals(25));
      expect(productWithDiscount.isOutOfStock, isFalse);
      expect(productWithDiscount.primaryImage, equals('https://example.com/tomato.jpg'));

      final productWithoutDiscount = ProductModel(
        id: 'prod_2',
        title: 'Fresh Tomato 1kg',
        description: 'Harvested from Bogura',
        price: 60.0,
        originalPrice: null,
        stock: 20,
        category: 'Vegetables',
        imageUrls: const ['https://example.com/tomato.jpg'],
        sellerId: 'seller_1',
        sellerName: 'Green Valley Organics',
      );
      expect(productWithoutDiscount.hasDiscount, isFalse);
      expect(productWithoutDiscount.discountPercentage, equals(0));

      final outOfStockProduct = productWithDiscount.copyWith(stock: 0);
      expect(outOfStockProduct.isOutOfStock, isTrue);
    });

    test('Serializes to map and deserializes correctly with Timestamp', () {
      final now = DateTime(2026, 9, 19, 10, 30, 0);
      final product = ProductModel(
        id: 'prod_tomato_01',
        title: 'Organic Red Tomato 1kg',
        description: 'Farm fresh red tomatoes',
        price: 65.0,
        originalPrice: 80.0,
        stock: 45,
        category: 'Vegetables',
        imageUrls: const ['https://example.com/tomato.jpg', 'https://example.com/tomato2.jpg'],
        sellerId: 'seller_01',
        sellerName: 'Green Valley Organics',
        rating: 4.8,
        reviewCount: 24,
        isFeatured: true,
        createdAt: now,
      );

      final map = product.toMap();
      expect(map['id'], 'prod_tomato_01');
      expect(map['price'], 65.0);
      expect(map['originalPrice'], 80.0);
      expect(map['isFeatured'], isTrue);
      expect(map['createdAt'], isA<Timestamp>());

      final deserialized = ProductModel.fromMap(map, documentId: 'prod_tomato_01');
      expect(deserialized.id, 'prod_tomato_01');
      expect(deserialized.title, 'Organic Red Tomato 1kg');
      expect(deserialized.price, 65.0);
      expect(deserialized.originalPrice, 80.0);
      expect(deserialized.stock, 45);
      expect(deserialized.category, 'Vegetables');
      expect(deserialized.imageUrls.length, 2);
      expect(deserialized.sellerName, 'Green Valley Organics');
      expect(deserialized.rating, 4.8);
      expect(deserialized.reviewCount, 24);
      expect(deserialized.isFeatured, isTrue);
      expect(deserialized.createdAt, equals(now));
    });

    test('Handles int prices gracefully in fromMap', () {
      final rawMap = {
        'id': 'raw_prod',
        'title': 'Test Item',
        'description': 'Description',
        'price': 100, // integer price from JSON
        'originalPrice': 120, // integer original price
        'stock': 10,
        'category': 'Fruits',
        'imageUrls': ['https://example.com/fruit.jpg'],
        'sellerId': 'seller_02',
        'sellerName': 'Fruit Mart',
        'rating': 5, // int rating
        'reviewCount': 8,
        'isFeatured': false,
      };

      final product = ProductModel.fromMap(rawMap);
      expect(product.price, equals(100.0));
      expect(product.originalPrice, equals(120.0));
      expect(product.rating, equals(5.0));
      expect(product.discountPercentage, equals(17));
    });
  });

  group('CategoryModel Domain Logic & Serialization', () {
    test('Serializes to map and deserializes correctly', () {
      const category = CategoryModel(
        id: 'cat_vegetables',
        name: 'Vegetables',
        icon: 'eco',
        imageUrl: 'https://example.com/veg.jpg',
      );

      final map = category.toMap();
      expect(map['id'], 'cat_vegetables');
      expect(map['name'], 'Vegetables');
      expect(map['icon'], 'eco');

      final deserialized = CategoryModel.fromMap(map);
      expect(deserialized, equals(category));
      expect(deserialized.name, 'Vegetables');
      expect(deserialized.icon, 'eco');
    });
  });
}
