import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../domain/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';

/// Concrete implementation of [OrderRepository] using Cloud Firestore
/// with optimistic local storage fallback for guest checkout & offline resilience.
class OrderRepositoryImpl implements OrderRepository {
  final FirebaseFirestore? _firestore;

  OrderRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>>? get _ordersCollection =>
      _firestore?.collection('orders');

  CollectionReference<Map<String, dynamic>>? get _productsCollection =>
      _firestore?.collection('products');

  @override
  Future<String> placeOrder(OrderModel order) async {
    final String orderId = order.id.isNotEmpty
        ? order.id
        : 'BS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final orderToPlace = order.copyWith(id: orderId);

    // 1. Try atomic Firestore transaction to check & decrement stock (if Firestore available)
    if (_firestore != null) {
      try {
        await _firestore.runTransaction((transaction) async {
          // First, check inventory for all items
          for (final item in orderToPlace.items) {
            if (item.productId.isEmpty) continue;
            final productRef = _productsCollection!.doc(item.productId);
            final productSnap = await transaction.get(productRef);

            if (productSnap.exists) {
              final data = productSnap.data();
              final currentStock = (data?['stock'] as num?)?.toInt() ?? 0;
              if (currentStock < item.quantity) {
                throw Exception(
                  'Insufficient stock for "${item.title}". Only $currentStock available.',
                );
              }
              final newStock = currentStock - item.quantity;
              transaction.update(productRef, {'stock': newStock});
            }
          }

          // Second, write the order document atomically
          final orderRef = _ordersCollection!.doc(orderId);
          transaction.set(orderRef, orderToPlace.toMap(forFirestore: true));
        });
      } catch (e) {
        // If error is an explicit stock limitation, rethrow it so UI can inform the user
        final errorStr = e.toString();
        if (errorStr.contains('Insufficient stock')) {
          rethrow;
        }
        // Otherwise, continue to local save (e.g. guest or offline)
      }
    }

    // 2. Persist locally for immediate offline tracking and guest support
    await _saveOrderLocally(orderToPlace);

    return orderId;
  }

  @override
  Stream<List<OrderModel>> streamBuyerOrders(String buyerId) async* {
    yield await _getLocalOrders();

    if (_ordersCollection == null ||
        buyerId.isEmpty ||
        buyerId == 'current_user' ||
        buyerId.startsWith('guest_')) {
      return;
    }

    try {
      final remoteStream = _ordersCollection!
          .where('buyerId', isEqualTo: buyerId)
          .snapshots();

      await for (final snapshot in remoteStream) {
        final remoteOrders = snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), documentId: doc.id))
            .toList();

        final localOrders = await _getLocalOrders();
        final Map<String, OrderModel> orderMap = {};

        for (final o in localOrders) {
          orderMap[o.id] = o;
        }
        for (final o in remoteOrders) {
          orderMap[o.id] = o;
        }

        final list = orderMap.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield list;
      }
    } catch (_) {
      yield await _getLocalOrders();
    }
  }

  @override
  Stream<List<OrderModel>> streamSellerOrders(String sellerId) async* {
    if (sellerId.isEmpty) {
      yield [];
      return;
    }

    // 1. Immediately yield local orders for instant zero-latency UI display
    yield await _getLocalOrdersForSeller(sellerId);

    if (_ordersCollection == null) {
      return;
    }

    // 2. Stream from Firestore and merge with local storage
    try {
      final remoteStream = _ordersCollection!
          .where('vendorIds', arrayContains: sellerId)
          .snapshots();

      await for (final snapshot in remoteStream) {
        final remoteOrders = snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data(), documentId: doc.id))
            .toList();

        final localOrders = await _getLocalOrdersForSeller(sellerId);
        final Map<String, OrderModel> orderMap = {};

        for (final o in localOrders) {
          orderMap[o.id] = o;
        }
        for (final o in remoteOrders) {
          orderMap[o.id] = o;
        }

        final list = orderMap.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield list;
      }
    } catch (_) {
      yield await _getLocalOrdersForSeller(sellerId);
    }
  }

  Future<List<OrderModel>> _getLocalOrdersForSeller(String sellerId) async {
    final allLocal = await _getLocalOrders();
    return allLocal.where((order) {
      final hasVendorId = order.vendorIds.contains(sellerId);
      final hasItemFromSeller = order.items.any((item) => item.sellerId == sellerId);
      return hasVendorId || hasItemFromSeller;
    }).toList();
  }

  @override
  Stream<OrderModel?> streamOrderById(String orderId) async* {
    final localOrders = await _getLocalOrders();
    OrderModel? local;
    try {
      local = localOrders.firstWhere((o) => o.id == orderId);
    } catch (_) {}
    yield local;

    if (_ordersCollection == null) return;

    try {
      await for (final snap in _ordersCollection!.doc(orderId).snapshots()) {
        if (snap.exists && snap.data() != null) {
          yield OrderModel.fromMap(snap.data()!, documentId: snap.id);
        } else {
          yield local;
        }
      }
    } catch (_) {
      yield local;
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    if (_ordersCollection != null) {
      try {
        await _ordersCollection!.doc(orderId).update({'status': status.name});
      } catch (_) {
        // Graceful fallback
      }
    }

    // Update in local storage
    final localOrders = await _getLocalOrders();
    final index = localOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      localOrders[index] = localOrders[index].copyWith(status: status);
      await _saveAllLocalOrders(localOrders);
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  // --- Local Storage Helpers ---

  Future<List<OrderModel>> _getLocalOrders() async {
    try {
      final jsonStr = await LocalStorageService.getOrdersJson();
      if (jsonStr == null || jsonStr.trim().isEmpty) return [];
      dynamic decoded = jsonDecode(jsonStr);
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is! List) return [];
      return decoded
          .map((item) => OrderModel.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveOrderLocally(OrderModel order) async {
    final existing = await _getLocalOrders();
    final index = existing.indexWhere((o) => o.id == order.id);
    if (index != -1) {
      existing[index] = order;
    } else {
      existing.insert(0, order);
    }
    await _saveAllLocalOrders(existing);
  }

  Future<void> _saveAllLocalOrders(List<OrderModel> orders) async {
    final jsonList = orders.map((o) => o.toMap(forFirestore: false)).toList();
    await LocalStorageService.saveOrdersJson(jsonEncode(jsonList));
  }
}
