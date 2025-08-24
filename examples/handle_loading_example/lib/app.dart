// pubspec.yaml dependencies:
// flutter:
//   sdk: flutter
// flutter_riverpod: ^2.4.9
// http: ^1.1.0

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global navigator key for overlay loading
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for loading changes
    _watchForLoading(ref);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Loading Examples',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }

  void _watchForLoading(WidgetRef ref) {
    ref.listen<bool>(
      loadingOverlayProvider,
      (wasLoading, isLoading) {
        final context = navigatorKey.currentContext;
        if (context == null) return;

        if (isLoading && !(wasLoading ?? false)) {
          // Show the overlay
          _showLoadingOverlay(context);
        } else if (!isLoading && (wasLoading ?? false)) {
          // Hide the overlay
          Navigator.of(context).pop();
        }
      },
    );
  }

  void _showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: Colors.black54,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing...'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MODELS
// =============================================================================

class User {
  final String id;
  final String name;
  final String email;
  final String avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? 'Unknown User',
      email: json['email'] ?? 'no-email@example.com',
      avatar: json['avatar'] ?? 'https://via.placeholder.com/150',
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['title'] ?? 'Product',
      description: json['description'] ?? 'No description',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] ?? 'https://via.placeholder.com/150',
    );
  }
}

// =============================================================================
// STATE MODELS
// =============================================================================

// For full screen loading
class DataState<T> {
  final bool isLoading;
  final String? error;
  final T? data;

  const DataState({
    required this.isLoading,
    this.error,
    this.data,
  });

  factory DataState.loading() => DataState<T>(isLoading: true);
  factory DataState.error(String message) =>
      DataState<T>(isLoading: false, error: message);
  factory DataState.success(T data) =>
      DataState<T>(isLoading: false, data: data);

