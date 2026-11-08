import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  static const String baseUrl = 'https://dummyjson.com/products';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };
  static const Duration _timeout = Duration(seconds: 15);

  /// Membungkus request: kalau gagal konek / timeout, lempar pesan yang ramah.
  static Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(_timeout);
    } catch (_) {
      throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet.');
    }
  }

  // ---------- READ ----------
  /// limit=0 -> ambil SEMUA produk (bukan hanya 100).
  static Future<List<Product>> fetchProducts() async {
    final response = await _send(http.get(Uri.parse('$baseUrl?limit=0')));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List productsJson = data['products'];
      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat produk (${response.statusCode})');
    }
  }

  // ---------- CREATE ----------
  /// POST /products/add
  static Future<void> createProduct(Product product) async {
    final response = await _send(http.post(
      Uri.parse('$baseUrl/add'),
      headers: _headers,
      body: json.encode(product.toJson()),
    ));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Gagal menambah produk (${response.statusCode})');
    }
  }

  // ---------- UPDATE ----------
  /// PUT /products/{id}
  static Future<void> updateProduct(Product product) async {
    // Produk buatan lokal tidak ada di server -> cukup update di aplikasi.
    if (product.isLocal) return;
    final response = await _send(http.put(
      Uri.parse('$baseUrl/${product.id}'),
      headers: _headers,
      body: json.encode(product.toJson()),
    ));
    if (response.statusCode != 200) {
      throw Exception('Gagal mengubah produk (${response.statusCode})');
    }
  }

  // ---------- DELETE ----------
  /// DELETE /products/{id}
  static Future<void> deleteProduct(Product product) async {
    if (product.isLocal) return;
    final response = await _send(http.delete(Uri.parse('$baseUrl/${product.id}')));
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus produk (${response.statusCode})');
    }
  }
}
