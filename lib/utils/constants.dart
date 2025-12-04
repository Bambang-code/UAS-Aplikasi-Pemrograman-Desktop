import 'package:flutter/material.dart';

// App Constants
class AppConstants {
  static const String appName = 'Cafe Management';
  static const String version = '1.0.0';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleKasir = 'kasir';
  static const String rolePelanggan = 'pelanggan';

  // Payment Methods - UPDATED
  static const String paymentCash = 'Cash';
  static const String paymentQRIS = 'QRIS';
  static const String paymentTransfer = 'Transfer';
  static const String paymentKartu = 'Kartu';

  // Order Status
  static const String statusPending = 'Pending';
  static const String statusProcessing = 'Diproses';
  static const String statusCompleted = 'Selesai';
  static const String statusCancelled = 'Dibatalkan';

  // Table Status
  static const String tableEmpty = 'Kosong';
  static const String tableOccupied = 'Terisi';

  // Status Pembayaran
  static const String pembayaranPending = 'Pending';
  static const String pembayaranLunas = 'Lunas';
  static const String pembayaranGagal = 'Gagal';

  // Status Pesanan
  static const String pesananMenunggu = 'Menunggu';
  static const String pesananDiproses = 'Diproses';
  static const String pesananDikirim = 'Dikirim';
  static const String pesananSelesai = 'Selesai';

  static const List<String> statusPembayaran = [
    pembayaranPending,
    pembayaranLunas,
    pembayaranGagal,
  ];

  static const List<String> statusPesanan = [
    pesananMenunggu,
    pesananDiproses,
    pesananDikirim,
    pesananSelesai,
  ];

  // Categories
  static const List<String> menuCategories = [
    'Minuman',
    'Makanan',
    'Snack',
    'Dessert',
  ];
}

// Color Palette
class AppColors {
  static const Color primary = Color(0xFF6D4C41);
  static const Color secondary = Color(0xFFD7CCC8);
  static const Color accent = Color(0xFFFF6F00);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
}

// Text Styles
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle body1 = TextStyle(fontSize: 16);

  static const TextStyle body2 = TextStyle(fontSize: 14);

  static const TextStyle caption = TextStyle(fontSize: 12, color: Colors.grey);
}
