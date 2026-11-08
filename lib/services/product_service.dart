import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

/// Mengambil data produk dari https://dummyjson.com/docs/products
class ProductService {
  static const _base = 'https://dummyjson.com';

  /// Jika [query] kosong -> semua produk. Jika ada -> hasil pencarian.
  /// `limit=0` membuat DummyJSON mengembalikan seluruh data.
  Future<List<Product>> fetchProducts({String query = ''}) async {
    final q = query.trim();
    final uri = q.isEmpty
        ? Uri.parse('$_base/products?limit=0')
        : Uri.parse('$_base/products/search')
            .replace(queryParameters: {'q': q, 'limit': '0'});

    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('Gagal memuat data (kode ${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['products'] as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ------------------------------------------------------------------
  // CREATE / UPDATE / DELETE
  // ------------------------------------------------------------------
  static const _headers = {'Content-Type': 'application/json'};

  /// Membungkus request: kalau gagal konek / timeout, lempar pesan yang ramah.
  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(const Duration(seconds: 20));
    } catch (_) {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  /// POST /products/add
  Future<void> createProduct(Product product) async {
    final res = await _send(http.post(
      Uri.parse('$_base/products/add'),
      headers: _headers,
      body: jsonEncode(product.toJson()),
    ));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Gagal menambah produk (kode ${res.statusCode})');
    }
  }

  /// PUT /products/{id}
  Future<void> updateProduct(Product product) async {
    // Produk buatan aplikasi tidak ada di server -> cukup diubah di aplikasi.
    if (product.isLocal) return;
    final res = await _send(http.put(
      Uri.parse('$_base/products/${product.id}'),
      headers: _headers,
      body: jsonEncode(product.toJson()),
    ));
    if (res.statusCode != 200) {
      throw Exception('Gagal mengubah produk (kode ${res.statusCode})');
    }
  }

  /// DELETE /products/{id}
  Future<void> deleteProduct(Product product) async {
    if (product.isLocal) return;
    final res = await _send(http.delete(Uri.parse('$_base/products/${product.id}')));
    if (res.statusCode != 200) {
      throw Exception('Gagal menghapus produk (kode ${res.statusCode})');
    }
  }
}
