class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final double rating;
  final String category;
  final String thumbnail;
  final List<String> images;

  /// true = produk dibuat lewat aplikasi (tidak ada di server DummyJSON),
  /// jadi tidak perlu dipanggil PUT/DELETE ke server (akan 404).
  final bool isLocal;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rating,
    required this.category,
    required this.thumbnail,
    required this.images,
    this.isLocal = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      category: json['category'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      images: List<String>.from(json['images'] ?? []),
    );
  }

  /// Body JSON untuk POST (tambah) dan PUT (ubah).
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'rating': rating,
      'category': category,
      'thumbnail': thumbnail,
      'images': images,
    };
  }

  Product copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    double? rating,
    String? category,
    String? thumbnail,
    List<String>? images,
    bool? isLocal,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      category: category ?? this.category,
      thumbnail: thumbnail ?? this.thumbnail,
      images: images ?? this.images,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}
