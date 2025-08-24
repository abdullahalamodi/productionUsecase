# Mastering Loading States in Flutter with Riverpod: A Complete Guide to the 3 Essential Loading types

Loading states are crucial for creating smooth user experiences in Flutter apps. Users need to know when something is happening, whether it's fetching data, submitting a form, or updating content. With Riverpod, we can implement loading states elegantly and efficiently.

In this comprehensive guide, we'll explore **three distinct loading types** that cover every scenario you'll encounter in your Flutter apps. Each pattern serves a specific purpose and requires a different implementation approach.

## 🎯 The Three Types of Loading States

Before diving into implementation, let's understand when to use each loading type:

### 1. **Inline Loading** 
- **When to use**: Displaying content like item details, user profiles, or any page that starts empty
- **Behavior**: The entire screen shows a loading indicator until content is ready
- **Example**: Loading a product detail page

### 2. **Action Loading**
- **When to use**: Performing actions like form submissions, API calls, or any user-triggered operations
- **Behavior**: An overlay covers the entire app while the action completes
- **Example**: Submitting a login form or processing a payment

### 3. **Inner Loading**
- **When to use**: Updating existing content like search results, filters, or refreshing data
- **Behavior**: Content remains visible with an additional loading indicator
- **Example**: Real-time search or applying filters to a product list

Now let's implement each pattern step by step.

---

## 🔄 Pattern 1: Inline Loading

Inline loading is perfect for pages that need to fetch data before displaying content. We'll create a custom state model to handle loading, data, and error states.

### Step 1: Create the State Model

```dart
class DataStateModel<T> {
  final bool isLoading;
  final String? errorMessage;
  final T? data;

  const DataStateModel({
    required this.isLoading,
    this.errorMessage,
    this.data,
  });

  // Factory constructor for initial loading state
  factory DataStateModel.loading() => DataStateModel<T>(isLoading: true);

  // Factory constructor for error state
  factory DataStateModel.error(String message) => DataStateModel<T>(
    isLoading: false,
    errorMessage: message,
  );

  // Factory constructor for success state
  factory DataStateModel.success(T data) => DataStateModel<T>(
    isLoading: false,
    data: data,
  );

  // CopyWith method for state updates
  DataStateModel<T> copyWith({
    bool? isLoading,
    String? errorMessage,
    T? data,
  }) {
    return DataStateModel<T>(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      data: data ?? this.data,
    );
  }
}
```

### Step 2: Create the StateNotifier Provider

```dart
final userProfileProvider = StateNotifierProvider.autoDispose
    .family<UserProfileNotifier, DataStateModel<UserModel>, String>(
  (ref, userId) => UserProfileNotifier(ref, userId),
);

class UserProfileNotifier extends StateNotifier<DataStateModel<UserModel>> {
  UserProfileNotifier(this._ref, this._userId) 
    : super(DataStateModel.loading()) {
    _fetchUserProfile();
  }

  final Ref _ref;
  final String _userId;

  Future<void> _fetchUserProfile() async {
    try {
      // Fetch user data from repository
      final userData = await _ref
          .read(userRepositoryProvider)
          .getUserById(_userId);
      
      // Update state with successful data
      state = DataStateModel.success(userData);
      
    } on ApiException catch (e) {
      // Handle API errors
      state = DataStateModel.error(e.message);
    } catch (e) {
      // Handle unexpected errors
      state = DataStateModel.error('An unexpected error occurred');
    }
  }

  // Method to retry fetching data
  Future<void> retry() async {
    state = DataStateModel.loading();
    await _fetchUserProfile();
  }
}
```

### Step 3: Use Inline Loading in Your Widget

```dart
class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId});
  
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProfileProvider(userId));
    
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: _buildBody(userState, ref),
    );
  }

  Widget _buildBody(DataStateModel<UserModel> state, WidgetRef ref) {
    if (state.isLoading) {
      // Show loading indicator
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (state.errorMessage != null) {
      // Show error with retry option
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(userProfileProvider(userId).notifier)
                  .retry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      // Show user profile content
      return UserProfileContent(user: state.data!);
    }
  }
}
```

---

## ⚡ Pattern 2: Action Loading (Global Overlay)

Action loading provides a global overlay that can be triggered from anywhere in your app. This pattern is ideal for form submissions and API actions that require user to wait.

### Step 1: Create the Global Loading Provider

```dart
final globalLoadingProvider = StateProvider<bool>((ref) => false);
```

