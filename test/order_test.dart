import 'dart:convert';
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

    test('streamSellerOrders streams orders matching sellerId and ignores others', () async {
      final repo = OrderRepositoryImpl();

      const address = AddressModel(
        id: 'addr_seller_test',
        userId: 'buyer_abc',
        recipientName: 'Test Buyer',
        phoneNumber: '01711111111',
        street: 'Banani 11',
        area: 'Banani',
      );

      final orderForSellerA = OrderModel(
        id: 'BS-SELLER-A',
        buyerId: 'buyer_abc',
        buyerName: 'Test Buyer',
        buyerPhone: '01711111111',
        deliveryAddress: address,
        items: const [
          CartItemModel(
            productId: 'p_a',
            title: 'Seller A Product',
            image: '',
            price: 100.0,
            quantity: 2,
            sellerId: 'seller_alpha',
            sellerName: 'Alpha Store',
          ),
        ],
        vendorIds: const ['seller_alpha'],
        subtotal: 200.0,
        deliveryFee: 50.0,
        totalAmount: 250.0,
        paymentMethod: 'Cash on Delivery',
        deliveryDate: 'Today',
        deliverySlot: 'Morning',
        status: OrderStatus.placed,
        createdAt: DateTime.now(),
      );

      final orderForSellerB = OrderModel(
        id: 'BS-SELLER-B',
        buyerId: 'buyer_abc',
        buyerName: 'Test Buyer',
        buyerPhone: '01711111111',
        deliveryAddress: address,
        items: const [
          CartItemModel(
            productId: 'p_b',
            title: 'Seller B Product',
            image: '',
            price: 300.0,
            quantity: 1,
            sellerId: 'seller_beta',
            sellerName: 'Beta Store',
          ),
        ],
        vendorIds: const ['seller_beta'],
        subtotal: 300.0,
        deliveryFee: 50.0,
        totalAmount: 350.0,
        paymentMethod: 'bKash Online',
        deliveryDate: 'Tomorrow',
        deliverySlot: 'Evening',
        status: OrderStatus.placed,
        createdAt: DateTime.now(),
      );

      await repo.placeOrder(orderForSellerA);
      await repo.placeOrder(orderForSellerB);

      // Verify seller_alpha only gets orderForSellerA
      final sellerAOrders = await repo.streamSellerOrders('seller_alpha').first;
      expect(sellerAOrders.length, equals(1));
      expect(sellerAOrders.first.id, equals('BS-SELLER-A'));

      // Verify seller_beta only gets orderForSellerB
      final sellerBOrders = await repo.streamSellerOrders('seller_beta').first;
      expect(sellerBOrders.length, equals(1));
      expect(sellerBOrders.first.id, equals('BS-SELLER-B'));

      // Advance status of order A and verify reflection
      await repo.updateOrderStatus('BS-SELLER-A', OrderStatus.confirmed);
      final updatedOrders = await repo.streamSellerOrders('seller_alpha').first;
      expect(updatedOrders.first.status, equals(OrderStatus.confirmed));
    });

    test('recovers orders even when stored JSON string is double-encoded by web SharedPreferences', () async {
      final repo = OrderRepositoryImpl();

      // Simulate double-encoded JSON string as produced by Web localStorage
      final rawOrderJson = jsonEncode([
        {
          'id': 'BS-WEB-DOUBLE',
          'buyerId': 'buyer_web',
          'buyerName': 'Web Buyer',
          'buyerPhone': '01800000000',
          'deliveryAddress': {
            'id': 'addr_w',
            'userId': 'buyer_web',
            'recipientName': 'Web Buyer',
            'phoneNumber': '01800000000',
            'street': 'Road 1',
            'area': 'Gulshan',
          },
          'items': [
            {
              'productId': 'p_web',
              'title': 'Double Encoded Item',
              'image': '',
              'price': 120.0,
              'quantity': 1,
              'sellerId': 'seller_web',
              'sellerName': 'Web Store',
            }
          ],
          'vendorIds': ['seller_web'],
          'subtotal': 120.0,
          'deliveryFee': 50.0,
          'totalAmount': 170.0,
          'paymentMethod': 'Cash on Delivery',
          'deliveryDate': 'Today',
          'deliverySlot': 'Morning',
          'status': 'placed',
          'createdAt': '2026-10-07T20:00:00.000',
        }
      ]);

      // Double-encode it: JSON string of a JSON string
      final doubleEncoded = jsonEncode(rawOrderJson);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_orders_json', doubleEncoded);

      // Verify streamSellerOrders parses it cleanly without throwing
      final orders = await repo.streamSellerOrders('seller_web').first;
      expect(orders.length, equals(1));
      expect(orders.first.id, equals('BS-WEB-DOUBLE'));
      expect(orders.first.items.first.title, equals('Double Encoded Item'));
    });
  });
}
