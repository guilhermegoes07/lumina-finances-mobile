import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool _isDarkMode;
  bool _showForecast;

  AppSettings({bool isDarkMode = false, bool showForecast = false}) 
      : _isDarkMode = isDarkMode,
        _showForecast = showForecast;

  bool get isDarkMode => _isDarkMode;
  bool get showForecast => _showForecast;

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    
    // Salvar a preferência
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    
    notifyListeners();
  }

  Future<void> toggleForecast() async {
    _showForecast = !_showForecast;
    
    // Salvar a preferência
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showForecast', _showForecast);
    
    notifyListeners();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showForecast = prefs.getBool('showForecast') ?? false;
    notifyListeners();
  }
} 