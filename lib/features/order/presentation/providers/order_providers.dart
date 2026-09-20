import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';

/// Provider providing the concrete [OrderRepository].
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return OrderRepositoryImpl(firestore: firestore);
});

/// StreamProvider delivering real-time list of all orders for the current user/guest.
final buyerOrdersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  final authUser = ref.watch(authStateChangesProvider).value;
  final buyerId = authUser?.uid ?? 'guest_user';

  return repository.streamBuyerOrders(buyerId);
});

/// Filtered provider returning only currently active (pending, packing, in-transit) orders.
final activeOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final ordersAsync = ref.watch(buyerOrdersStreamProvider);
  return ordersAsync.whenData((orders) => orders.where((o) => o.isActive).toList());
});

/// Filtered provider returning past (delivered or cancelled) orders.
final pastOrdersProvider = Provider<AsyncValue<List<OrderModel>>>((ref) {
  final ordersAsync = ref.watch(buyerOrdersStreamProvider);
  return ordersAsync.whenData((orders) => orders.where((o) => !o.isActive).toList());
});

/// StreamProvider for an individual order by ID (for live tracking screens).
final orderTrackingStreamProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.streamOrderById(orderId);
});
