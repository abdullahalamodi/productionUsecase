# 🔍 Master Search & Filter in Flutter with Riverpod - Clean Architecture Guide

Ever struggled with managing search and filter state across multiple pages in your Flutter app? Here's a clean, reusable solution using Riverpod that will make your code more maintainable! 🚀

## 🎯 The Problem

Most apps need search and filter functionality on multiple pages (users list, products, appointments, etc.). The challenge is:
- Each page needs its own independent search state
- Debounced search to avoid excessive API calls
- Easy filter updates without boilerplate
- Proper memory management

## 💡 The Solution: Family Provider Pattern

### Step 1: Create the Filter Model
```dart
class FilterModel {
  final String searchText;
  final String category;
  final DateTime? dateFrom;
  
  const FilterModel({
    this.searchText = '',
    this.category = '',
    this.dateFrom,
  });
  
  FilterModel copyWith({
    String? searchText,
    String? category,
    DateTime? dateFrom,
  }) {
    return FilterModel(
      searchText: searchText ?? this.searchText,
      category: category ?? this.category,
      dateFrom: dateFrom ?? this.dateFrom,
    );
  }
  
  static FilterModel empty() => const FilterModel();
}
```

### Step 2: Define the Typedef for Clean Code
```dart
typedef FilterUpdater = FilterModel Function(FilterModel model);
```

### Step 3: Create the Search & Filter Provider
```dart
final searchAndFilterProvider = StateNotifierProvider.autoDispose
    .family<SearchAndFilterProvider, FilterModel, String>((ref, pageId) {
  return SearchAndFilterProvider(ref);
});

class SearchAndFilterProvider extends StateNotifier<FilterModel> {
  SearchAndFilterProvider(this.ref) : super(FilterModel.empty()) {
    searchController.addListener(_searchListener);
  }
  
  final Ref ref;
  final searchController = TextEditingController();
  Timer? _searchTimer;
  
  // Debounced search - waits 500ms after user stops typing
  void _searchListener() {
    final currentText = searchController.text;
    if (state.searchText == currentText) return;
    
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        state = state.copyWith(searchText: currentText);
      }
    });
  }
  
  // Clean way to update any filter
  void updateFilters(FilterUpdater updater) {
    state = updater(state);
  }
  
  void clearFilters() {
    searchController.clear();
    state = FilterModel.empty();
  }
  
  @override
  void dispose() {
    _searchTimer?.cancel();
    if (mounted) {
      searchController.removeListener(_searchListener);
    }
    searchController.dispose();
    super.dispose();
  }
}
```

## 🔥 How to Use It

### In Your Page Widget:
```dart
class ProductsPage extends ConsumerWidget {

  static String pageName = 'products';

    
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Each page gets its own provider instance
    final searchProvider = searchAndFilterProvider(pageName);
    final filters = ref.watch(searchProvider);

    
    // Listen for filter changes and refresh data
    ref.listen(searchProvider, (prev, next) {
      if (prev != next) {
        ref.read(productsListProvider.notifier).getProducts(filters: next);
      }
    });
    
    return Column(
      children: [
        // Search TextField
        TextField(
          controller: ref.read(searchProvider.notifier).searchController,
          decoration: InputDecoration(hintText: 'Search products...'),
        ),
        
        // Filter Buttons
        Row(
          children: [
            FilterChip(
              label: Text('Electronics'),
              selected: filters.category == 'electronics',
              onSelected: (selected) {
                ref.read(searchProvider.notifier).updateFilters(
                  (model) => model.copyWith(
                    category: selected ? 'electronics' : '',
                  ),
                );
              },
            ),
          ],
        ),
        
        // Your products list here...
      ],
    );
  }
}
```

### Update Filters Anywhere:
```dart
// Simple search update
ref.read(searchAndFilterProvider(pageName).notifier).updateFilters(
  (model) => model.copyWith(searchText: 'iPhone'),
);

// Multiple filters at once
ref.read(searchAndFilterProvider(pageName).notifier).updateFilters(
  (model) => model.copyWith(
    category: 'electronics',
    dateFrom: DateTime.now().subtract(Duration(days: 30)),
  ),
);

// Clear all filters
ref.read(searchAndFilterProvider(pageName).notifier).clearFilters();
```

## 🎉 Why This Pattern Rocks

✅ **Isolated State**: Each page has independent search/filter state
✅ **Debounced Search**: No excessive API calls
✅ **Memory Efficient**: Auto-dispose cleans up resources
✅ **Reusable**: Use the same provider for any page
✅ **Testable**: Easy to unit test each component

## 🔧 Pro Tips

1. **Use descriptive page IDs**: `'users'`, `'products'`, `'appointments'`
2. **Make debounce configurable** for different use cases
4. **Extend FilterModel** as your app grows

## 🏁 Result

You now have a bulletproof search and filter system that scales with your app! No more duplicate code, memory leaks, or messy state management.

Try it out and let me know how it works for you! 💪
