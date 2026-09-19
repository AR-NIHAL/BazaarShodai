import 'package:bazaar_shodai/features/buyer/domain/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Seller Product Upload & Verification', () {
    test('Constructs published vendor product with Cloudinary image and seller metadata', () {
      final now = DateTime.now();
      final product = ProductModel(
        id: 'seller_prod_101',
        title: 'Bogra Organic Cauliflower',
        description: 'Naturally grown organic cauliflower freshly harvested this morning.',
        price: 45.0,
        originalPrice: 55.0,
        stock: 30,
        category: 'Vegetables',
        imageUrls: const ['https://res.cloudinary.com/dkmv1b5z0/image/upload/v1234/cauliflower.jpg'],
        sellerId: 'vendor_uid_999',
        sellerName: 'Bogra Fresh Mart',
        rating: 5.0,
        reviewCount: 0,
        isFeatured: false,
        createdAt: now,
      );

      expect(product.id, equals('seller_prod_101'));
      expect(product.sellerId, equals('vendor_uid_999'));
      expect(product.sellerName, equals('Bogra Fresh Mart'));
      expect(product.primaryImage, contains('res.cloudinary.com'));
      expect(product.hasDiscount, isTrue);
      expect(product.discountPercentage, equals(18));
      expect(product.isOutOfStock, isFalse);

      final map = product.toMap();
      expect(map['sellerId'], equals('vendor_uid_999'));
      expect(map['sellerName'], equals('Bogra Fresh Mart'));
      expect(map['stock'], equals(30));

      final fromMap = ProductModel.fromMap(map, documentId: 'seller_prod_101');
      expect(fromMap.sellerId, equals('vendor_uid_999'));
      expect(fromMap.sellerName, equals('Bogra Fresh Mart'));
      expect(fromMap.primaryImage, equals(product.primaryImage));
    });
  });
}
