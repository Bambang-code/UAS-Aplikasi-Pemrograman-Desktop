import '../services/db_helper.dart';
import '../models/pesanan.dart';
import '../models/detail_pesanan.dart';
import '../models/cart_item.dart';

class PesananService {
  final DBHelper _dbHelper = DBHelper();

  // Create pesanan baru
  Future<int> createPesanan({
    required int pelangganId,
    required List<CartItem> cart,
    required String nomorMeja,
    double diskon = 0,
    String? metodePembayaran,
    String? buktiTransfer,
  }) async {
    final subtotal = cart.fold<double>(0, (sum, item) => sum + item.subtotal);
    final total = subtotal - diskon;

    final pesanan = Pesanan(
      pelangganId: pelangganId,
      nomorMeja: nomorMeja,
      subtotal: subtotal,
      diskon: diskon,
      total: total,
      statusPembayaran: 'Pending',
      statusPesanan: 'Menunggu',
      tanggal: DateTime.now(),
      metodePembayaran: metodePembayaran,
      buktiTransfer: buktiTransfer,
    );

    final pesananId = await _dbHelper.insert('pesanan', pesanan.toMap());

    // Insert detail pesanan
    for (var item in cart) {
      final detail = DetailPesanan(
        pesananId: pesananId,
        menuId: item.menu.id!,
        jumlah: item.quantity,
        subtotal: item.subtotal,
      );
      await _dbHelper.insert('detail_pesanan', detail.toMap());

      // Update stok menu
      await _dbHelper.rawQuery(
        'UPDATE menu SET stok = stok - ? WHERE id = ?',
        [item.quantity, item.menu.id],
      );
    }

    // Update status meja
    await _dbHelper.update(
      'meja',
      {'status': 'Terisi'},
      where: 'nomor_meja = ?',
      whereArgs: [nomorMeja],
    );

    return pesananId;
  }

  // Get pesanan by status pembayaran
  Future<List<Pesanan>> getPesananByStatusPembayaran(String status) async {
    final data = await _dbHelper.query(
      'pesanan',
      where: 'status_pembayaran = ?',
      whereArgs: [status],
    );
    return data.map((e) => Pesanan.fromMap(e)).toList();
  }

  // Get pesanan by status pesanan
  Future<List<Pesanan>> getPesananByStatusPesanan(String status) async {
    final data = await _dbHelper.query(
      'pesanan',
      where: 'status_pesanan = ?',
      whereArgs: [status],
    );
    return data.map((e) => Pesanan.fromMap(e)).toList();
  }

  // Get all pesanan
  Future<List<Pesanan>> getAllPesanan() async {
    final data = await _dbHelper.rawQuery(
      'SELECT p.*, u.username as pelanggan_nama FROM pesanan p LEFT JOIN users u ON p.pelanggan_id = u.id ORDER BY tanggal DESC',
    );
    return data.map((e) => Pesanan.fromMap(e)).toList();
  }

