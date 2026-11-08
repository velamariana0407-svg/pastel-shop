import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

/// Form untuk TAMBAH (product == null) dan UBAH (product != null).
/// Saat sukses, halaman ini menutup diri dan mengembalikan Product.
class ProductFormScreen extends StatefulWidget {
  final Product? product;
  final List<String> categories;

  const ProductFormScreen({Key? key, this.product, required this.categories})
      : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  static const Color bgColor = Color(0xFFFDFBF7);
  static const Color textColor = Color(0xFF4A4E69);
  static const Color accentColor = Color(0xFFB5EAD7);
  static const Color coral = Color(0xFFF8AFA6);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _thumbCtrl;
  String? _category;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p == null ? '' : p.price.toString());
    _thumbCtrl = TextEditingController(text: p?.thumbnail ?? '');
    _category = p?.category;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _thumbCtrl.dispose();
    super.dispose();
  }

  String _placeholder(String title) =>
      'https://dummyjson.com/image/400x400/ffd6e0/4a4e69?text=${Uri.encodeComponent(title)}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    final old = widget.product;
    final title = _titleCtrl.text.trim();
    final thumbInput = _thumbCtrl.text.trim();
    final thumb = thumbInput.isEmpty ? _placeholder(title) : thumbInput;

    final product = Product(
      id: old?.id ?? 0, // id produk baru diberikan oleh halaman depan
      title: title,
      description: _descCtrl.text.trim(),
      price: double.parse(_priceCtrl.text.trim().replaceAll(',', '.')),
      rating: old?.rating ?? 0,
      category: _category!,
      thumbnail: thumb,
      images: (old != null && thumb == old.thumbnail) ? old.images : [thumb],
      isLocal: old?.isLocal ?? false,
    );

    try {
      if (_isEdit) {
        await ApiService.updateProduct(product); // PUT
      } else {
        await ApiService.createProduct(product); // POST
      }
      if (!mounted) return;
      Navigator.pop(context, product);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: coral,
        ),
      );
    }
  }

  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7)),
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
      prefixIcon: icon == null ? null : Icon(icon, color: textColor),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: accentColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: coral, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE76F7A), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE76F7A), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryItems = <String>{
      ...widget.categories,
      if (_category != null) _category!,
    }.toList()
      ..sort();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: textColor),
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Ubah Produk' : 'Tambah Produk',
          style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
                controller: _titleCtrl,
                enabled: !_saving,
                style: const TextStyle(color: textColor),
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Nama produk', icon: Icons.shopping_bag_outlined),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama produk wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                enabled: !_saving,
                style: const TextStyle(color: textColor),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec('Harga (USD)', hint: 'contoh: 19.99', icon: Icons.attach_money),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Masukkan harga yang valid (lebih dari 0)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _category,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(color: textColor, fontSize: 16),
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
              TextFormField(
                controller: _descCtrl,
                enabled: !_saving,
                style: const TextStyle(color: textColor),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Deskripsi', icon: Icons.notes_rounded),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thumbCtrl,
                enabled: !_saving,
                style: const TextStyle(color: textColor),
                keyboardType: TextInputType.url,
                decoration: _dec(
                  'URL gambar (opsional)',
                  hint: 'https://...',
                  icon: Icons.image_outlined,
                ),
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
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: coral,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: coral.withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
