import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../services/product_store.dart';

/// Palet pastel biru khusus form (sama dengan halaman lain).
class _Blue {
  static const bg = Color(0xFFF2F8FE);
  static const sky = Color(0xFFD3E8FA);
  static const deep = Color(0xFF4F86C6);
  static const ink = Color(0xFF1F3A57);
  static const inkSoft = Color(0xFF6A839E);
  static const danger = Color(0xFFE05A5A);
}

/// Form untuk TAMBAH (product == null) dan UBAH (product != null).
/// Kalau berhasil, halaman menutup dan mengembalikan [Product] hasilnya.
class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _price;
  late final TextEditingController _discount;
  late final TextEditingController _stock;
  late final TextEditingController _desc;
  late final TextEditingController _thumb;
  String? _category;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _title = TextEditingController(text: p?.title ?? '');
    _price = TextEditingController(text: p == null ? '' : _fmt(p.price));
    _discount =
        TextEditingController(text: p == null ? '0' : _fmt(p.discountPercentage));
    _stock = TextEditingController(text: p == null ? '10' : '${p.stock}');
    _desc = TextEditingController(text: p?.description ?? '');
    _thumb = TextEditingController(text: p?.thumbnail ?? '');
    _category = p?.category;
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _discount.dispose();
    _stock.dispose();
    _desc.dispose();
    _thumb.dispose();
    super.dispose();
  }

  String _placeholder(String title) =>
      'https://dummyjson.com/image/400x400/d3e8fa/1f3a57?text=${Uri.encodeComponent(title)}';

  String _availability(int stock, Product? old) {
    if (old != null && (stock > 0) == (old.stock > 0)) {
      return old.availabilityStatus;
    }
    return stock > 0 ? 'Tersedia' : 'Stok habis';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final old = widget.product;
    final title = _title.text.trim();
    final thumbInput = _thumb.text.trim();
    final thumb = thumbInput.isEmpty ? _placeholder(title) : thumbInput;
    final stock = int.parse(_stock.text.trim());

    final product = Product(
      id: old?.id ?? ProductStore.instance.newLocalId(),
      title: title,
      description: _desc.text.trim(),
      category: _category!,
      price: double.parse(_price.text.trim().replaceAll(',', '.')),
      discountPercentage:
          double.parse(_discount.text.trim().replaceAll(',', '.')),
      rating: old?.rating ?? 0,
      stock: stock,
      brand: old?.brand,
      thumbnail: thumb,
      images: (old != null && thumb == old.thumbnail) ? old.images : [thumb],
      availabilityStatus: _availability(stock, old),
      shippingInformation: old?.shippingInformation ?? '-',
      warrantyInformation: old?.warrantyInformation ?? '-',
      returnPolicy: old?.returnPolicy ?? '-',
      reviews: old?.reviews ?? <Review>[],
      isLocal: old?.isLocal ?? true,
    );

    try {
      final service = ProductService();
      if (old == null) {
        await service.createProduct(product); // POST
        ProductStore.instance.addCreated(product);
      } else {
        await service.updateProduct(product); // PUT
        ProductStore.instance.update(product);
      }
      if (!mounted) return;
      Navigator.pop(context, product);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _Blue.danger,
          behavior: SnackBarBehavior.floating,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _Blue.inkSoft),
      hintStyle: const TextStyle(color: _Blue.inkSoft),
      prefixIcon: icon == null ? null : Icon(icon, color: _Blue.deep),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: border(_Blue.sky, 1.5),
      disabledBorder: border(_Blue.sky, 1.5),
      focusedBorder: border(_Blue.deep, 2),
      errorBorder: border(_Blue.danger, 1.5),
      focusedErrorBorder: border(_Blue.danger, 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryItems = <String>{
      ...ProductStore.instance.categories,
      if (_category != null) _category!,
    }.toList()
      ..sort();

    const textStyle = TextStyle(color: _Blue.ink, fontWeight: FontWeight.w500);

    return Scaffold(
      backgroundColor: _Blue.bg,
      appBar: AppBar(
        backgroundColor: _Blue.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _Blue.ink),
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Ubah Produk' : 'Tambah Produk',
          style: const TextStyle(color: _Blue.ink, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                enabled: !_saving,
                style: textStyle,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    _dec('Nama produk', icon: Icons.shopping_bag_outlined),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama produk wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: textStyle.copyWith(fontSize: 16),
                decoration: _dec('Kategori', icon: Icons.category_outlined),
                items: categoryItems
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.replaceAll('-', ' ')),
                        ))
                    .toList(),
                onChanged: _saving ? null : (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      enabled: !_saving,
                      style: textStyle,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Harga (USD)', icon: Icons.attach_money),
                      validator: (v) {
                        final n = double.tryParse(
                            (v ?? '').trim().replaceAll(',', '.'));
                        if (n == null || n <= 0) return 'Harga tidak valid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discount,
                      enabled: !_saving,
                      style: textStyle,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _dec('Diskon (%)', icon: Icons.percent),
                      validator: (v) {
                        final n = double.tryParse(
                            (v ?? '').trim().replaceAll(',', '.'));
                        if (n == null || n < 0 || n > 100) return '0 - 100';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stock,
                enabled: !_saving,
                style: textStyle,
                keyboardType: TextInputType.number,
                decoration: _dec('Stok', icon: Icons.inventory_2_outlined),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Stok harus angka 0 atau lebih';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _desc,
                enabled: !_saving,
                style: textStyle,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Deskripsi', icon: Icons.notes_rounded),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Deskripsi wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thumb,
                enabled: !_saving,
                style: textStyle,
                keyboardType: TextInputType.url,
                decoration: _dec('URL gambar (opsional)',
                    hint: 'https://...', icon: Icons.image_outlined),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return null;
                  if (!t.startsWith('http://') && !t.startsWith('https://')) {
                    return 'URL harus diawali http:// atau https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _Blue.deep,
                    disabledBackgroundColor: _Blue.deep.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          _isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
