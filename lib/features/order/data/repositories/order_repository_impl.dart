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
  Stream<List<OrderModel>> streamBuyerOrders(String buyerId) {
    // If Firestore is null, buyerId is empty, or guest, stream purely from local storage
    if (_ordersCollection == null ||
        buyerId.isEmpty ||
        buyerId == 'current_user' ||
        buyerId.startsWith('guest_')) {
      return Stream.fromFuture(_getLocalOrders());
    }

    return _ordersCollection!
        .where('buyerId', isEqualTo: buyerId)
        .snapshots()
        .asyncMap((snapshot) async {
      final remoteOrders = snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), documentId: doc.id))
          .toList();

      final localOrders = await _getLocalOrders();
      final Map<String, OrderModel> orderMap = {};

      for (final o in localOrders) {
        orderMap[o.id] = o;
      }
      for (final o in remoteOrders) {
        orderMap[o.id] = o; // remote takes precedence
      }

      final list = orderMap.values.toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((error) async {
      // Fallback to local storage if Firestore throws index or network error
      return await _getLocalOrders();
    });
  }

  @override
  Stream<OrderModel?> streamOrderById(String orderId) {
    if (_ordersCollection == null) {
      return Stream.fromFuture(_getLocalOrders()).map((list) {
        try {
          return list.firstWhere((o) => o.id == orderId);
        } catch (_) {
          return null;
        }
      });
    }

    return _ordersCollection!.doc(orderId).snapshots().asyncMap((snap) async {
      if (snap.exists && snap.data() != null) {
        return OrderModel.fromMap(snap.data()!, documentId: snap.id);
      }
      // Fallback to local storage
      final localOrders = await _getLocalOrders();
      try {
        return localOrders.firstWhere((o) => o.id == orderId);
      } catch (_) {
        return null;
      }
    }).handleError((error) async {
      final localOrders = await _getLocalOrders();
      try {
        return localOrders.firstWhere((o) => o.id == orderId);
      } catch (_) {
        return null;
      }
    });
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
      final List<dynamic> list = jsonDecode(jsonStr);
      return list
          .map((item) => OrderModel.fromMap(item as Map<String, dynamic>))
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
