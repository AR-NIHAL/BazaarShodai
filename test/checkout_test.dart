import 'package:bazaar_shodai/features/checkout/domain/models/address_model.dart';
import 'package:bazaar_shodai/features/checkout/domain/models/delivery_slot_model.dart';
import 'package:bazaar_shodai/features/checkout/presentation/providers/checkout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddressModel Domain Logic', () {
    test('Serializes to map and parses correctly with formatted address', () {
      const address = AddressModel(
        id: 'addr_1',
        userId: 'user_123',
        label: 'Home',
        recipientName: 'Ariful Islam',
        phoneNumber: '01700000000',
        street: 'House 12, Road 5',
        area: 'Dhanmondi',
        city: 'Dhaka',
        deliveryInstructions: 'Leave with building guard',
        isDefault: true,
      );

      expect(address.formattedAddress, equals('House 12, Road 5, Dhanmondi, Dhaka'));
      expect(address.isDefault, isTrue);

      final map = address.toMap();
      expect(map['recipientName'], equals('Ariful Islam'));
      expect(map['area'], equals('Dhanmondi'));

      final parsed = AddressModel.fromMap(map, documentId: 'addr_1');
      expect(parsed.id, equals('addr_1'));
      expect(parsed.recipientName, equals('Ariful Islam'));
      expect(parsed.formattedAddress, equals(address.formattedAddress));
    });
  });

  group('DeliverySlot & PaymentMethod Domain Logic', () {
    test('DeliverySlot properties and fees are computed properly', () {
      final morningSlot = DeliverySlot.defaultSlots.firstWhere((s) => s.id == 'morning');
      final expressSlot = DeliverySlot.defaultSlots.firstWhere((s) => s.id == 'express');

      expect(morningSlot.extraFee, equals(0.0));
      expect(expressSlot.extraFee, equals(30.0));
      expect(expressSlot.timeRange, contains('2 Hours'));
    });

    test('PaymentMethod names and brand colors are correct', () {
      expect(PaymentMethod.cashOnDelivery.displayName, contains('Cash on Delivery'));
      expect(PaymentMethod.bkash.displayName, contains('bKash'));
      expect(PaymentMethod.nagad.displayName, contains('Nagad'));
    });
  });

  group('Checkout & Addresses Notifier Integration', () {
    test('CheckoutNotifier manages address selection, slots, and payment method', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final checkoutNotifier = container.read(checkoutProvider.notifier);

      // Default state has Dhanmondi address and morning slot
      expect(container.read(checkoutProvider).selectedDate, equals('Today'));
      expect(container.read(checkoutProvider).selectedSlot.id, equals('morning'));
      expect(
        container.read(checkoutProvider).selectedPaymentMethod,
        equals(PaymentMethod.cashOnDelivery),
      );

      // Switch to Express slot
      final expressSlot = DeliverySlot.defaultSlots.firstWhere((s) => s.id == 'express');
      checkoutNotifier.setDeliverySlot(expressSlot);
      expect(container.read(checkoutProvider).selectedSlot.id, equals('express'));

      // Switch payment method to bKash
      checkoutNotifier.setPaymentMethod(PaymentMethod.bkash);
      expect(
        container.read(checkoutProvider).selectedPaymentMethod,
        equals(PaymentMethod.bkash),
      );

      // Add a new address
      const newAddress = AddressModel(
        id: 'addr_new_99',
        userId: 'current_user',
        label: 'Office',
        recipientName: 'Arif Office',
        phoneNumber: '01800000000',
        street: 'Level 4, Banani Tower',
        area: 'Banani',
        isDefault: true,
      );

      container.read(addressesProvider.notifier).addAddress(newAddress);
      expect(container.read(addressesProvider).first.id, equals('addr_new_99'));

      checkoutNotifier.setAddress(newAddress);
      expect(container.read(checkoutProvider).selectedAddress?.area, equals('Banani'));
    });
  });
}
