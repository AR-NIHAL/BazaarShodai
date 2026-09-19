import 'package:bazaar_shodai/features/auth/domain/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserModel Serialization & Domain Logic', () {
    test('UserRole helper properties work correctly', () {
      expect(UserRole.customer.isCustomer, isTrue);
      expect(UserRole.customer.isSeller, isFalse);

      expect(UserRole.seller.isSeller, isTrue);
      expect(UserRole.seller.isCustomer, isFalse);

      expect(UserRole.fromString('seller'), equals(UserRole.seller));
      expect(UserRole.fromString('customer'), equals(UserRole.customer));
      expect(UserRole.fromString('unknown_role'), equals(UserRole.customer));
    });

    test('ShopDetails serialization and copyWith', () {
      const shop = ShopDetails(
        shopName: 'Fresh Bazar Dhanmondi',
        phone: '+8801700000000',
        address: 'Road 27, Dhanmondi, Dhaka',
      );

      final map = shop.toMap();
      expect(map['shopName'], 'Fresh Bazar Dhanmondi');
      expect(map['phone'], '+8801700000000');
      expect(map['address'], 'Road 27, Dhanmondi, Dhaka');

      final deserialized = ShopDetails.fromMap(map);
      expect(deserialized, equals(shop));

      final updated = shop.copyWith(shopName: 'Bazaar Shodai Hub');
      expect(updated.shopName, 'Bazaar Shodai Hub');
      expect(updated.phone, '+8801700000000');
    });

    test('UserModel serialization with default customer role', () {
      final now = DateTime(2026, 9, 18, 12, 0, 0);
      final user = UserModel(
        uid: 'test_uid_123',
        email: 'buyer@bazaarshodai.com',
        name: 'Rahim Ahmed',
        role: UserRole.customer,
        isApproved: true,
        createdAt: now,
      );

      final map = user.toMap();
      expect(map['uid'], 'test_uid_123');
      expect(map['email'], 'buyer@bazaarshodai.com');
      expect(map['name'], 'Rahim Ahmed');
      expect(map['role'], 'customer');
      expect(map['isApproved'], isTrue);
      expect(map['shopDetails'], isNull);
      expect(map['createdAt'], isA<Timestamp>());

      final deserialized = UserModel.fromMap(map);
      expect(deserialized.uid, 'test_uid_123');
      expect(deserialized.email, 'buyer@bazaarshodai.com');
      expect(deserialized.role, UserRole.customer);
      expect(deserialized.isApproved, isTrue);
      expect(deserialized.shopDetails, isNull);
      expect(deserialized.createdAt, equals(now));
    });

    test('UserModel serialization with seller role and shop details', () {
      const shop = ShopDetails(
        shopName: 'Karwan Bazar Fresh Produce',
        phone: '+8801811111111',
        address: 'Karwan Bazar, Dhaka',
      );

      const seller = UserModel(
        uid: 'seller_uid_456',
        email: 'seller@bazaarshodai.com',
        name: 'Karim Ullah',
        role: UserRole.seller,
        isApproved: false, // Pending admin approval
        shopDetails: shop,
      );

      final map = seller.toMap();
      expect(map['role'], 'seller');
      expect(map['isApproved'], isFalse);
      expect(map['shopDetails'], isA<Map<String, dynamic>>());
      expect(map['shopDetails']['shopName'], 'Karwan Bazar Fresh Produce');

      final deserialized = UserModel.fromMap(map);
      expect(deserialized.role, UserRole.seller);
      expect(deserialized.isApproved, isFalse);
      expect(deserialized.shopDetails, equals(shop));
    });

    test('UserModel copyWith works properly', () {
      const user = UserModel(
        uid: 'user_1',
        email: 'user1@test.com',
        name: 'Original Name',
        role: UserRole.customer,
      );

      final updated = user.copyWith(
        name: 'Updated Name',
        role: UserRole.seller,
        isApproved: false,
      );

      expect(updated.uid, 'user_1');
      expect(updated.name, 'Updated Name');
      expect(updated.role, UserRole.seller);
      expect(updated.isApproved, isFalse);
    });
  });
}
