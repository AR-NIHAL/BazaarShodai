import '../../../buyer/domain/models/product_model.dart';

/// Contract defining vendor-specific catalog operations.
abstract class SellerRepository {
  /// Publishes a new product document to Firestore `/products/{productId}`.
  Future<void> addProduct(ProductModel product);

  /// Real-time stream of all products owned by a specific [sellerId].
  Stream<List<ProductModel>> getSellerProductsStream(String sellerId);

  /// Deletes a product from Firestore `/products/{productId}`.
  Future<void> deleteProduct(String productId);
}
