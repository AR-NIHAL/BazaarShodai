import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/buyer_repository.dart';

/// Firebase Firestore implementation of [BuyerRepository].
class BuyerRepositoryImpl implements BuyerRepository {
  final FirebaseFirestore _firestore;

  BuyerRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  @override
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _categoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryModel.fromMap(doc.data(), documentId: doc.id);
      }).toList();
    });
  }

  @override
  Stream<List<ProductModel>> getProductsStream({
    String? categoryName,
    bool? onlyFeatured,
  }) {
    Query<Map<String, dynamic>> query = _productsCollection;

    if (categoryName != null &&
        categoryName.isNotEmpty &&
        categoryName.toLowerCase() != 'all') {
      query = query.where('category', isEqualTo: categoryName);
    }

    if (onlyFeatured == true) {
      query = query.where('isFeatured', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), documentId: doc.id);
      }).toList();
    });
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final snapshot = await _productsCollection.get();
    return snapshot.docs
        .map((doc) => ProductModel.fromMap(doc.data(), documentId: doc.id))
        .where((product) =>
            product.title.toLowerCase().contains(cleanQuery) ||
            product.category.toLowerCase().contains(cleanQuery) ||
            product.description.toLowerCase().contains(cleanQuery))
        .toList();
  }

  @override
  Future<void> seedInitialDataIfEmpty() async {
    try {
      final existingCategories = await _categoriesCollection.limit(1).get();
      if (existingCategories.docs.isNotEmpty) {
        return;
      }

      // Initialize standard marketplace categories only (zero fake products)
      final initialCategories = [
        const CategoryModel(
          id: 'cat_vegetables',
          name: 'Vegetables',
          icon: 'eco',
          imageUrl: '',
        ),
        const CategoryModel(
          id: 'cat_fruits',
          name: 'Fruits',
          icon: 'apple',
          imageUrl: '',
        ),
        const CategoryModel(
          id: 'cat_fish_meat',
          name: 'Fish & Meat',
          icon: 'set_meal',
          imageUrl: '',
        ),
        const CategoryModel(
          id: 'cat_spices_oil',
          name: 'Spices & Oil',
          icon: 'grain',
          imageUrl: '',
        ),
        const CategoryModel(
          id: 'cat_dairy_eggs',
          name: 'Dairy & Eggs',
          icon: 'egg',
          imageUrl: '',
        ),
        const CategoryModel(
          id: 'cat_rice_grains',
          name: 'Rice & Grains',
          icon: 'rice_bowl',
          imageUrl: '',
        ),
      ];

      for (final cat in initialCategories) {
        await _categoriesCollection.doc(cat.id).set(cat.toMap());
      }
    } catch (_) {
      // Gracefully continue
    }
  }
}
