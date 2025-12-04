// services/menu_service.dart
import '../models/menu.dart';
import 'db_helper.dart';

class MenuService {
  final DBHelper _dbHelper = DBHelper();

  Future<List<Menu>> getAllMenu() async {
    final data = await _dbHelper.query('menu');
    return data.map((m) => Menu.fromMap(m)).toList();
  }

  Future<List<Menu>> getMenuByCategory(String category) async {
    final data = await _dbHelper.query(
      'menu',
      where: 'kategori = ?',
      whereArgs: [category],
    );
    return data.map((m) => Menu.fromMap(m)).toList();
  }

  Future<Menu?> getMenuById(int id) async {
    final data = await _dbHelper.query(
      'menu',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (data.isEmpty) return null;
    return Menu.fromMap(data.first);
  }

  Future<int> addMenu(Menu menu) async {
    return await _dbHelper.insert('menu', menu.toMap());
  }

  Future<int> updateMenu(Menu menu) async {
    return await _dbHelper.update(
      'menu',
      menu.toMap(),
      where: 'id = ?',
      whereArgs: [menu.id],
    );
  }

  Future<int> deleteMenu(int id) async {
    return await _dbHelper.delete('menu', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateStok(int menuId, int newStok) async {
    return await _dbHelper.update(
      'menu',
      {'stok': newStok},
      where: 'id = ?',
      whereArgs: [menuId],
    );
  }

  Future<List<Menu>> searchMenu(String keyword) async {
    final data = await _dbHelper.rawQuery(
      'SELECT * FROM menu WHERE nama LIKE ? OR kategori LIKE ?',
      ['%$keyword%', '%$keyword%'],
    );
    return data.map((m) => Menu.fromMap(m)).toList();
  }
}
