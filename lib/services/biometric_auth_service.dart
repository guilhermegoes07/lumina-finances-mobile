import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'auth_service.dart';

class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Verificar se o dispositivo suporta biometria
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Verificar se há biometria disponível
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Obter tipos de biometria disponíveis
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Autenticar com biometria
  static Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Por favor, autentique-se para acessar o Lumina Finances',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // Verificar se a biometria está habilitada para o usuário atual
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return false;
    
    final email = user['email'];
    return prefs.getBool('pref_${email}_biometricEnabled') ?? false;
  }

  // Habilitar biometria para o usuário atual
  static Future<void> enableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return;
    
    final email = user['email'];
    await prefs.setBool('pref_${email}_biometricEnabled', true);
  }

  // Desabilitar biometria para o usuário atual
  static Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return;
    
    final email = user['email'];
    await prefs.setBool('pref_${email}_biometricEnabled', false);
  }
}

class PinAuthService {
  // Verificar se o PIN está configurado
  static Future<bool> isPinConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return false;
    
    final email = user['email'];
    final pinHash = prefs.getString('pref_${email}_pinHash');
    return pinHash != null && pinHash.isNotEmpty;
  }

  // Configurar PIN
  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return;
    
    final email = user['email'];
    final pinHash = _hashPin(pin);
    await prefs.setString('pref_${email}_pinHash', pinHash);
    await prefs.setBool('pref_${email}_pinEnabled', true);
  }

  // Verificar PIN
  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return false;
    
    final email = user['email'];
    final storedHash = prefs.getString('pref_${email}_pinHash');
    if (storedHash == null) return false;
    
    final pinHash = _hashPin(pin);
    return pinHash == storedHash;
  }

  // Remover PIN
  static Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return;
    
    final email = user['email'];
    await prefs.remove('pref_${email}_pinHash');
    await prefs.setBool('pref_${email}_pinEnabled', false);
  }

  // Verificar se o PIN está habilitado
  static Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return false;
    
    final email = user['email'];
    return prefs.getBool('pref_${email}_pinEnabled') ?? false;
  }

  // Hash do PIN
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
