import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported user roles within BazaarShodai's multi-vendor ecosystem.
enum UserRole {
  customer,
  seller;

  bool get isSeller => this == UserRole.seller;
  bool get isCustomer => this == UserRole.customer;

  static UserRole fromString(String? role) {
    if (role == 'seller') {
      return UserRole.seller;
    }
    return UserRole.customer;
  }
}

/// Structured shop and contact details for vendor accounts.
class ShopDetails {
  final String shopName;
  final String phone;
  final String address;

  const ShopDetails({
    required this.shopName,
    required this.phone,
    required this.address,
  });

  factory ShopDetails.fromMap(Map<String, dynamic> map) {
    return ShopDetails(
      shopName: map['shopName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'phone': phone,
      'address': address,
    };
  }

  ShopDetails copyWith({
    String? shopName,
    String? phone,
    String? address,
  }) {
    return ShopDetails(
      shopName: shopName ?? this.shopName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopDetails &&
        other.shopName == shopName &&
        other.phone == phone &&
        other.address == address;
  }

  @override
  int get hashCode => shopName.hashCode ^ phone.hashCode ^ address.hashCode;

  @override
  String toString() =>
      'ShopDetails(shopName: $shopName, phone: $phone, address: $address)';
}

/// Core domain user entity representing both buyers and vendors.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final bool isApproved;
  final ShopDetails? shopDetails;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.role = UserRole.customer,
    this.isApproved = true,
    this.shopDetails,
    this.createdAt,
  });

  /// Factory constructor to deserialize Firestore document data into a [UserModel].
  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['createdAt'];
    if (rawCreatedAt is Timestamp) {
      parsedCreatedAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt is int) {
      parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    }

    ShopDetails? parsedShopDetails;
    if (map['shopDetails'] != null && map['shopDetails'] is Map<String, dynamic>) {
      parsedShopDetails = ShopDetails.fromMap(
        Map<String, dynamic>.from(map['shopDetails'] as Map),
      );
    }

    return UserModel(
      uid: documentId ?? (map['uid'] as String? ?? ''),
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      isApproved: map['isApproved'] as bool? ?? (map['role'] != 'seller'),
      shopDetails: parsedShopDetails,
      createdAt: parsedCreatedAt,
    );
  }

  /// Serializes [UserModel] to a Map suitable for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.name,
      'isApproved': isApproved,
      'shopDetails': shopDetails?.toMap(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  /// Creates a copy of this [UserModel] with updated fields.
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    UserRole? role,
    bool? isApproved,
    ShopDetails? shopDetails,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      shopDetails: shopDetails ?? this.shopDetails,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        other.isApproved == isApproved &&
        other.shopDetails == shopDetails;
  }

  @override
  int get hashCode =>
      uid.hashCode ^
      email.hashCode ^
      name.hashCode ^
      role.hashCode ^
      isApproved.hashCode ^
      shopDetails.hashCode;

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, name: $name, role: ${role.name}, isApproved: $isApproved, shopDetails: $shopDetails)';
  }
}
