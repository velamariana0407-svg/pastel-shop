import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/product_card.dart';

/// Palet pastel biru khusus HomeScreen (disesuaikan tanpa variabel unused)
class _Blue {
   static const bg = Color(0xFFF2F8FE); // latar halaman
   static const sky = Color(0xFFD3E8FA); // pastel utama
   static const periwinkle = Color(0xFF8FB8E8); // aksen bayangan/garis
   static const deep = Color(0xFF4F86C6); // aksen tegas (tombol, ikon aktif)
   static const ink = Color(0xFF1F3A57); // teks utama
   static const inkSoft = Color(0xFF6A839E); // teks sekunder
   static const pink = Color(0xFFF8D7DA); // untuk pesan error
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = ProductService();
  final _controller = TextEditingController();
  final _focus = FocusNode();

  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load({String query = ''}) async {
    setState(() {
      _loading = true;
      _error = null;
      _activeQuery = query.trim();
    });
    try {
      final result = await _service.fetchProducts(query: query);
      if (!mounted) return;
      setState(() {
        _products = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat produk.\nPeriksa koneksi internet kamu.';
        _loading = false;
      });
    }
  }

  void _submitSearch() {
    _focus.unfocus();
    _load(query: _controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    _focus.unfocus();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Blue.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                _loading
                    ? 'Memuat...'
                    : _activeQuery.isEmpty
                        ? '${_products.length} produk'
                        : '${_products.length} hasil untuk "$_activeQuery"',
                style: const TextStyle(
                    fontSize: 13, color: _Blue.inkSoft, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _Blue.sky,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.shopping_bag_rounded,
                color: _Blue.deep),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pastel Shop',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: _Blue.ink),
              ),
              Text(
                'Temukan produk favoritmu',
                style: TextStyle(fontSize: 12, color: _Blue.inkSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _Blue.sky, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _Blue.periwinkle.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submitSearch(),
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: _Blue.ink, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: const TextStyle(color: _Blue.inkSoft),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: _Blue.inkSoft),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Material(
                color: _Blue.deep,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _submitSearch,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.search_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _Blue.deep),
      );
    }
    if (_error != null) {
      return _Message(
        icon: Icons.wifi_off_rounded,
        color: _Blue.pink,
        text: _error!,
        actionLabel: 'Coba lagi',
        onAction: () => _load(query: _activeQuery),
      );
    }
    if (_products.isEmpty) {
      return _Message(
        icon: Icons.search_off_rounded,
        color: _Blue.sky,
        text: 'Produk "$_activeQuery" tidak ditemukan.',
        actionLabel: 'Tampilkan semua',
        onAction: _clearSearch,
      );
    }
    return RefreshIndicator(
      color: _Blue.deep,
      backgroundColor: Colors.white,
      onRefresh: () => _load(query: _activeQuery),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: _products.length,
        itemBuilder: (context, i) =>
            ProductCard(product: _products[i], index: i),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({
    required this.icon,
    required this.color,
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: _Blue.ink),
            ),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: _Blue.inkSoft, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _Blue.deep,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onAction,
              child: Text(actionLabel, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}