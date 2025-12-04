# ☕ Cafe Management System

Aplikasi manajemen cafe lengkap yang dibangun dengan Flutter untuk desktop (Windows, Linux, macOS). Sistem ini mendukung manajemen menu, meja, pesanan, pembayaran, dan laporan penjualan dengan antarmuka yang modern dan user-friendly.

---

## ✨ Fitur Utama

### 👤 Multi-Role System
- **Admin**: Akses penuh ke seluruh sistem
- **Kasir**: Kelola pesanan, konfirmasi pembayaran, cetak struk
- **Pelanggan**: Pesan menu, tracking pesanan, lihat riwayat

### 🍽️ Manajemen Menu
- CRUD menu dengan kategori (Minuman, Makanan, Snack, Dessert)
- Upload foto menu (support base64)
- Manajemen stok otomatis
- Filter dan pencarian menu
- Category chips dengan icon

### 🪑 Manajemen Meja
- Status meja real-time (Kosong/Terisi)
- QR Code untuk setiap meja
- Auto update status saat order dibuat
- Opsi Takeaway untuk order tanpa meja

### 📦 Sistem Pesanan
- **Status Pembayaran**: Pending, Lunas, Gagal
- **Status Pesanan**: Menunggu, Diproses, Dikirim, Selesai
- Upload bukti transfer (QRIS/Transfer)
- Sistem promo code (CAFE10, CAFE20)
- Multiple payment methods (Cash, QRIS, Transfer, Kartu)
- Auto refresh pesanan (3-5 detik)

### 💰 Pembayaran & Kasir
- Konfirmasi pembayaran dengan verifikasi bukti
- Perhitungan kembalian otomatis (Cash)
- Cetak struk pembayaran (PDF)
- Lihat detail pesanan lengkap

### 📊 Dashboard & Laporan
- **Dashboard Admin** dengan 2 tab:
  - Overview: Stats cards, Quick actions
  - Grafik Analisis: 6+ jenis grafik interaktif
- **Charts**:
  - Penjualan 7 hari terakhir (Line Chart)
  - Penjualan per kategori (Pie Chart)
  - Top 10 menu terlaris (Bar Chart)
  - Metode pembayaran (Pie Chart)
  - Perbandingan minggu ini vs minggu lalu
  - Distribusi status pesanan
- **Laporan**:
  - Filter per periode (Hari Ini, Minggu Ini, Bulan Ini, Custom)
  - Filter per metode pembayaran
  - Export PDF
  - Hapus pesanan (Admin only)

### 🎨 UI/UX Features
- Modern gradient design
- Dark mode support
- Loading screen dengan animasi
- Splash screen dengan fireworks animation
- Auto refresh data
- Responsive layout
- Animated transitions
- Material Design 3

---

## 🚀 Teknologi

### Framework & Libraries
```yaml
dependencies:
  flutter: ^3.0.0
  sqflite_common_ffi: ^2.3.0  # Database SQLite untuk desktop
  path: ^1.8.3
  provider: ^6.1.1              # State management
  intl: ^0.18.1                 # Format tanggal & currency
  qr_flutter: ^4.1.0            # Generate QR Code
  file_picker: ^6.1.1           # Upload file
  pdf: ^3.10.7                  # Generate PDF
  printing: ^5.12.0             # Print PDF
  fl_chart: ^0.66.0             # Charts & grafik
```

### Database Schema
```sql
-- Users (Admin, Kasir, Pelanggan)
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  role TEXT NOT NULL
);

-- Menu
CREATE TABLE menu (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nama TEXT NOT NULL,
  kategori TEXT NOT NULL,
  harga REAL NOT NULL,
  stok INTEGER NOT NULL,
  foto TEXT
);

-- Meja dengan QR Code
CREATE TABLE meja (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nomor_meja TEXT UNIQUE NOT NULL,
  status TEXT NOT NULL,
  qr_code TEXT
);

-- Pesanan
CREATE TABLE pesanan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pelanggan_id INTEGER NOT NULL,
  nomor_meja TEXT NOT NULL,
  subtotal REAL NOT NULL,
  diskon REAL DEFAULT 0,
  total REAL NOT NULL,
  status_pembayaran TEXT DEFAULT 'Pending',
  status_pesanan TEXT DEFAULT 'Menunggu',
  tanggal TEXT NOT NULL,
  metode_pembayaran TEXT,
  bukti_transfer TEXT,
  FOREIGN KEY (pelanggan_id) REFERENCES users (id)
);

-- Detail Pesanan
CREATE TABLE detail_pesanan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pesanan_id INTEGER NOT NULL,
  menu_id INTEGER NOT NULL,
  jumlah INTEGER NOT NULL,
  subtotal REAL NOT NULL,
  FOREIGN KEY (pesanan_id) REFERENCES pesanan (id),
  FOREIGN KEY (menu_id) REFERENCES menu (id)
);
```

---

## 📦 Instalasi

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Git

### Clone Repository
```bash
git clone https://github.com/Bambang-code/cafe-management-system.git
cd cafe-management-system
```

### Install Dependencies
```bash
flutter pub get
```

### Run Application
```bash
# Windows
flutter run -d windows

# Linux
flutter run -d linux

# macOS
flutter run -d macos
```

### Build Release
```bash
# Windows
flutter build windows --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release
```

---

## 👥 Default Users

### Admin
- Username: `admin`
- Password: `admin123`
- Akses: Full control

