/// Domain entity representing a delivery address for hyperlocal deliveries.
class AddressModel {
  final String id;
  final String userId;
  final String label; // 'Home', 'Office', 'Other'
  final String recipientName;
  final String phoneNumber;
  final String street; // House #, Road #, Block/Sector
  final String area; // e.g. Dhanmondi, Mirpur, Uttara, Gulshan
  final String city; // Default 'Dhaka'
  final String? deliveryInstructions;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.userId,
    this.label = 'Home',
    required this.recipientName,
    required this.phoneNumber,
    required this.street,
    required this.area,
    this.city = 'Dhaka',
    this.deliveryInstructions,
    this.isDefault = false,
  });

  /// Formatted single-line display of the address
  String get formattedAddress => '$street, $area, $city';

  /// Standard popular delivery areas in Dhaka
  static const List<String> popularAreas = [
    'Dhanmondi',
    'Gulshan 1',
    'Gulshan 2',
    'Banani',
    'Uttara',
    'Mirpur 1',
    'Mirpur 2',
    'Mirpur 10',
    'Mohammadpur',
    'Badda',
    'Bashundhara R/A',
    'Khilgaon',
    'Motijheel',
    'Shantinagar',
    'Lalmatia',
  ];

  AddressModel copyWith({
    String? id,
    String? userId,
    String? label,
    String? recipientName,
    String? phoneNumber,
    String? street,
    String? area,
    String? city,
    String? deliveryInstructions,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      street: street ?? this.street,
      area: area ?? this.area,
      city: city ?? this.city,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'street': street,
      'area': area,
      'city': city,
      if (deliveryInstructions != null) 'deliveryInstructions': deliveryInstructions,
      'isDefault': isDefault,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return AddressModel(
      id: documentId ?? (map['id'] as String? ?? ''),
      userId: map['userId'] as String? ?? '',
      label: map['label'] as String? ?? 'Home',
      recipientName: map['recipientName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      street: map['street'] as String? ?? '',
      area: map['area'] as String? ?? 'Dhanmondi',
      city: map['city'] as String? ?? 'Dhaka',
      deliveryInstructions: map['deliveryInstructions'] as String?,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }
}