  // Update status pembayaran - UPDATED (Kosongkan meja jika Gagal)
  Future<void> updateStatusPembayaran(int id, String status) async {
    await _dbHelper.update(
      'pesanan',
      {'status_pembayaran': status},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Jika pembayaran GAGAL, kosongkan meja dan kembalikan stok
    if (status == 'Gagal') {
      final pesananData = await getPesananById(id);
      if (pesananData != null) {
        // Kosongkan meja
        await _dbHelper.update(
          'meja',
          {'status': 'Kosong'},
          where: 'nomor_meja = ?',
          whereArgs: [pesananData.nomorMeja],
        );

        // Kembalikan stok menu
        final details = await getDetailPesanan(id);
        for (var detail in details) {
          await _dbHelper.rawQuery(
            'UPDATE menu SET stok = stok + ? WHERE id = ?',
            [detail.jumlah, detail.menuId],
          );
        }
      }
    }
  }

  // Update status pesanan
  Future<void> updateStatusPesanan(int id, String status) async {
    await _dbHelper.update(
      'pesanan',
      {'status_pesanan': status},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Jika status pesanan = Selesai, kosongkan meja
    if (status == 'Selesai') {
      final pesananData = await getPesananById(id);
      if (pesananData != null) {
        await _dbHelper.update(
          'meja',
          {'status': 'Kosong'},
          where: 'nomor_meja = ?',
          whereArgs: [pesananData.nomorMeja],
        );
      }
    }
  }

  // Get pesanan by ID
  Future<Pesanan?> getPesananById(int id) async {
    final data = await _dbHelper.query(
      'pesanan',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return Pesanan.fromMap(data.first);
  }

  // Get detail pesanan
  Future<List<DetailPesanan>> getDetailPesanan(int pesananId) async {
    final data = await _dbHelper.rawQuery('''
      SELECT dp.*, m.nama as nama_menu, m.harga as harga_satuan
      FROM detail_pesanan dp
      JOIN menu m ON dp.menu_id = m.id
      WHERE dp.pesanan_id = ?
    ''', [pesananId]);

    return data.map((e) => DetailPesanan.fromMap(e)).toList();
  }

  // Complete pesanan (untuk kasir payment)
  Future<void> completePesanan(int id) async {
    await updateStatusPembayaran(id, 'Lunas');
    await updateStatusPesanan(id, 'Selesai');
  }

  // Get dashboard stats (untuk menggantikan transaksi_service)
  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Pesanan hari ini yang sudah lunas
    final todayPesanan = await _dbHelper.rawQuery(
      "SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as revenue FROM pesanan WHERE tanggal >= ? AND tanggal < ? AND status_pembayaran = 'Lunas'",
      [today.toIso8601String(), tomorrow.toIso8601String()],
    );

    final menuCount = await _dbHelper.rawQuery(
      'SELECT COUNT(*) as count FROM menu',
    );

    final tableStats = await _dbHelper.rawQuery(
      "SELECT COUNT(*) as total, SUM(CASE WHEN status = 'Terisi' THEN 1 ELSE 0 END) as occupied FROM meja",
    );

    return {
      'today_transactions': todayPesanan.first['count'],
      'today_revenue': todayPesanan.first['revenue'],
      'total_menu': menuCount.first['count'],
      'total_tables': tableStats.first['total'],
      'occupied_tables': tableStats.first['occupied'],
    };
  }

  // Get pesanan by date range untuk laporan
  Future<List<Map<String, dynamic>>> getPesananByDateRange(
    DateTime start,
    DateTime end, {
    String? paymentMethod,
  }) async {
    String query = '''
      SELECT p.*, u.username as pelanggan_nama
      FROM pesanan p
      LEFT JOIN users u ON p.pelanggan_id = u.id
      WHERE p.tanggal BETWEEN ? AND ?
      AND p.status_pembayaran = 'Lunas'
    ''';

    List<dynamic> args = [start.toIso8601String(), end.toIso8601String()];

    if (paymentMethod != null) {
      query += ' AND p.metode_pembayaran = ?';
      args.add(paymentMethod);
    }

    query += ' ORDER BY p.tanggal DESC';

    return await _dbHelper.rawQuery(query, args);
  }

  Future<void> deletePesanan(int id) async {
  // Get pesanan data untuk kembalikan stok
  final pesananData = await getPesananById(id);
  if (pesananData != null) {
    // Kembalikan stok menu
    final details = await getDetailPesanan(id);
    for (var detail in details) {
      await _dbHelper.rawQuery(
        'UPDATE menu SET stok = stok + ? WHERE id = ?',
        [detail.jumlah, detail.menuId],
      );
    }

    // Kosongkan meja jika terisi
    await _dbHelper.update(
      'meja',
      {'status': 'Kosong'},
      where: 'nomor_meja = ?',
      whereArgs: [pesananData.nomorMeja],
    );
  }

  await _dbHelper.delete(
      'detail_pesanan',
      where: 'pesanan_id = ?',
      whereArgs: [id],
    );

    // Hapus pesanan
    await _dbHelper.delete(
      'pesanan',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 1. Data penjualan per hari (7 hari terakhir)
  Future<List<Map<String, dynamic>>> getDailySalesChart() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    final data = await _dbHelper.rawQuery('''
    SELECT 
      DATE(tanggal) as date,
      COUNT(*) as total_orders,
      COALESCE(SUM(total), 0) as revenue
    FROM pesanan
    WHERE tanggal >= ? 
    AND status_pembayaran = 'Lunas'
    GROUP BY DATE(tanggal)
    ORDER BY date ASC
  ''', [sevenDaysAgo.toIso8601String()]);

    return data;
  }

// 2. Penjualan per kategori menu
  Future<List<Map<String, dynamic>>> getSalesByCategory() async {
    final data = await _dbHelper.rawQuery('''
    SELECT 
      m.kategori,
      COUNT(dp.id) as total_orders,
      COALESCE(SUM(dp.subtotal), 0) as revenue
    FROM detail_pesanan dp
    JOIN menu m ON dp.menu_id = m.id
    JOIN pesanan p ON dp.pesanan_id = p.id
    WHERE p.status_pembayaran = 'Lunas'
    GROUP BY m.kategori
    ORDER BY revenue DESC
  ''');

    return data;
  }

// 3. Top 10 menu terlaris
  Future<List<Map<String, dynamic>>> getTopSellingMenu({int limit = 10}) async {
    final data = await _dbHelper.rawQuery('''
    SELECT 
      m.nama,
      m.kategori,
      SUM(dp.jumlah) as total_quantity,
      COALESCE(SUM(dp.subtotal), 0) as revenue
    FROM detail_pesanan dp
    JOIN menu m ON dp.menu_id = m.id
    JOIN pesanan p ON dp.pesanan_id = p.id
    WHERE p.status_pembayaran = 'Lunas'
    GROUP BY m.id
    ORDER BY total_quantity DESC
    LIMIT ?
  ''', [limit]);

    return data;
  }

// 4. Penjualan per metode pembayaran
  Future<List<Map<String, dynamic>>> getSalesByPaymentMethod() async {
    final data = await _dbHelper.rawQuery('''
    SELECT 
      metode_pembayaran,
      COUNT(*) as total_orders,
      COALESCE(SUM(total), 0) as revenue
    FROM pesanan
    WHERE status_pembayaran = 'Lunas'
    AND metode_pembayaran IS NOT NULL
    GROUP BY metode_pembayaran
    ORDER BY revenue DESC
  ''');

    return data;
  }

// 5. Penjualan per jam (untuk analisis jam ramai)
  Future<List<Map<String, dynamic>>> getSalesByHour() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final data = await _dbHelper.rawQuery('''
    SELECT 
      CAST(strftime('%H', tanggal) AS INTEGER) as hour,
      COUNT(*) as total_orders,
      COALESCE(SUM(total), 0) as revenue
    FROM pesanan
    WHERE tanggal >= ? AND tanggal < ?
    AND status_pembayaran = 'Lunas'
    GROUP BY hour
    ORDER BY hour ASC
  ''', [today.toIso8601String(), tomorrow.toIso8601String()]);

    return data;
  }

// 6. Perbandingan penjualan minggu ini vs minggu lalu
  Future<Map<String, dynamic>> getWeeklyComparison() async {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart;

    // Minggu ini
    final thisWeek = await _dbHelper.rawQuery('''
    SELECT 
      COUNT(*) as total_orders,
      COALESCE(SUM(total), 0) as revenue
    FROM pesanan
    WHERE tanggal >= ?
    AND status_pembayaran = 'Lunas'
  ''', [thisWeekStart.toIso8601String()]);

    // Minggu lalu
    final lastWeek = await _dbHelper.rawQuery('''
    SELECT 
      COUNT(*) as total_orders,
      COALESCE(SUM(total), 0) as revenue
    FROM pesanan
    WHERE tanggal >= ? AND tanggal < ?
    AND status_pembayaran = 'Lunas'
  ''', [lastWeekStart.toIso8601String(), lastWeekEnd.toIso8601String()]);

    final thisWeekRevenue = (thisWeek.first['revenue'] as num).toDouble();
    final lastWeekRevenue = (lastWeek.first['revenue'] as num).toDouble();

    final growth = lastWeekRevenue > 0
        ? ((thisWeekRevenue - lastWeekRevenue) / lastWeekRevenue) * 100
        : 0.0;

    return {
      'this_week': thisWeek.first,
      'last_week': lastWeek.first,
      'growth_percentage': growth,
    };
  }

// 7. Status pesanan distribution
  Future<Map<String, int>> getOrderStatusDistribution() async {
    final data = await _dbHelper.rawQuery('''
    SELECT 
      status_pesanan,
      COUNT(*) as count
    FROM pesanan
    WHERE DATE(tanggal) = DATE('now')
    GROUP BY status_pesanan
  ''');

    Map<String, int> distribution = {
      'Menunggu': 0,
      'Diproses': 0,
      'Dikirim': 0,
      'Selesai': 0,
    };

    for (var item in data) {
      distribution[item['status_pesanan']] = item['count'] as int;
    }

    return distribution;
  }

  // Get summary untuk laporan
  Future<Map<String, dynamic>> getSummary(
    DateTime start,
    DateTime end, {
    String? paymentMethod,
  }) async {
    String query = '''
      SELECT 
        COUNT(*) as total_transactions,
        COALESCE(SUM(total), 0) as total_revenue,
        COALESCE(AVG(total), 0) as average
      FROM pesanan
      WHERE tanggal BETWEEN ? AND ?
      AND status_pembayaran = 'Lunas'
    ''';

    List<dynamic> args = [start.toIso8601String(), end.toIso8601String()];

    if (paymentMethod != null) {
      query += ' AND metode_pembayaran = ?';
      args.add(paymentMethod);
    }

    final result = await _dbHelper.rawQuery(query, args);
    return result.first;
  }
}
