import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../services/product_store.dart';
import 'product_form_screen.dart';

/// Palet pastel biru khusus halaman detail
class _Blue {
  static const bg = Color(0xFFF2F8FE); // latar halaman
  static const ice = Color(0xFFE6F1FC); // kartu paling terang
  static const sky = Color(0xFFD3E8FA); // pastel utama
  static const mist = Color(0xFFBBD9F4); // pastel sedang
  static const periwinkle = Color(0xFF8FB8E8); // aksen
  static const deep = Color(0xFF4F86C6); // aksen tegas (tombol, harga)
  static const ink = Color(0xFF1F3A57); // teks utama
  static const inkSoft = Color(0xFF6A839E); // teks sekunder
  static const star = Color(0xFFF6C453); // bintang rating
  static const danger = Color(0xFFE05A5A); // aksi hapus
}

class DetailScreen extends StatefulWidget {
  final Product product;
  final Color? color;

  const DetailScreen({super.key, required this.product, this.color});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _busy = false;
  late Product _product;

  Product get p => _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  SnackBar _snack(String text, {bool error = false}) => SnackBar(
        backgroundColor: error ? _Blue.danger : _Blue.ink,
        behavior: SnackBarBehavior.floating,
        content: Text(text),
      );

  // ---------- UBAH ----------
  Future<void> _edit() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);
    final updated = await Navigator.push<Product>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: _product)),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _product = updated;
      _page = 0;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(_snack('Perubahan berhasil disimpan'));
  }

  // ---------- HAPUS ----------
  Future<void> _confirmDelete() async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus produk?',
            style: TextStyle(fontWeight: FontWeight.w800, color: _Blue.ink)),
        content: Text('"${_product.title}" akan dihapus.',
            style: const TextStyle(color: _Blue.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _Blue.inkSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(
                    color: _Blue.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final title = _product.title;
    setState(() => _busy = true);
    try {
      await ProductService().deleteProduct(_product);
      ProductStore.instance.remove(_product);
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(_snack('$title berhasil dihapus'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Blue.bg,
      bottomNavigationBar: _buildBottomBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGallery(context),
            Transform.translate(
              offset: const Offset(0, -28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                decoration: const BoxDecoration(
                  color: _Blue.bg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.images.length > 1) ...[
                      _buildThumbnails(),
                      const SizedBox(height: 20),
                    ],
                    _buildTitleBlock(),
                    const SizedBox(height: 22),
                    const _SectionTitle('Deskripsi'),
                    Text(
                      p.description,
                      style: const TextStyle(
                          fontSize: 14, height: 1.6, color: _Blue.inkSoft),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Informasi produk'),
                    _buildInfoList(),
                    const SizedBox(height: 24),
                    _SectionTitle('Ulasan (${p.reviews.length})'),
                    ..._buildReviews(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    return Container(
      height: 360,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_Blue.mist, _Blue.sky, _Blue.ice],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: 30,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            Positioned.fill(
              top: 48,
              bottom: 40,
              child: PageView.builder(
                controller: _pageController,
                itemCount: p.images.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final img = Image.network(
                    p.images[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (c, child, prog) => prog == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _Blue.deep),
                          ),
                    errorBuilder: (c, e, s) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: _Blue.inkSoft),
                  );
                  return i == 0
                      ? Hero(tag: 'product-${p.id}', child: img)
                      : img;
                },
              ),
            ),
            Positioned(
              left: 16,
              top: 8,
              child: _CircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            // Tombol ubah & hapus
            Positioned(
              right: 16,
              top: 8,
              child: _busy
                  ? Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: _Blue.deep),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircleButton(icon: Icons.edit_rounded, onTap: _edit),
                        const SizedBox(width: 8),
                        _CircleButton(
                          icon: Icons.delete_outline_rounded,
                          color: _Blue.danger,
                          onTap: _confirmDelete,
                        ),
                      ],
                    ),
            ),
            if (p.images.length > 1)
              Positioned(
                right: 16,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_page + 1} / ${p.images.length}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _Blue.ink),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnails() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: p.images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final active = i == _page;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: active ? _Blue.sky : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: active ? _Blue.deep : _Blue.sky,
                  width: active ? 2 : 1.5,
                ),
              ),
              child: Image.network(
                p.images[i],
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: 18,
                    color: _Blue.inkSoft),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(text: p.category, bg: _Blue.sky, fg: _Blue.deep),
            if (p.brand != null)
              _Chip(text: p.brand!, bg: Colors.white, fg: _Blue.ink),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          p.title,
          style: const TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: _Blue.ink),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.star_rounded, color: _Blue.star, size: 22),
            const SizedBox(width: 4),
            Text(
              p.rating.toStringAsFixed(1),
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: _Blue.ink),
            ),
            const SizedBox(width: 10),
            Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: _Blue.periwinkle, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(
              p.availabilityStatus,
              style: const TextStyle(color: _Blue.inkSoft, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoList() {
    final items = <(IconData, String, String)>[
      (Icons.inventory_2_rounded, 'Stok', '${p.stock} unit'),
      (Icons.local_shipping_rounded, 'Pengiriman', p.shippingInformation),
      (Icons.verified_user_rounded, 'Garansi', p.warrantyInformation),
      (Icons.assignment_return_rounded, 'Pengembalian', p.returnPolicy),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _Blue.sky, width: 1.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: i.isEven ? _Blue.sky : _Blue.ice,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(items[i].$1, size: 20, color: _Blue.deep),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].$2,
                            style: const TextStyle(
                                fontSize: 12, color: _Blue.inkSoft)),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$3,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _Blue.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 14, endIndent: 14, color: _Blue.ice),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildReviews() {
    if (p.reviews.isEmpty) {
      return const [
        Text('Belum ada ulasan.', style: TextStyle(color: _Blue.inkSoft)),
      ];
    }
    final avatarColors = [_Blue.sky, _Blue.mist, _Blue.ice];
    return [
      for (var i = 0; i < p.reviews.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: avatarColors[i % avatarColors.length],
                    child: Text(
                      p.reviews[i].reviewerName.isEmpty
                          ? '?'
                          : p.reviews[i].reviewerName[0].toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, color: _Blue.deep),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p.reviews[i].reviewerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: _Blue.ink),
                    ),
                  ),
                  ...List.generate(
                    5,
                    (s) => Icon(
                      s < p.reviews[i].rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: _Blue.star,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                p.reviews[i].comment,
                style: const TextStyle(
                    fontSize: 13.5, height: 1.5, color: _Blue.inkSoft),
              ),
            ],
          ),
        ),
    ];
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _Blue.periwinkle.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (p.hasDiscount)
                      Text(
                        '\$${p.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _Blue.inkSoft,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (p.hasDiscount) const SizedBox(width: 8),
                    if (p.hasDiscount)
                      _Chip(
                        text: '-${p.discountPercentage.toStringAsFixed(0)}%',
                        bg: _Blue.sky,
                        fg: _Blue.deep,
                        small: true,
                      ),
                  ],
                ),
                Text(
                  '\$${p.finalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: _Blue.deep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _Blue.deep,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: _Blue.ink,
                  behavior: SnackBarBehavior.floating,
                  content: Text('${p.title} ditambahkan ke keranjang'),
                ),
              );
            },
            icon: const Icon(Icons.shopping_bag_rounded, size: 20),
            label: const Text('Tambah ke keranjang',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: _Blue.ink),
        ),
      );
}

class _Chip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final bool small;
  const _Chip(
      {required this.text,
      required this.bg,
      required this.fg,
      this.small = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 8 : 12, vertical: small ? 3 : 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w700,
              color: fg),
        ),
      );
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _CircleButton(
      {required this.icon, required this.onTap, this.color = _Blue.ink});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.85),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      );
}