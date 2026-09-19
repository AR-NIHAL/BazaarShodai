/// Domain model representing a product category in BazaarShodai.
class CategoryModel {
  final String id;
  final String name;
  final String? icon;
  final String? imageUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    this.icon,
    this.imageUrl,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return CategoryModel(
      id: documentId ?? (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? imageUrl,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel &&
        other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ icon.hashCode ^ imageUrl.hashCode;

  @override
  String toString() => 'CategoryModel(id: $id, name: $name, icon: $icon, imageUrl: $imageUrl)';
}
