import 'package:flutter/material.dart';

/// Available payment methods on BazaarShodai
enum PaymentMethod {
  cashOnDelivery,
  bkash,
  nagad;

  String get displayName {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery (COD)';
      case PaymentMethod.bkash:
        return 'bKash Online Payment';
      case PaymentMethod.nagad:
        return 'Nagad Online Payment';
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return 'Pay in cash when groceries arrive at your doorstep';
      case PaymentMethod.bkash:
        return 'Pay instantly from your bKash wallet';
      case PaymentMethod.nagad:
        return 'Fast and secure payment with Nagad';
    }
  }

  Color get brandColor {
    switch (this) {
      case PaymentMethod.cashOnDelivery:
        return const Color(0xFF047857);
      case PaymentMethod.bkash:
        return const Color(0xFFE2136E); // bKash official magenta
      case PaymentMethod.nagad:
        return const Color(0xFFF7941D); // Nagad official orange
    }
  }
}

/// Delivery slot representation for fresh perishable groceries
class DeliverySlot {
  final String id;
  final String title;
  final String timeRange;
  final String subtitle;
  final IconData icon;
  final String? badge;
  final double extraFee;

  const DeliverySlot({
    required this.id,
    required this.title,
    required this.timeRange,
    required this.subtitle,
    required this.icon,
    this.badge,
    this.extraFee = 0.0,
  });

  static const DeliverySlot morningSlot = DeliverySlot(
    id: 'morning',
    title: 'Morning Fresh',
    timeRange: '08:00 AM - 11:00 AM',
    subtitle: 'Harvested early morning, direct from local farmers',
    icon: Icons.wb_sunny_outlined,
    badge: 'Popular for Fish & Veggies',
  );

  static const DeliverySlot eveningSlot = DeliverySlot(
    id: 'evening',
    title: 'Evening Relax',
    timeRange: '05:00 PM - 08:00 PM',
    subtitle: 'Delivered after work hours, ready for dinner',
    icon: Icons.nights_stay_outlined,
  );

  static const DeliverySlot expressSlot = DeliverySlot(
    id: 'express',
    title: 'Express Delivery',
    timeRange: 'Within 2 Hours',
    subtitle: 'Priority rider dispatch directly to your doorstep',
    icon: Icons.bolt_outlined,
    badge: '+ ৳ 30 fee',
    extraFee: 30.0,
  );

  /// Standard predefined delivery slots for Dhaka city
  static const List<DeliverySlot> defaultSlots = [
    morningSlot,
    eveningSlot,
    expressSlot,
  ];
}