### Step 2: Set Up Loading Listener in App Widget

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to loading state changes
    _listenToGlobalLoading(ref);

    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'My Flutter App',
    );
  }

  void _listenToGlobalLoading(WidgetRef ref) {
    ref.listen<bool>(
      globalLoadingProvider,
      (previousState, currentState) {
        final context = navigatorKey.currentContext;
        if (context == null) return;

        if (currentState && !(previousState ?? false)) {
          // Show loading overlay
          _showLoadingOverlay(context);
        } else if (!currentState && (previousState ?? false)) {
          // Hide loading overlay
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

### Step 3: Use Action Loading in Your Business Logic

```dart
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState.initial());

  final Ref _ref;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Start global loading
      _ref.read(globalLoadingProvider.notifier).state = true;

      // Perform authentication
      final response = await _ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password);

      // Handle successful sign in
      state = AuthState.authenticated(response.user);
      
    } on AuthException catch (e) {
      // Handle authentication errors
      state = AuthState.error(e.message);
    } finally {
      // Always stop loading
      _ref.read(globalLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signOut() async {
    try {
      _ref.read(globalLoadingProvider.notifier).state = true;
      
      await _ref.read(authRepositoryProvider).signOut();
      state = const AuthState.unauthenticated();
      
    } finally {
      _ref.read(globalLoadingProvider.notifier).state = false;
    }
  }
}
```

---

## 🔍 Pattern 3: Inner Loading

Inner loading is used when you need to update existing content while keeping it visible. This pattern is commonly used for search functionality and real-time filters.

### Step 1: Extended State Model with Inner Loading

```dart
class SearchableDataState<T> {
  final bool isInitialLoading;
  final bool isInnerLoading;
  final String? errorMessage;
  final List<T> items;

  const SearchableDataState({
    required this.isInitialLoading,
    required this.isInnerLoading,
    this.errorMessage,
    required this.items,
  });

  factory SearchableDataState.initial() => SearchableDataState<T>(
    isInitialLoading: true,
    isInnerLoading: false,
    items: [],
  );

  SearchableDataState<T> copyWith({
    bool? isInitialLoading,
    bool? isInnerLoading,
    String? errorMessage,
    List<T>? items,
  }) {
    return SearchableDataState<T>(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isInnerLoading: isInnerLoading ?? this.isInnerLoading,
      errorMessage: errorMessage,
      items: items ?? this.items,
    );
  }
}
```

### Step 2: Create Search Provider with Inner Loading

```dart
final productSearchProvider = StateNotifierProvider<ProductSearchNotifier, 
    SearchableDataState<Product>>((ref) {
  return ProductSearchNotifier(ref);
});

class ProductSearchNotifier extends StateNotifier<SearchableDataState<Product>> {
  ProductSearchNotifier(this._ref) : super(SearchableDataState.initial()) {
    _loadInitialProducts();
  }

  final Ref _ref;

  Future<void> _loadInitialProducts() async {
    try {
      final products = await _ref
          .read(productRepositoryProvider)
          .getAllProducts();

      state = state.copyWith(
        isInitialLoading: false,
        items: products,
      );
    } catch (e) {
      state = state.copyWith(
        isInitialLoading: false,
        errorMessage: 'Failed to load products',
      );
    }
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await _loadInitialProducts();
      return;
    }

    try {
      // Start inner loading while keeping existing content visible
      state = state.copyWith(
        isInnerLoading: true,
        errorMessage: null,
      );

      final searchResults = await _ref
          .read(productRepositoryProvider)
          .searchProducts(query);

      state = state.copyWith(
        isInnerLoading: false,
        items: searchResults,
      );
    } catch (e) {
      state = state.copyWith(
        isInnerLoading: false,
        errorMessage: 'Search failed',
      );
    }
  }
}
```

### Step 3: Implement Search UI with Inner Loading

```dart
class ProductSearchPage extends ConsumerStatefulWidget {
  const ProductSearchPage({super.key});

  @override
  ConsumerState<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends ConsumerState<ProductSearchPage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(productSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildSearchField(searchState),
          ),
        ),
      ),
      body: _buildBody(searchState),
    );
  }

  Widget _buildSearchField(SearchableDataState<Product> state) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: state.isInnerLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        border: const OutlineInputBorder(),
      ),
      onChanged: (query) {
        ref.read(productSearchProvider.notifier).searchProducts(query);
      },
    );
  }

  Widget _buildBody(SearchableDataState<Product> state) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.items.isEmpty) {
      return Center(child: Text(state.errorMessage!));
    }

    return Column(
      children: [
        // Inner loading indicator at the top
        if (state.isInnerLoading)
          const LinearProgressIndicator(minHeight: 2),
        
        // Product list (remains visible during inner loading)
        Expanded(
          child: ListView.builder(
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              return ProductListItem(product: state.items[index]);
            },
          ),
        ),
      ],
    );
  }
}
```

---

## 🎯 Key Takeaways

1. **Inline Loading**: Perfect for initial data fetching where the entire screen waits for content
2. **Action Loading**: Ideal for user actions that require waiting with a global overlay
3. **Inner Loading**: Best for updating existing content while keeping it visible

Each pattern serves a specific purpose and provides the best user experience for different scenarios. Choose the right pattern based on your use case, and your users will appreciate the smooth, responsive feel of your Flutter app.

Remember to always handle errors gracefully and provide retry mechanisms where appropriate. With Riverpod's powerful state management capabilities, implementing these loading types becomes both elegant and maintainable.

Happy coding! 🚀
