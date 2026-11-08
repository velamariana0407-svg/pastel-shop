# Pastel Shop 🛍️

Aplikasi mobile katalog produk bertema **biru pastel**, dibuat dengan **Flutter** dan berjalan langsung di handphone (bukan di browser). Data diambil dari API [DummyJSON Products](https://dummyjson.com/docs/products).

## 🎥 Video Penjelasan & Demo

**YouTube:** https://youtu.be/95lxPkgH3EQ?si=zqCCv0uYpvgYcJXH

## 👤 Identitas

- **Nama:** Vela Serli Mariana
- **NIM:** 240102128
- **Kelas:** IF24B

## Fitur

- **Halaman depan**: seluruh produk (194 produk) dalam grid 2 kolom dengan skema warna biru pastel.
- **Halaman detail produk**: galeri gambar, harga dan diskon, rating, stok, info pengiriman/garansi, dan ulasan. Dibuka dengan mengetuk produk di halaman depan.
- **Search fungsional**: pencarian ke server (`/products/search`) lewat tombol search atau tombol enter di keyboard, lengkap dengan tombol hapus (X).
- **CRUD lengkap**: **tambah**, **ubah**, dan **hapus** produk (lihat tabel di bawah).
- Pull-to-refresh, tampilan loading, tampilan error dengan tombol "Coba lagi", dan validasi form.

## CRUD

| Aksi | Cara memakai | Endpoint |
|---|---|---|
| **Tambah** (Create) | Tombol **+ Tambah** di halaman depan, isi form, lalu simpan | `POST /products/add` |
| **Lihat** (Read) | Daftar produk, halaman detail, search, dan tarik layar ke bawah untuk refresh | `GET /products?limit=0` dan `GET /products/search?q=` |
| **Ubah** (Update) | Buka detail produk, ketuk ikon **pensil** di pojok kanan atas, ubah data, lalu simpan | `PUT /products/{id}` |
| **Hapus** (Delete) | Buka detail produk, ketuk ikon **tong sampah** di pojok kanan atas, lalu konfirmasi | `DELETE /products/{id}` |

> **Catatan penting:** DummyJSON hanya **mensimulasikan** operasi tambah, ubah, dan hapus. Server membalas sukses, tetapi data aslinya tidak benar-benar berubah.
> Karena itu, setelah server membalas sukses, perubahan dicatat di aplikasi (`ProductStore`) dan diterapkan ke setiap hasil `GET`, termasuk saat search dan refresh. Perubahan **hilang saat aplikasi ditutup dan dibuka lagi**.
> Produk yang dibuat lewat aplikasi tidak ada di server. Saat produk itu diubah atau dihapus, aplikasi tidak memanggil server (akan 404), cukup memperbarui datanya di aplikasi.

## Struktur Proyek

```
lib/
├── main.dart
├── models/
│   └── product.dart               # model data (+ toJson untuk POST/PUT)
├── services/
│   ├── product_service.dart       # semua pemanggilan API (GET, POST, PUT, DELETE)
│   └── product_store.dart         # menyimpan perubahan tambah/ubah/hapus selama app berjalan
├── screens/
│   ├── home_screen.dart           # halaman depan: grid produk, search, tombol Tambah
│   ├── detail_screen.dart         # halaman detail: tombol Ubah dan Hapus
│   └── product_form_screen.dart   # form tambah / ubah produk
├── widgets/
│   └── product_card.dart          # kartu produk
└── theme/
    └── app_colors.dart
```

## Teknologi

- Flutter (Dart)
- Package [`http`](https://pub.dev/packages/http) untuk memanggil REST API
- API: [DummyJSON](https://dummyjson.com/docs/products)

## Cara Menjalankan (di HP)

1. Pastikan Flutter sudah terpasang (`flutter doctor`).
2. Aktifkan **USB debugging** di HP Android, lalu colok ke laptop.
3. Jalankan perintah berikut di folder proyek:

```bash
flutter pub get
flutter devices     # pastikan HP terdeteksi
flutter run         # pilih HP, bukan Chrome/Windows
```

Pastikan `android/app/src/main/AndroidManifest.xml` memuat izin internet:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### Build APK

```bash
flutter build apk --release
```