  DataState<T> copyWith({
    bool? isLoading,
    String? error,
    T? data,
  }) {
    return DataState<T>(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
}

// For background loading (search)
class SearchState<T> {
  final bool isFirstTimeLoading;
  final bool isBackgroundLoading;
  final String? error;
  final List<T> items;

  const SearchState({
    required this.isFirstTimeLoading,
    required this.isBackgroundLoading,
    this.error,
    required this.items,
  });

  factory SearchState.empty() => SearchState<T>(
        isFirstTimeLoading: true,
        isBackgroundLoading: false,
        items: [],
      );

  SearchState<T> copyWith({
    bool? isFirstTimeLoading,
    bool? isBackgroundLoading,
    String? error,
    List<T>? items,
  }) {
    return SearchState<T>(
      isFirstTimeLoading: isFirstTimeLoading ?? this.isFirstTimeLoading,
      isBackgroundLoading: isBackgroundLoading ?? this.isBackgroundLoading,
      error: error,
      items: items ?? this.items,
    );
  }
}

// =============================================================================
// MOCK SERVICES (Simulating API calls)
// =============================================================================

class MockUserService {
  static Future<User> getUser(String userId) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    // Sometimes fail to test error handling
    if (Random().nextBool()) {
      throw Exception('User not found');
    }

    return User(
      id: userId,
      name: 'John Doe',
      email: 'john@example.com',
      avatar: 'https://via.placeholder.com/150/0000FF/FFFFFF?text=JD',
    );
  }

  static Future<bool> submitForm(Map<String, dynamic> data) async {
    // Simulate form submission
    await Future.delayed(Duration(seconds: 3));

    // Sometimes fail
    if (Random().nextBool()) {
      throw Exception('Submission failed');
    }

    return true;
  }
}

class MockProductService {
  static final List<Product> _allProducts = [
    Product(
        id: '1',
        name: 'iPhone 15',
        description: 'Latest Apple smartphone',
        price: 999.99,
        image: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=iPhone'),
    Product(
        id: '2',
        name: 'MacBook Pro',
        description: 'Powerful laptop for professionals',
        price: 1999.99,
        image: 'https://via.placeholder.com/150/00FF00/FFFFFF?text=MacBook'),
    Product(
        id: '3',
        name: 'iPad Air',
        description: 'Versatile tablet for work and play',
        price: 599.99,
        image: 'https://via.placeholder.com/150/0000FF/FFFFFF?text=iPad'),
    Product(
        id: '4',
        name: 'AirPods Pro',
        description: 'Wireless earbuds with noise cancellation',
        price: 249.99,
        image: 'https://via.placeholder.com/150/FF00FF/FFFFFF?text=AirPods'),
    Product(
        id: '5',
        name: 'Apple Watch',
        description: 'Smart watch for health and fitness',
        price: 399.99,
        image: 'https://via.placeholder.com/150/FFFF00/000000?text=Watch'),
    Product(
        id: '6',
        name: 'Samsung Galaxy',
        description: 'Android flagship phone',
        price: 899.99,
        image: 'https://via.placeholder.com/150/00FFFF/000000?text=Galaxy'),
  ];

  static Future<List<Product>> getAllProducts() async {
    await Future.delayed(Duration(seconds: 1));
    return _allProducts;
  }

  static Future<List<Product>> searchProducts(String query) async {
    await Future.delayed(Duration(milliseconds: 800));

    if (query.isEmpty) return _allProducts;

    return _allProducts
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

// Action loading provider
final loadingOverlayProvider = StateProvider<bool>((ref) => false);

// User provider (full screen loading)
final userProvider = StateNotifierProvider.autoDispose
    .family<UserNotifier, DataState<User>, String>(
  (ref, userId) => UserNotifier(ref, userId),
);

class UserNotifier extends StateNotifier<DataState<User>> {
  UserNotifier(this._ref, this._userId) : super(DataState.loading()) {
    _loadUser();
  }

  final Ref _ref;
  final String _userId;

  Future<void> _loadUser() async {
    try {
      final user = await MockUserService.getUser(_userId);
      state = DataState.success(user);
    } catch (e) {
      state = DataState.error('Oops! Could not load user: ${e.toString()}');
    }
  }

  void retry() {
    state = DataState.loading();
    _loadUser();
  }
}

// Form provider (action loading)
final formProvider = StateNotifierProvider<FormNotifier, Map<String, String>>(
  (ref) => FormNotifier(ref),
);

class FormNotifier extends StateNotifier<Map<String, String>> {
  FormNotifier(this._ref) : super({});

  final Ref _ref;

  Future<void> submitForm(Map<String, dynamic> formData) async {
    try {
      // Show loading overlay
      _ref.read(loadingOverlayProvider.notifier).state = true;

      // Submit form
      await MockUserService.submitForm(formData);

      // Show success
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Form submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Show error
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always hide loading
      _ref.read(loadingOverlayProvider.notifier).state = false;
    }
  }
}

// Product search provider (background loading)
final productSearchProvider =
    StateNotifierProvider<ProductSearchController, SearchState<Product>>(
  (ref) => ProductSearchController(ref),
);

class ProductSearchController extends StateNotifier<SearchState<Product>> {
  ProductSearchController(this._ref) : super(SearchState.empty()) {
    _loadAllProducts();
  }

  final Ref _ref;

  Future<void> _loadAllProducts() async {
    try {
      final products = await MockProductService.getAllProducts();
      state = state.copyWith(
        isFirstTimeLoading: false,
        items: products,
      );
    } catch (e) {
      state = state.copyWith(
        isFirstTimeLoading: false,
        error: 'Could not load products 😢',
      );
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      await _loadAllProducts();
      return;
    }

    try {
      state = state.copyWith(
        isBackgroundLoading: true,
        error: null,
      );

      final results = await MockProductService.searchProducts(query);

      state = state.copyWith(
        isBackgroundLoading: false,
        items: results,
      );
    } catch (e) {
      state = state.copyWith(
        isBackgroundLoading: false,
        error: 'Search failed 😅',
      );
    }
  }
}

// =============================================================================
// PAGES
// =============================================================================

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Examples'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose a loading example to test:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UserPage(userId: '123')),
              ),
              icon: const Icon(Icons.person),
              label: const Text('Full Screen Loading\n(User Profile)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FormPage()),
              ),
              icon: const Icon(Icons.send),
              label: const Text('Action Loading\n(Form Submission)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ProductSearchPage()),
              ),
              icon: const Icon(Icons.search),
              label: const Text('Background Loading\n(Product Search)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Tips:',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                        '• Some operations might fail randomly to test error handling'),
                    Text('• Try different searches in the product page'),
                    Text('• Notice how each loading type feels different'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full Screen Loading Example
class UserPage extends ConsumerWidget {
  const UserPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _buildContent(userState, ref),
    );
  }

  Widget _buildContent(DataState<User> state, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading user profile...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '😅 ${state.error!}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () =>
                    ref.read(userProvider(userId).notifier).retry(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final user = state.data!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user.avatar),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Name'),
                    subtitle: Text(user.name),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(user.email),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: const Text('ID'),
                    subtitle: Text(user.id),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => ref.read(userProvider(userId).notifier).retry(),
            child: const Text('Refresh Profile'),
          ),
        ],
      ),
    );
  }
}

// Action Loading Example
class FormPage extends ConsumerStatefulWidget {
  const FormPage({super.key});

  @override
  ConsumerState<FormPage> createState() => _FormPageState();
}

class _FormPageState extends ConsumerState<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Form'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Submit this form to see action loading in action!',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Submit Form',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The form might succeed or fail randomly to demonstrate both scenarios!',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final formData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'message': _messageController.text,
      };

      ref.read(formProvider.notifier).submitForm(formData);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

// Background Loading Example
class ProductSearchPage extends ConsumerWidget {
  const ProductSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(productSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Products'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildSearchBox(ref, searchState),
        ),
      ),
      body: _buildProductList(searchState),
    );
  }

  Widget _buildSearchBox(WidgetRef ref, SearchState<Product> state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search for products... (try "iPhone", "Mac", etc.)',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: state.isBackgroundLoading
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
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (text) {
          ref.read(productSearchProvider.notifier).search(text);
        },
      ),
    );
  }

  Widget _buildProductList(SearchState<Product> state) {
    if (state.isFirstTimeLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading products...'),
          ],
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(child: Text(state.error!));
    }

    return Column(
      children: [
        if (state.isBackgroundLoading)
          const LinearProgressIndicator(minHeight: 3),
        Expanded(
          child: state.items.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No products found'),
                      Text('Try searching for something else'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: state.items[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(product.image),
        ),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.description),
            const SizedBox(height: 4),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
