import 'package:bazaar_shodai/features/cart/domain/models/cart_item_model.dart';
import 'package:bazaar_shodai/features/checkout/domain/models/address_model.dart';
import 'package:bazaar_shodai/features/order/data/repositories/order_repository_impl.dart';
import 'package:bazaar_shodai/features/order/domain/models/order_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OrderStatus Enum', () {
    test('Correct step indices and display labels', () {
      expect(OrderStatus.placed.stepIndex, equals(0));
      expect(OrderStatus.confirmed.stepIndex, equals(1));
      expect(OrderStatus.outForDelivery.stepIndex, equals(2));
      expect(OrderStatus.delivered.stepIndex, equals(3));
      expect(OrderStatus.cancelled.stepIndex, equals(-1));

      expect(OrderStatus.placed.displayName, equals('Order Placed'));
      expect(OrderStatus.confirmed.displayName, equals('Confirmed & Packing'));
      expect(OrderStatus.outForDelivery.displayName, equals('Out for Delivery'));
      expect(OrderStatus.delivered.displayName, equals('Delivered'));
      expect(OrderStatus.cancelled.displayName, equals('Cancelled'));
    });
  });

  group('OrderModel Domain Logic & Serialization', () {
    final testAddress = const AddressModel(
      id: 'addr_test',
      userId: 'user_1',
      recipientName: 'Ariful Islam',
      phoneNumber: '01700000000',
      street: 'House 5, Road 2',
      area: 'Dhanmondi',
    );

    final testItems = [
      const CartItemModel(
        productId: 'prod_1',
        title: 'Fresh Cauliflower',
        image: 'https://example.com/cauliflower.jpg',
        price: 45.0,
        quantity: 2,
        sellerId: 'seller_1',
        sellerName: 'Green Farm',
      ),
      const CartItemModel(
        productId: 'prod_2',
        title: 'Organic Red Tomato',
        image: 'https://example.com/tomato.jpg',
        price: 60.0,
        quantity: 1,
        sellerId: 'seller_2',
        sellerName: 'Krishok Hub',
      ),
    ];

    test('Computes totalItemCount, isActive, and isDelivered accurately', () {
      final activeOrder = OrderModel(
        id: 'BS-1001',
        buyerId: 'user_1',
        buyerName: 'Ariful Islam',
        buyerPhone: '01700000000',
        deliveryAddress: testAddress,
        items: testItems,
        vendorIds: const ['seller_1', 'seller_2'],
        subtotal: 150.0,
        deliveryFee: 50.0,
        discount: 0.0,
        totalAmount: 200.0,
        paymentMethod: 'Cash on Delivery',
        deliveryDate: 'Today',
        deliverySlot: 'Morning Fresh',
        status: OrderStatus.placed,
        createdAt: DateTime(2026, 9, 20, 10, 0),
      );

      expect(activeOrder.totalItemCount, equals(3)); // 2 cauliflower + 1 tomato
      expect(activeOrder.isActive, isTrue);
      expect(activeOrder.isDelivered, isFalse);

      final deliveredOrder = activeOrder.copyWith(status: OrderStatus.delivered);
      expect(deliveredOrder.isActive, isFalse);
      expect(deliveredOrder.isDelivered, isTrue);

      final cancelledOrder = activeOrder.copyWith(status: OrderStatus.cancelled);
      expect(cancelledOrder.isActive, isFalse);
      expect(cancelledOrder.isDelivered, isFalse);
    });

    test('Serializes to map and deserializes without data loss', () {
      final order = OrderModel(
        id: 'BS-2002',
        buyerId: 'user_1',
        buyerName: 'Ariful Islam',
        buyerPhone: '01700000000',
        deliveryAddress: testAddress,
        items: testItems,
        vendorIds: const ['seller_1', 'seller_2'],
        subtotal: 150.0,
        deliveryFee: 50.0,
        discount: 10.0,
        totalAmount: 190.0,
        paymentMethod: 'bKash Online',
        paymentStatus: 'paid',
        deliveryDate: 'Today',
        deliverySlot: 'Evening Relax',
        deliveryInstructions: 'Call upon arrival',
        status: OrderStatus.confirmed,
        createdAt: DateTime(2026, 9, 20, 14, 30),
      );

      // Test JSON map (for local storage)
      final jsonMap = order.toMap(forFirestore: false);
      expect(jsonMap['id'], equals('BS-2002'));
      expect(jsonMap['paymentMethod'], equals('bKash Online'));
      expect(jsonMap['status'], equals('confirmed'));
      expect(jsonMap['deliveryInstructions'], equals('Call upon arrival'));
      expect(jsonMap['createdAt'], isA<String>());

      // Parse back
      final parsed = OrderModel.fromMap(jsonMap);
      expect(parsed.id, equals('BS-2002'));
      expect(parsed.buyerName, equals('Ariful Islam'));
      expect(parsed.items.length, equals(2));
      expect(parsed.items[0].title, equals('Fresh Cauliflower'));
      expect(parsed.status, equals(OrderStatus.confirmed));
      expect(parsed.deliveryInstructions, equals('Call upon arrival'));
      expect(parsed.totalAmount, equals(190.0));
    });
  });

  group('OrderRepositoryImpl Local Resilience', () {
    test('Saves order locally, updates status, and retrieves via stream', () async {
      final repo = OrderRepositoryImpl();

      const address = AddressModel(
        id: 'addr_1',
        userId: 'guest_user',
        recipientName: 'Guest Buyer',
        phoneNumber: '01900000000',
        street: 'Gulshan 2',
        area: 'Gulshan',
      );

      final order = OrderModel(
        id: 'BS-LOCAL-1',
        buyerId: 'guest_user',
        buyerName: 'Guest Buyer',
        buyerPhone: '01900000000',
        deliveryAddress: address,
        items: const [
          CartItemModel(
            productId: 'prod_99',
            title: 'Farm Fresh Egg (12 pcs)',
            image: '',
            price: 155.0,
            quantity: 1,
            sellerId: 'egg_seller',
            sellerName: 'Dhaka Poultry',
          ),
        ],
        vendorIds: const ['egg_seller'],
        subtotal: 155.0,
        deliveryFee: 50.0,
        totalAmount: 205.0,
        paymentMethod: 'Cash on Delivery',
        deliveryDate: 'Today',
        deliverySlot: 'Morning Fresh',
        status: OrderStatus.placed,
        createdAt: DateTime.now(),
      );

      // 1. Place order
      final orderId = await repo.placeOrder(order);
      expect(orderId, equals('BS-LOCAL-1'));

      // 2. Stream single order
      final fetchedOrder = await repo.streamOrderById(orderId).first;
      expect(fetchedOrder, isNotNull);
      expect(fetchedOrder!.id, equals('BS-LOCAL-1'));
      expect(fetchedOrder.status, equals(OrderStatus.placed));

      // 3. Update status to confirmed
      await repo.updateOrderStatus(orderId, OrderStatus.confirmed);
      final updatedOrder = await repo.streamOrderById(orderId).first;
      expect(updatedOrder!.status, equals(OrderStatus.confirmed));

      // 4. Cancel order
      await repo.cancelOrder(orderId);
      final cancelledOrder = await repo.streamOrderById(orderId).first;
      expect(cancelledOrder!.status, equals(OrderStatus.cancelled));
      expect(cancelledOrder.isActive, isFalse);
    });
  });
}
