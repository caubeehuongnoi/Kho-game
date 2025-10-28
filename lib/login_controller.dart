import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController {
  String? _username;
  String? _password;

  void setUsername(String value) => _username = value;
  void setPassword(String value) => _password = value;

  /// Đăng ký: thêm tài khoản mới nếu username chưa tồn tại
  Future<bool> register() async {
    if (_username == null ||
        _username!.trim().isEmpty ||
        _password == null ||
        _password!.trim().isEmpty) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users');

    List<Map<String, String>> users = [];
    if (usersJson != null) {
      final decoded = jsonDecode(usersJson) as List;
      users = decoded.map((e) => Map<String, String>.from(e)).toList();
    }

    final exists = users.any((u) => u['username'] == _username!.trim());
    if (exists) return false;

    users.add({'username': _username!.trim(), 'password': _password!.trim()});

    await prefs.setString('users', jsonEncode(users));
    return true;
  }

  /// Đăng nhập: kiểm tra trong list users
  Future<bool> login() async {
    if (_username == null ||
        _username!.trim().isEmpty ||
        _password == null ||
        _password!.trim().isEmpty) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users');
    if (usersJson == null) return false;

    final decoded = jsonDecode(usersJson) as List;
    final users = decoded.map((e) => Map<String, String>.from(e)).toList();

    final found = users.any(
      (u) =>
          u['username'] == _username!.trim() &&
          u['password'] == _password!.trim(),
    );

    if (found) {
      // lưu username hiện tại để dùng cho welcome / auto-login
      await prefs.setString('current_user', _username!.trim());
    }

    return found;
  }

  /// Lấy user đang đăng nhập (nếu có)
  Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user');
  }

  /// Xóa current_user (logout)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
  }

  /// Lấy tất cả user (để debug / hiển thị)
  Future<List<Map<String, String>>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString('users');
    if (usersJson == null) return [];
    final decoded = jsonDecode(usersJson) as List;
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  }
}
