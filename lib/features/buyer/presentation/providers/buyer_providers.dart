import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/buyer_repository_impl.dart';
import '../../domain/models/category_model.dart';
import '../../domain/models/product_model.dart';
import '../../domain/repositories/buyer_repository.dart';

/// Exposes the [BuyerRepository] implementation.
final buyerRepositoryProvider = Provider<BuyerRepository>((ref) {
  return BuyerRepositoryImpl();
});

/// Notifier managing active category filter. `null` or `'All'` selects all categories.
class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectCategory(String? category) {
    if (category == 'All') {
      state = null;
    } else {
      state = category;
    }
  }
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String?>(SelectedCategoryNotifier.new);

/// Notifier managing active product search query on Home Screen.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Live stream of all product categories from Firestore.
final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(buyerRepositoryProvider);
  return repo.getCategoriesStream();
});

/// Live stream of marketplace products reacting to category selection and text search query.
final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final repo = ref.watch(buyerRepositoryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  return repo.getProductsStream(categoryName: selectedCategory).map((products) {
    if (query.isEmpty) return products;
    return products.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  });
});

/// Live stream of featured / promotional products for highlight carousels.
final featuredProductsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final repo = ref.watch(buyerRepositoryProvider);
  return repo.getProductsStream(onlyFeatured: true);
});
