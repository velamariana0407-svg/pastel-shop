import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_form_screen.dart';

class DetailScreen extends StatefulWidget {
  final Product product;
  final List<String> categories;
  final ValueChanged<Product> onUpdated;
  final ValueChanged<Product> onDeleted;

  const DetailScreen({
    Key? key,
    required this.product,
    required this.categories,
    required this.onUpdated,
    required this.onDeleted,
  }) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  static const Color bgColor = Color(0xFFFDFBF7);
  static const Color textColor = Color(0xFF4A4E69);
  static const Color pastelBadge = Color(0xFFE2F0CB);
  static const Color danger = Color(0xFFE76F7A);

  late Product _product;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<Product>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          product: _product,
          categories: widget.categories,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    setState(() => _product = updated);
    widget.onUpdated(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk berhasil diubah ✨')),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus produk?',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Text('"${_product.title}" akan dihapus.',
            style: const TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await ApiService.deleteProduct(_product); // DELETE
      if (!mounted) return;
      widget.onDeleted(_product);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: _busy ? null : () => Navigator.pop(context),
        ),
        title: const Text('Detail Produk',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: _busy
            ? const [
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Color(0xFFF8AFA6)),
                    ),
                  ),
                ),
              ]
            : [
                IconButton(
                  tooltip: 'Ubah',
                  icon: const Icon(Icons.edit_outlined, color: textColor),
                  onPressed: _edit,
                ),
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline_rounded, color: danger),
                  onPressed: _confirmDelete,
                ),
              ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  product.thumbnail,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: textColor, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                        color: pastelBadge, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      product.category.replaceAll('-', ' ').toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text('${product.rating}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(product.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text('\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF8AFA6))),
            const SizedBox(height: 20),
            const Text('Deskripsi Produk',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 8),
            Text(product.description,
                style: TextStyle(
                    fontSize: 14, color: textColor.withValues(alpha: 0.8), height: 1.5)),
          ],
        ),
      ),
    );
  }
}
