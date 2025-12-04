import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cafe.db');

    return await openDatabase(
      path,
      version: 5, // UPDATED VERSION (hapus transaksi)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table users
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      role TEXT NOT NULL
    )
  ''');

    // Table menu
    await db.execute('''
    CREATE TABLE menu (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama TEXT NOT NULL,
      kategori TEXT NOT NULL,
      harga REAL NOT NULL,
      stok INTEGER NOT NULL,
      foto TEXT
    )
  ''');

    // Table meja - WITH qr_code
    await db.execute('''
    CREATE TABLE meja (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nomor_meja TEXT NOT NULL UNIQUE,
      status TEXT NOT NULL,
      qr_code TEXT
    )
  ''');

    // Table pesanan
    await db.execute('''
    CREATE TABLE pesanan (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      pelanggan_id INTEGER NOT NULL,
      nomor_meja TEXT NOT NULL,
      subtotal REAL NOT NULL,
      diskon REAL DEFAULT 0,
      total REAL NOT NULL,
      status_pembayaran TEXT NOT NULL DEFAULT 'Pending',
      status_pesanan TEXT NOT NULL DEFAULT 'Menunggu',
      tanggal TEXT NOT NULL,
      metode_pembayaran TEXT,
      bukti_transfer TEXT,
      FOREIGN KEY (pelanggan_id) REFERENCES users (id)
    )
  ''');

    // Table detail_pesanan
    await db.execute('''
    CREATE TABLE detail_pesanan (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      pesanan_id INTEGER NOT NULL,
      menu_id INTEGER NOT NULL,
      jumlah INTEGER NOT NULL,
      subtotal REAL NOT NULL,
      FOREIGN KEY (pesanan_id) REFERENCES pesanan (id),
      FOREIGN KEY (menu_id) REFERENCES menu (id)
    )
  ''');

    // Insert default data
    await _insertDefaultData(db);
  }

  // Migration untuk upgrade
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Hapus kolom status lama dan tambah 2 status baru
      await db.execute('DROP TABLE IF EXISTS pesanan');
      await db.execute('DROP TABLE IF EXISTS detail_pesanan');

      // Buat ulang tabel dengan struktur baru
      await db.execute('''
      CREATE TABLE pesanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pelanggan_id INTEGER NOT NULL,
        nomor_meja TEXT NOT NULL,
        subtotal REAL NOT NULL,
        diskon REAL DEFAULT 0,
        total REAL NOT NULL,
        status_pembayaran TEXT NOT NULL DEFAULT 'Pending',
        status_pesanan TEXT NOT NULL DEFAULT 'Menunggu',
        tanggal TEXT NOT NULL,
        metode_pembayaran TEXT,
        bukti_transfer TEXT,
        FOREIGN KEY (pelanggan_id) REFERENCES users (id)
      )
    ''');

      await db.execute('''
      CREATE TABLE detail_pesanan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pesanan_id INTEGER NOT NULL,
        menu_id INTEGER NOT NULL,
        jumlah INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (pesanan_id) REFERENCES pesanan (id),
        FOREIGN KEY (menu_id) REFERENCES menu (id)
      )
    ''');
    }

    // Add qr_code column to meja table
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE meja ADD COLUMN qr_code TEXT');

        // Generate QR codes for existing tables
        final mejas = await db.query('meja');
        for (var meja in mejas) {
          final qrCode =
              'QR${DateTime.now().millisecondsSinceEpoch}_${meja['id']}';
          await db.update(
            'meja',
            {'qr_code': qrCode},
            where: 'id = ?',
            whereArgs: [meja['id']],
          );
        }
      } catch (e) {
        print('Error adding qr_code column: $e');
      }
    }

    // HAPUS TABEL TRANSAKSI
    if (oldVersion < 5) {
      try {
        await db.execute('DROP TABLE IF EXISTS transaksi');
        await db.execute('DROP TABLE IF EXISTS detail_transaksi');
        print('Tabel transaksi berhasil dihapus');
      } catch (e) {
        print('Error menghapus tabel transaksi: $e');
      }
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // Default users
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
    });

    await db.insert('users', {
      'username': 'kasir',
      'password': 'kasir123',
      'role': 'kasir',
    });

    // Default meja - WITH qr_code
    for (int i = 1; i <= 10; i++) {
      final qrCode = 'QR${DateTime.now().millisecondsSinceEpoch}_$i';
      await db.insert('meja', {
        'nomor_meja': 'Meja $i',
        'status': 'Kosong',
        'qr_code': qrCode,
      });
    }

    // Default menu
    List<Map<String, dynamic>> defaultMenu = [
      {
        'nama': 'Kopi Hitam',
        'kategori': 'Minuman',
        'harga': 15000,
        'stok': 100,
      },
      {'nama': 'Kopi Susu', 'kategori': 'Minuman', 'harga': 18000, 'stok': 100},
      {
        'nama': 'Cappuccino',
        'kategori': 'Minuman',
        'harga': 20000,
        'stok': 100,
      },
      {'nama': 'Latte', 'kategori': 'Minuman', 'harga': 22000, 'stok': 100},
      {'nama': 'Teh Manis', 'kategori': 'Minuman', 'harga': 10000, 'stok': 100},
      {'nama': 'Jus Jeruk', 'kategori': 'Minuman', 'harga': 15000, 'stok': 50},
      {
        'nama': 'Nasi Goreng',
        'kategori': 'Makanan',
        'harga': 25000,
        'stok': 50,
      },
      {'nama': 'Mie Goreng', 'kategori': 'Makanan', 'harga': 20000, 'stok': 50},
      {'nama': 'Sandwich', 'kategori': 'Makanan', 'harga': 18000, 'stok': 30},
      {'nama': 'French Fries', 'kategori': 'Snack', 'harga': 15000, 'stok': 40},
      {'nama': 'Onion Rings', 'kategori': 'Snack', 'harga': 12000, 'stok': 40},
      {'nama': 'Brownies', 'kategori': 'Dessert', 'harga': 15000, 'stok': 30},
      {'nama': 'Ice Cream', 'kategori': 'Dessert', 'harga': 12000, 'stok': 50},
    ];

    for (var item in defaultMenu) {
      await db.insert('menu', item);
    }
  }

  // Method untuk reset database (hapus dan buat ulang)
  Future<void> resetDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'cafe.db');

      // Tutup database jika terbuka
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Hapus file database
      await deleteDatabase(path);

      // Inisialisasi ulang database dengan skema baru
      _database = await _initDB();

      print('Database berhasil di-reset!');
    } catch (e) {
      print('Error reset database: $e');
      rethrow;
    }
  }

  // CRUD Operations
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs);
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
