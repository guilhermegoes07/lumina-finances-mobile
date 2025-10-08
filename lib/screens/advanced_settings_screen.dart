import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'spending_limits_screen.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import '../models/transaction.dart';
import '../models/financial_goal.dart';
import 'package:printing/printing.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  final String? initialTab;

  const AdvancedSettingsScreen({
    Key? key, 
    this.initialTab,
  }) : super(key: key);

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _exportInProgress = false;
  bool _biometricEnabled = false;
  List<dynamic> _spendingLimits = [];
  bool _isLoggingOut = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSpendingLimits();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await AuthService.getCurrentUser();
    final email = user != null && user['email'] != null ? user['email'] : null;
    setState(() {
      _isDarkMode = email != null ? (prefs.getBool('pref_${email}_isDarkMode') ?? false) : false;
      _notificationsEnabled = email != null ? (prefs.getBool('pref_${email}_notificationsEnabled') ?? true) : true;
      _biometricEnabled = email != null ? (prefs.getBool('pref_${email}_biometricEnabled') ?? false) : false;
    });
  }
  
  Future<void> _loadSpendingLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final limitsJson = prefs.getStringList('spendingLimits') ?? [];
    setState(() {
      _spendingLimits = limitsJson.map((json) => SpendingLimit.fromJson(jsonDecode(json))).toList();
    });
  }
  
  Future<void> _toggleDarkMode(bool value) async {
    final appSettings = Provider.of<AppSettings>(context, listen: false);
    appSettings.toggleDarkMode();
    final user = await AuthService.getCurrentUser();
    final email = user != null && user['email'] != null ? user['email'] : null;
    setState(() {
      _isDarkMode = value;
    });
    if (email != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_${email}_isDarkMode', value);
    }
  }
  
  Future<void> _toggleNotifications(bool value) async {
    final user = await AuthService.getCurrentUser();
    final email = user != null && user['email'] != null ? user['email'] : null;
    if (email != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_${email}_notificationsEnabled', value);
    }
    setState(() {
      _notificationsEnabled = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value 
          ? 'Notificações ativadas com sucesso!'
          : 'Notificações desativadas'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _toggleBiometric(bool value) async {
    final user = await AuthService.getCurrentUser();
    final email = user != null && user['email'] != null ? user['email'] : null;
    if (email != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pref_${email}_biometricEnabled', value);
    }
    setState(() {
      _biometricEnabled = value;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value 
          ? 'Autenticação biométrica ativada!'
          : 'Autenticação biométrica desativada'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _exportData(String format) async {
    setState(() {
      _exportInProgress = true;
    });
    
    try {
      // Simulação de exportação
      await Future.delayed(const Duration(seconds: 2));
      
      if (format == 'csv') {
        // Implementação básica para exportar dados (simulação)
        final directory = await getApplicationDocumentsDirectory();
        final path = directory.path;
        final now = DateTime.now();
        final filename = 'lumina_finances_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
        final file = File('$path/$filename');
        
        // Dados simulados de exemplo
        List<List<dynamic>> rows = [];
        rows.add(['Data', 'Categoria', 'Descrição', 'Valor', 'Tipo']);
        rows.add(['2023-01-15', 'Alimentação', 'Supermercado', '150.00', 'Despesa']);
        rows.add(['2023-01-20', 'Salário', 'Pagamento Mensal', '3000.00', 'Receita']);
        
        String csv = const ListToCsvConverter().convert(rows);
        await file.writeAsString(csv);
        
        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Dados exportados para $path/$filename'),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else if (format == 'pdf') {
        // Implementação da exportação em PDF
        try {
          final transactionModel = Provider.of<TransactionModel>(context, listen: false);
          
          final file = await PdfService.generateTransactionsReport(
            transactions: transactionModel.transactions,
            balance: transactionModel.balance,
            totalIncome: transactionModel.totalIncome,
            totalExpenses: transactionModel.totalExpenses,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('PDF gerado: ${file.path.split('/').last}'),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Visualizar',
                  onPressed: () async {
                    await Printing.sharePdf(
                      bytes: await file.readAsBytes(),
                      filename: file.path.split('/').last,
                    );
                  },
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao gerar PDF: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar dados: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _exportInProgress = false;
        });
      }
    }
  }
  
  void _navigateToSpendingLimits() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpendingLimitsScreen(),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Cabeçalho com informações do usuário
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[300],
                    child: userProfile.avatarUrl.isEmpty
                        ? Text(
                            userProfile.name.isNotEmpty
                                ? userProfile.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontSize: 24, color: Colors.black87),
                          )
                        : null,
                    backgroundImage: userProfile.avatarUrl.isNotEmpty
                        ? NetworkImage(userProfile.avatarUrl)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.name.isEmpty ? 'João Silva' : userProfile.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userProfile.email.isEmpty ? 'joao.silva@gmail.com' : userProfile.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // Editar perfil (implementar)
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Seção Limites de Gastos
          const Text(
            'Limites de Gastos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _spendingLimits.isEmpty
                  ? const Text('Nenhum limite cadastrado.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._spendingLimits.map((limit) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(limit.category)),
                                    Text('R\$ ${limit.amount.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: limit.amount > 0 ? (limit.spent / limit.amount).clamp(0.0, 1.0) : 0.0,
                                  backgroundColor: Colors.grey[200],
                                ),
                                const SizedBox(height: 16),
                              ],
                            )),
                        ElevatedButton.icon(
                          onPressed: _navigateToSpendingLimits,
                          icon: const Icon(Icons.edit),
                          label: const Text('Gerenciar Limites'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Informações do Aplicativo
          const Text(
            'Informações do Aplicativo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  title: const Text('Versão do Aplicativo'),
                  trailing: const Text('1.0.0'),
                ),
                ListTile(
                  title: const Text('Termos de Uso'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Implementar termos de uso
                  },
                ),
                ListTile(
                  title: const Text('Política de Privacidade'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Implementar política de privacidade
                  },
                ),
                ListTile(
                  title: const Text('Código Aberto'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Implementar tela de licenças
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
} 