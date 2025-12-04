// services/user_service.dart
import '../models/user.dart';
import 'db_helper.dart';

class UserService {
  final DBHelper _dbHelper = DBHelper();

  Future<User?> login(String username, String password) async {
    final data = await _dbHelper.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (data.isEmpty) return null;
    return User.fromMap(data.first);
  }

  Future<List<User>> getAllUsers() async {
    final data = await _dbHelper.query('users');
    return data.map((u) => User.fromMap(u)).toList();
  }

  Future<int> addUser(User user) async {
    return await _dbHelper.insert('users', user.toMap());
  }

  Future<int> updateUser(User user) async {
    return await _dbHelper.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    return await _dbHelper.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isUsernameExists(String username) async {
    final data = await _dbHelper.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return data.isNotEmpty;
  }

  Future<int> changePassword(int userId, String newPassword) async {
    return await _dbHelper.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
