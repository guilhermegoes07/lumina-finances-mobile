import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../models/user_profile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = true;
  bool _hasAccount = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAccount();
  }

  Future<void> _checkExistingAccount() async {
    final loggedIn = await AuthService.isLoggedIn();
    setState(() {
      _hasAccount = loggedIn;
      _isLoading = false;
    });
    if (loggedIn) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    final user = await AuthService.getCurrentUser();
    if (user != null && user['email'] != null) {
      final userProfile = Provider.of<UserProfile>(context, listen: false);
      userProfile.updateProfile(
        name: user['name'] ?? '',
        email: user['email'] ?? '',
        profileType: user['profileType'] ?? 'Pessoal',
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo e nome do app
                Icon(
                  Icons.account_balance,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Lumina Finances',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hora de organizar suas finanças de forma clara!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 64),
                
                // Botões
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Criar Conta',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen(isLogin: true)),
                      );
                    },
                    child: const Text(
                      'Já tem uma conta? Fazer login',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 