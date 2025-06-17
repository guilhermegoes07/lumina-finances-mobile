import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _isDarkMode;

  AppSettings({bool isDarkMode = false}) : _isDarkMode = isDarkMode;

  bool get isDarkMode => _isDarkMode;

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    
    // Salvar a preferência
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    
    notifyListeners();
  }
} 