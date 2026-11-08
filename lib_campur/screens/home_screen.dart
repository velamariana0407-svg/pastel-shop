import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'product_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  List<String> get _categories =>
      (_allProducts.map((p) => p.category).toSet().toList()..sort());

  // ---------- READ ----------
  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _error = null;
        _isLoading = false;
        _applyFilter();
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isLoading = false;
        if (_allProducts.isEmpty) _error = msg;
      });
      if (_allProducts.isNotEmpty) _showSnack(msg);
    }
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts
          .where((p) =>
              p.title.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }
  }

  // ---------- CREATE ----------
  Future<void> _openCreate() async {
    final created = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(categories: _categories),
      ),
    );
    if (created == null || !mounted) return;

    // DummyJSON selalu membalas id yang sama untuk produk baru,
    // jadi id unik diberikan di aplikasi.
    final nextId = _allProducts.fold<int>(0, (m, p) => p.id > m ? p.id : m) + 1;
    setState(() {
      _allProducts.insert(0, created.copyWith(id: nextId, isLocal: true));
      _applyFilter();
    });
    _showSnack('Produk berhasil ditambahkan ✨');
  }

  // ---------- UPDATE (dipanggil dari halaman detail) ----------
  void _onUpdated(Product updated) {
    final i = _allProducts.indexWhere((p) => p.id == updated.id);
    if (i == -1) return;
    setState(() {
      _allProducts[i] = updated;
      _applyFilter();
    });
  }

  // ---------- DELETE (dipanggil dari halaman detail) ----------
  void _onDeleted(Product deleted) {
    setState(() {
      _allProducts.removeWhere((p) => p.id == deleted.id);
      _applyFilter();
    });
    _showSnack('Produk berhasil dihapus 🗑️');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFFDFBF7);
    const Color textColor = Color(0xFF4A4E69);
    const Color cardColor = Color(0xFFFFF0F5);
    const Color accentColor = Color(0xFFB5EAD7);
    const Color coral = Color(0xFFF8AFA6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        title: const Text(
          'Pastel Shop ✨',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      floatingActionButton: _isLoading || _error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: coral,
              foregroundColor: Colors.white,
              elevation: 2,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: coral))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('😿', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 8),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: textColor)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: coral, foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _isLoading = true;
                            });
                            _loadProducts();
                          },
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: TextField(
                        onChanged: (q) => setState(() {
                          _query = q;
                          _applyFilter();
                        }),
                        style: const TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'Cari produk favoritmu...',
                          hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                          prefixIcon: const Icon(Icons.search, color: textColor),
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide: const BorderSide(color: accentColor, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.0),
                            borderSide: const BorderSide(color: coral, width: 2),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: coral,
                        onRefresh: _loadProducts,
                        child: _filteredProducts.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 160),
                                  Center(
                                    child: Text('Produk tidak ditemukan 🌸',
                                        style: TextStyle(color: textColor, fontSize: 16)),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                                itemCount: _filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = _filteredProducts[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailScreen(
                                            product: product,
                                            categories: _categories,
                                            onUpdated: _onUpdated,
                                            onDeleted: _onDeleted,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(20)),
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Image.network(
                                                    product.thumbnail,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    errorBuilder: (_, __, ___) => const Center(
                                                      child: Icon(
                                                          Icons.image_not_supported_outlined,
                                                          color: textColor),
                                                    ),
                                                  ),
                                                  if (product.isLocal)
                                                    Positioned(
                                                      top: 8,
                                                      left: 8,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: accentColor,
                                                          borderRadius:
                                                              BorderRadius.circular(10),
                                                        ),
                                                        child: const Text('Baru',
                                                            style: TextStyle(
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                                color: textColor)),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: textColor),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                        '\$${product.price.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF84A9AC),
                                                            fontSize: 14)),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.star,
                                                            size: 14, color: Colors.amber),
                                                        Text('${product.rating}',
                                                            style: const TextStyle(
                                                                fontSize: 12,
                                                                color: textColor)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
