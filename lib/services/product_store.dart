import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// Menyimpan perubahan produk (tambah / ubah / hapus) selama aplikasi berjalan.
///
/// DummyJSON hanya MENSIMULASIKAN POST / PUT / DELETE (server membalas sukses,
/// tetapi datanya tidak benar-benar berubah). Karena itu perubahan yang sudah
/// disetujui server dicatat di sini, lalu diterapkan ke setiap hasil GET
/// (termasuk saat search dan refresh) supaya daftar produk tetap konsisten.
class ProductStore extends ChangeNotifier {
  ProductStore._();
  static final ProductStore instance = ProductStore._();

  final List<Product> _created = []; // produk baru buatan aplikasi
  final Map<int, Product> _edited = {}; // produk server yang diubah
  final Set<int> _deleted = {}; // id produk server yang dihapus
  final Set<String> _categories = {};
  int _seq = 10000; // id produk baru (jauh di atas id milik server)

  /// Semua kategori yang pernah dimuat dari server.
  List<String> get categories => _categories.toList()..sort();

  int newLocalId() => ++_seq;

  /// Dipanggil setiap kali data baru dari server berhasil dimuat.
  void registerFetched(List<Product> items) {
    for (final p in items) {
      if (p.category.isNotEmpty) _categories.add(p.category);
    }
  }

  /// Terapkan perubahan lokal ke hasil dari server.
  List<Product> apply(List<Product> fetched, String query) {
    final q = query.trim().toLowerCase();
    bool matches(Product p) =>
        q.isEmpty ||
        p.title.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q);

    return [
      ..._created.where(matches),
      for (final p in fetched)
        if (!_deleted.contains(p.id)) _edited[p.id] ?? p,
    ];
  }

  void addCreated(Product p) {
    _created.insert(0, p);
    notifyListeners();
  }

  void update(Product p) {
    if (p.isLocal) {
      final i = _created.indexWhere((e) => e.id == p.id);
      if (i != -1) _created[i] = p;
    } else {
      _edited[p.id] = p;
    }
    notifyListeners();
  }

  void remove(Product p) {
    if (p.isLocal) {
      _created.removeWhere((e) => e.id == p.id);
    } else {
      _deleted.add(p.id);
      _edited.remove(p.id);
    }
    notifyListeners();
  }
}
