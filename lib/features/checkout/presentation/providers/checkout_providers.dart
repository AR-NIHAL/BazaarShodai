import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/address_model.dart';
import '../../domain/models/delivery_slot_model.dart';

/// State object representing the checkout configuration
class CheckoutState {
  final AddressModel? selectedAddress;
  final String selectedDate; // 'Today' or 'Tomorrow'
  final DeliverySlot selectedSlot;
  final PaymentMethod selectedPaymentMethod;
  final String deliveryInstructions;
  final bool isSubmitting;
  final String? errorMessage;

  const CheckoutState({
    this.selectedAddress,
    this.selectedDate = 'Today',
    this.selectedSlot = DeliverySlot.morningSlot,
    this.selectedPaymentMethod = PaymentMethod.cashOnDelivery,
    this.deliveryInstructions = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  CheckoutState copyWith({
    AddressModel? selectedAddress,
    String? selectedDate,
    DeliverySlot? selectedSlot,
    PaymentMethod? selectedPaymentMethod,
    String? deliveryInstructions,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedSlot: selectedSlot ?? this.selectedSlot,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier managing the checkout preferences
class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    final addresses = ref.watch(addressesProvider);
    final defaultAddress = addresses.isNotEmpty ? addresses.first : null;
    return CheckoutState(selectedAddress: defaultAddress);
  }

  void setAddress(AddressModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  void setDeliveryDate(String date) {
    state = state.copyWith(selectedDate: date);
  }

  void setDeliverySlot(DeliverySlot slot) {
    state = state.copyWith(selectedSlot: slot);
  }

  void setPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedPaymentMethod: method);
  }

  void setDeliveryInstructions(String instructions) {
    state = state.copyWith(deliveryInstructions: instructions);
  }

  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }

  void setError(String? message) {
    state = state.copyWith(errorMessage: message);
  }
}

final checkoutProvider =
    NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);

/// Notifier managing user's saved delivery addresses
class AddressesNotifier extends Notifier<List<AddressModel>> {
  @override
  List<AddressModel> build() {
    return _initialSampleAddresses;
  }

  static const List<AddressModel> _initialSampleAddresses = [
    AddressModel(
      id: 'addr_default_1',
      userId: 'current_user',
      label: 'Home',
      recipientName: 'Customer',
      phoneNumber: '01712345678',
      street: 'House 42, Road 9/A',
      area: 'Dhanmondi',
      city: 'Dhaka',
      deliveryInstructions: 'Ring doorbell and leave at 3rd floor',
      isDefault: true,
    ),
    AddressModel(
      id: 'addr_default_2',
      userId: 'current_user',
      label: 'Office',
      recipientName: 'Customer',
      phoneNumber: '01712345678',
      street: 'Navana Tower, Level 8, Gulshan Avenue',
      area: 'Gulshan 1',
      city: 'Dhaka',
      isDefault: false,
    ),
  ];

  void addAddress(AddressModel newAddress) {
    final updated = List<AddressModel>.from(state);
    if (newAddress.isDefault) {
      for (int i = 0; i < updated.length; i++) {
        updated[i] = updated[i].copyWith(isDefault: false);
      }
    }
    updated.insert(0, newAddress);
    state = updated;
  }

  void deleteAddress(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}

final addressesProvider =
    NotifierProvider<AddressesNotifier, List<AddressModel>>(AddressesNotifier.new);
