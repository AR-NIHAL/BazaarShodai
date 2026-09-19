import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../buyer/domain/models/product_model.dart';
import '../../data/repositories/seller_repository_impl.dart';
import '../../domain/repositories/seller_repository.dart';

/// Provider exposing [SellerRepository] instance.
final sellerRepositoryProvider = Provider<SellerRepository>((ref) {
  return SellerRepositoryImpl();
});

/// StreamProvider emitting the current seller's catalog of published products.
final sellerProductsStreamProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, sellerId) {
  final repo = ref.watch(sellerRepositoryProvider);
  return repo.getSellerProductsStream(sellerId);
});