### Kasir
- Username: `kasir`
- Password: `kasir123`
- Akses: Pesanan, Pembayaran, Menu, Meja

### Pelanggan
- Register manual di aplikasi
- Akses: Pesan menu, Tracking, Riwayat

---

## 🎯 Cara Penggunaan

### 1️⃣ Alur Admin
1. Login sebagai admin
2. Dashboard → Lihat statistik & grafik
3. Menu → Kelola menu (CRUD)
4. Meja → Kelola meja & QR Code
5. User → Tambah/edit user
6. Laporan → Export & analisis

### 2️⃣ Alur Kasir
1. Login sebagai kasir
2. Pesanan → Monitor pesanan masuk
3. Klik pesanan → Konfirmasi/Tolak pembayaran
4. Update status pesanan (Diproses → Dikirim → Selesai)
5. Cetak struk jika lunas

### 3️⃣ Alur Pelanggan
1. Register/Login
2. Pilih Meja atau Takeaway
3. Browse menu → Tambah ke keranjang
4. Checkout → Pilih metode pembayaran
5. Upload bukti (jika QRIS/Transfer)
6. Tracking pesanan real-time
7. Lihat riwayat & struk

---

## 🎨 Fitur Promo

Gunakan kode promo saat checkout:
- **CAFE10**: Diskon 10%
- **CAFE20**: Diskon 20%

---

## 📸 Screenshots

### Loading Screen
![Loading Screen](screenshots/loading.png)

### Splash Screen dengan Fireworks
![Splash Screen](screenshots/splash.png)

### Dashboard Admin
![Dashboard](screenshots/dashboard.png)

### Grafik Analisis
![Charts](screenshots/charts.png)

### Manajemen Menu
![Menu](screenshots/menu.png)

### Kasir - Pesanan
![Kasir](screenshots/kasir.png)

### Pelanggan - Order
![Pelanggan](screenshots/pelanggan.png)

---

## 🔧 Troubleshooting

### Database Error "no such table"
```dart
// Di login_screen.dart ada tombol "Reset Database"
// Atau jalankan:
await DBHelper().resetDatabase();
```

### Port sudah digunakan
```bash
flutter run -d windows --dart-define=PORT=8081
```

### Build gagal di Windows
```bash
flutter clean
flutter pub get
flutter build windows --release
```

---

## 📁 Struktur Project
```
lib/
├── main.dart                    # Entry point & theme
├── models/                      # Data models
│   ├── user.dart
│   ├── menu.dart
│   ├── meja.dart
│   ├── pesanan.dart
│   ├── detail_pesanan.dart
│   └── cart_item.dart
├── services/                    # Business logic
│   ├── db_helper.dart
│   ├── user_service.dart
│   ├── menu_service.dart
│   └── pesanan_service.dart
├── screens/                     # UI Screens
│   ├── loading_screen.dart
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── dashboard_screen.dart
│   ├── menu_screen.dart
│   ├── meja_screen.dart
│   ├── user_screen.dart
│   ├── order_screen.dart
│   ├── payment_screen.dart
│   ├── report_screen.dart
│   ├── kasir_*.dart             # Kasir screens
│   └── pelanggan_*.dart         # Pelanggan screens
├── widgets/                     # Reusable widgets
│   ├── custom_button.dart
│   ├── menu_card.dart
│   ├── report_table.dart
│   └── dashboard_charts.dart
└── utils/                       # Utilities
    ├── constants.dart
    └── helpers.dart
```

---

## 🛠️ Development

### Add New Feature
1. Create model di `models/`
2. Create service di `services/`
3. Create screen di `screens/`
4. Update routes jika perlu
5. Test thoroughly

### Database Migration
Edit `db_helper.dart`:
```dart
// Increment version
version: 6, // dari 5 ke 6

// Tambah logic di _onUpgrade
if (oldVersion < 6) {
  await db.execute('ALTER TABLE...');
}
```

---

## 📝 TODO / Future Features

- [ ] Multi-tenant support
- [ ] SMS/Email notifications
- [ ] Loyalty program
- [ ] Kitchen display system
- [ ] Mobile app (iOS/Android)
- [ ] Online ordering
- [ ] Inventory management
- [ ] Employee shift management
- [ ] Customer feedback system
- [ ] Integration dengan payment gateway

---

## 🤝 Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Developer

**Your Name**
- GitHub: [@Bambang-code](https://github.com/Bambang-code)

---

## 🙏 Acknowledgments

- Flutter Team untuk framework yang luar biasa
- Material Design untuk design guidelines
- Community packages yang digunakan
- Inspirasi dari berbagai POS systems

---

## 📞 Support

Jika ada pertanyaan atau issue:
1. Check [Issues](https://github.com/Bambang-code/cafe-management-system/issues)
2. Create new issue dengan label yang sesuai
3. Email ke: support@example.com

---

**⭐ Jika project ini membantu, jangan lupa beri star! ⭐**

---

## 📊 Statistics

![GitHub stars](https://img.shields.io/github/stars/Bambang-code/cafe-management-system?style=social)
![GitHub forks](https://img.shields.io/github/forks/Bambang-code/cafe-management-system?style=social)
![GitHub issues](https://img.shields.io/github/issues/Bambang-code/cafe-management-system)
![GitHub license](https://img.shields.io/github/license/Bambang-code/cafe-management-system)

---

Made with ❤️ and ☕ by [Kelompok 5]