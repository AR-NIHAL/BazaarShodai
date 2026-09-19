import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../buyer/domain/models/product_model.dart';
import '../../domain/repositories/seller_repository.dart';

/// Firestore implementation of [SellerRepository].
class SellerRepositoryImpl implements SellerRepository {
  final FirebaseFirestore _firestore;

  SellerRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  @override
  Future<void> addProduct(ProductModel product) async {
    final docRef = product.id.isNotEmpty
        ? _productsCollection.doc(product.id)
        : _productsCollection.doc();

    final productToSave = product.id.isEmpty
        ? product.copyWith(id: docRef.id)
        : product;

    await docRef.set(productToSave.toMap());
  }

  @override
  Stream<List<ProductModel>> getSellerProductsStream(String sellerId) {
    return _productsCollection
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data(), documentId: doc.id);
      }).toList();
    });
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _productsCollection.doc(productId).delete();
  }
}
