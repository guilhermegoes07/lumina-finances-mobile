import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class AuthService {
  static const String usersKey = 'users';
  static const String loggedUserKey = 'loggedUserEmail';

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(usersKey);
    if (usersJson == null) return [];
    final List<dynamic> usersList = jsonDecode(usersJson);
    return usersList.cast<Map<String, dynamic>>();
  }

  static Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(usersKey, jsonEncode(users));
  }

  static Future<bool> register({
    required String name,
    required String email,
    required String password,
    String profileType = 'Pessoal',
  }) async {
    final users = await getAllUsers();
    if (users.any((u) => u['email'] == email)) {
      return false; // Já existe usuário com esse email
    }
    users.add({
      'name': name,
      'email': email,
      'passwordHash': _hashPassword(password),
      'profileType': profileType,
    });
    await _saveUsers(users);
    await _setLoggedUser(email);
    return true;
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    final users = await getAllUsers();
    final user = users.firstWhere(
      (u) => u['email'] == email && u['passwordHash'] == _hashPassword(password),
      orElse: () => {},
    );
    if (user.isEmpty) return false;
    await _setLoggedUser(email);
    return true;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(loggedUserKey);
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(loggedUserKey);
    if (email == null) return null;
    final users = await getAllUsers();
    return users.firstWhere((u) => u['email'] == email, orElse: () => {});
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(loggedUserKey) != null;
  }

  static Future<void> _setLoggedUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(loggedUserKey, email);
  }
} 