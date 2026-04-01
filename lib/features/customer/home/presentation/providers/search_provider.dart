import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuish_food/features/customer/home/domain/entities/restaurant.dart';
import 'package:tuish_food/features/customer/home/presentation/providers/home_provider.dart';

/// Holds the current search query string.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) {
    state = value;
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Fetches search results based on the current query.
/// Automatically re-fetches when [searchQueryProvider] changes.
final searchResultsProvider =
    FutureProvider<List<Restaurant>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isEmpty) {
    return [];
  }

  final repository = ref.watch(restaurantRepositoryProvider);

  final result = await repository.searchRestaurants(query.trim());

  return result.fold(
    (failure) => throw Exception(failure.message),
    (restaurants) => restaurants,
  );
});
