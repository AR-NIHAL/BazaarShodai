import '../models/order_model.dart';

/// Contract for managing customer grocery orders in BazaarShodai.
abstract class OrderRepository {
  /// Places a customer order atomically, deducting stock from products.
  /// Returns the placed order ID.
  Future<String> placeOrder(OrderModel order);

  /// Streams the list of all orders belonging to a specific buyer.
  Stream<List<OrderModel>> streamBuyerOrders(String buyerId);

  /// Streams real-time updates for a single order by ID.
  Stream<OrderModel?> streamOrderById(String orderId);

  /// Updates the lifecycle status of an order.
  Future<void> updateOrderStatus(String orderId, OrderStatus status);

  /// Cancels an order (allowed only if order is in [OrderStatus.placed]).
  Future<void> cancelOrder(String orderId);
}
