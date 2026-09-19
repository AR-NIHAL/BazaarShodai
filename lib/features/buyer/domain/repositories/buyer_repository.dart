import '../models/category_model.dart';
import '../models/product_model.dart';

/// Contract defining read operations for buyer shopping catalog.
abstract class BuyerRepository {
  /// Stream emitting the active product categories.
  Stream<List<CategoryModel>> getCategoriesStream();

  /// Stream emitting products with optional filtering by category name and featured status.
  Stream<List<ProductModel>> getProductsStream({
    String? categoryName,
    bool? onlyFeatured,
  });

  /// Searches products matching the given [query].
  Future<List<ProductModel>> searchProducts(String query);

  /// Seeds initial categories and farm-fresh grocery products into Firestore if collections are empty.
  /// Useful for immediate portfolio demonstration on new or empty Firebase instances.
  Future<void> seedInitialDataIfEmpty();
}
