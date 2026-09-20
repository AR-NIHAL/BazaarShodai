import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../cart/domain/models/cart_item_model.dart';
import '../../../checkout/domain/models/address_model.dart';

/// Lifecycle status for a customer grocery order
enum OrderStatus {
  placed,
  confirmed,
  outForDelivery,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed & Packing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get subtitle {
    switch (this) {
      case OrderStatus.placed:
        return 'Your order has been received by BazaarShodai';
      case OrderStatus.confirmed:
        return 'Fresh farm produce is being inspected and packed';
      case OrderStatus.outForDelivery:
        return 'Delivery hero is on the way to your doorstep';
      case OrderStatus.delivered:
        return 'Package handed over safely';
      case OrderStatus.cancelled:
        return 'Order was cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.outForDelivery:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.placed:
        return const Color(0xFF2563EB); // Blue
      case OrderStatus.confirmed:
        return const Color(0xFFD97706); // Amber
      case OrderStatus.outForDelivery:
        return const Color(0xFF7C3AED); // Purple
      case OrderStatus.delivered:
        return const Color(0xFF059669); // Emerald Green
      case OrderStatus.cancelled:
        return const Color(0xFFDC2626); // Red
    }
  }
}

/// Domain entity representing a customer order in BazaarShodai
class OrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final AddressModel deliveryAddress;
  final List<CartItemModel> items;
  final List<String> vendorIds;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus; // 'pending' or 'paid'
  final String deliveryDate;
  final String deliverySlot;
  final String? deliveryInstructions;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? estimatedDeliveryTime;

  const OrderModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.vendorIds,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0.0,
    required this.totalAmount,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    required this.deliveryDate,
    required this.deliverySlot,
    this.deliveryInstructions,
    this.status = OrderStatus.placed,
    required this.createdAt,
    this.estimatedDeliveryTime,
  });

  /// True if the order is still active (not yet delivered or cancelled)
  bool get isActive =>
      status != OrderStatus.delivered && status != OrderStatus.cancelled;

  /// True if the order has been delivered
  bool get isDelivered => status == OrderStatus.delivered;

  /// Total count of items in this order
  int get totalItemCount => items.fold(0, (total, i) => total + i.quantity);

  Map<String, dynamic> toMap({bool forFirestore = true}) {
    return {
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'deliveryAddress': deliveryAddress.toMap(),
      'items': items.map((i) => i.toMap()).toList(),
      'vendorIds': vendorIds,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'deliveryDate': deliveryDate,
      'deliverySlot': deliverySlot,
      if (deliveryInstructions != null) 'deliveryInstructions': deliveryInstructions,
      'status': status.name,
      'createdAt': forFirestore ? Timestamp.fromDate(createdAt) : createdAt.toIso8601String(),
      if (estimatedDeliveryTime != null)
        'estimatedDeliveryTime': forFirestore
            ? Timestamp.fromDate(estimatedDeliveryTime!)
            : estimatedDeliveryTime!.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parsedCreatedAt = DateTime.now();
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    }

    DateTime? parsedEst;
    final rawEst = map['estimatedDeliveryTime'];
    if (rawEst is Timestamp) {
      parsedEst = rawEst.toDate();
    } else if (rawEst is String) {
      parsedEst = DateTime.tryParse(rawEst);
    }

    List<CartItemModel> parsedItems = [];
    if (map['items'] != null && map['items'] is List) {
      parsedItems = (map['items'] as List)
          .map((i) => CartItemModel.fromMap(i as Map<String, dynamic>))
          .toList();
    }

    List<String> parsedVendorIds = [];
    if (map['vendorIds'] != null && map['vendorIds'] is List) {
      parsedVendorIds = List<String>.from((map['vendorIds'] as List).map((v) => v.toString()));
    }

    OrderStatus parsedStatus = OrderStatus.placed;
    final rawStatus = map['status'] as String?;
    if (rawStatus != null) {
      for (final s in OrderStatus.values) {
        if (s.name == rawStatus) {
          parsedStatus = s;
          break;
        }
      }
    }

    return OrderModel(
      id: documentId ?? (map['id'] as String? ?? ''),
      buyerId: map['buyerId'] as String? ?? '',
      buyerName: map['buyerName'] as String? ?? 'Valued Customer',
      buyerPhone: map['buyerPhone'] as String? ?? '',
      deliveryAddress: map['deliveryAddress'] != null
          ? AddressModel.fromMap(map['deliveryAddress'] as Map<String, dynamic>)
          : const AddressModel(
              id: '',
              userId: '',
              recipientName: 'Customer',
              phoneNumber: '',
              street: '',
              area: 'Dhaka',
            ),
      items: parsedItems,
      vendorIds: parsedVendorIds,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash on Delivery',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      deliveryDate: map['deliveryDate'] as String? ?? 'Today',
      deliverySlot: map['deliverySlot'] as String? ?? 'Morning Fresh',
      deliveryInstructions: map['deliveryInstructions'] as String?,
      status: parsedStatus,
      createdAt: parsedCreatedAt,
      estimatedDeliveryTime: parsedEst,
    );
  }

  OrderModel copyWith({
    String? id,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    AddressModel? deliveryAddress,
    List<CartItemModel>? items,
    List<String>? vendorIds,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? deliveryDate,
    String? deliverySlot,
    String? deliveryInstructions,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? estimatedDeliveryTime,
  }) {
    return OrderModel(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      vendorIds: vendorIds ?? this.vendorIds,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
    );
  }
}
