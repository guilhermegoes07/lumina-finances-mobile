import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/models/app_settings.dart';
import '../../lib/services/database_service.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  final String initialTab;
  
  const AdvancedSettingsScreen({super.key, this.initialTab = 'general'});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _backupAutoEnabled = false;
  bool _aiSuggestionsEnabled = false;
  String _language = 'Português (BR)';
  String _dateFormat = 'DD/MM/AAAA';
  String _currency = 'BRL (R$)';
  
  // Categorias
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];
  
  // Limites
  final Map<String, double> _spendingLimits = {
    'Alimentação': 1200.0,
    'Transporte': 800.0,
    'Moradia': 2000.0,
    'Compras': 1000.0,
  };
  
  final TextEditingController _totalLimitController = TextEditingController(text: '5000,00');
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _getInitialIndex(),
    );
    _loadSettings();
    _loadCategories();
  }
  
  int _getInitialIndex() {
    if (widget.initialTab == 'backup') return 0;
    if (widget.initialTab == 'categories') return 1;
    if (widget.initialTab == 'limits') return 2;
    return 0;
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _totalLimitController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _backupAutoEnabled = prefs.getBool('backupAutoEnabled') ?? false;
      _aiSuggestionsEnabled = prefs.getBool('aiSuggestionsEnabled') ?? false;
      _language = prefs.getString('language') ?? 'Português (BR)';
      _dateFormat = prefs.getString('dateFormat') ?? 'DD/MM/AAAA';
      _currency = prefs.getString('currency') ?? 'BRL (R$)';
    });
  }
  
  Future<void> _loadCategories() async {
    try {
      final expenseCategoriesMap = await DatabaseService.getCategories('expense');
      final incomeCategoriesMap = await DatabaseService.getCategories('income');

      setState(() {
        _expenseCategories = expenseCategoriesMap;
        _incomeCategories = incomeCategoriesMap;
      });
    } catch (e) {
      // Tratar erro
    }
  }
  
  Future<void> _saveSettings(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações Avançadas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Backup e Sincronização'),
            Tab(text: 'Gerenciar Categorias'),
            Tab(text: 'Moeda e Região'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Backup e Sincronização
          _buildBackupTab(),
          
          // Gerenciar Categorias
          _buildCategoriesTab(),
          
          // Moeda e Região
          _buildRegionTab(),
        ],
      ),
    );
  }
  
  Widget _buildBackupTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Backup e Sincronização',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Backup Automático'),
                  subtitle: const Text('Fazer backup automático dos seus dados'),
                  value: _backupAutoEnabled,
                  onChanged: (value) {
                    setState(() {
                      _backupAutoEnabled = value;
                    });
                    _saveSettings('backupAutoEnabled', value);
                  },
                ),
                
                const Divider(),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Último backup: 04/05/2025 12:30'),
                ),
                
                const SizedBox(height: 8),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // Realizar backup manual
                        },
                        child: const Text('Fazer backup agora'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Restaurar backup
                        },
                        child: const Text('Restaurar backup'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Recursos de IA',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Sugestões Inteligentes'),
                  subtitle: const Text('Receber sugestões baseadas nos seus gastos'),
                  value: _aiSuggestionsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _aiSuggestionsEnabled = value;
                    });
                    _saveSettings('aiSuggestionsEnabled', value);
                  },
                ),
                
                const Divider(),
                
                ListTile(
                  title: const Text('Gerenciar dados de IA'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navegar para gerenciamento de dados de IA
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoriesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categorias de Despesas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_expenseCategories.length} itens',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        ..._expenseCategories.map((category) => _buildCategoryItem(category, 'expense')),
        
        TextButton.icon(
          onPressed: () {
            // Adicionar nova categoria de despesa
          },
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Categoria'),
        ),
        
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categorias de Receitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_incomeCategories.length} itens',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        ..._incomeCategories.map((category) => _buildCategoryItem(category, 'income')),
        
        TextButton.icon(
          onPressed: () {
            // Adicionar nova categoria de receita
          },
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Categoria'),
        ),
        
        const SizedBox(height: 16),
        
        ElevatedButton(
          onPressed: () {
            // Personalizar categorias
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          child: const Text('Personalizar Categorias'),
        ),
      ],
    );
  }
  
  Widget _buildRegionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Moeda e Região',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text('Moeda Principal'),
                  trailing: Text(_currency),
                  onTap: () {
                    // Selecionar moeda
                  },
                ),
                
                const Divider(),
                
                ListTile(
                  title: const Text('Formato de Data'),
                  trailing: Text(_dateFormat),
                  onTap: () {
                    // Selecionar formato de data
                  },
                ),
                
                const Divider(),
                
                ListTile(
                  title: const Text('Idioma'),
                  trailing: Text(_language),
                  onTap: () {
                    // Selecionar idioma
                  },
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'Limites de Gastos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Limite Total Mensal',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'R\$ 5.000,00',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gasto: R\$ 3.750,00',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const Text(
                        '75%',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                const Divider(),
                
                // Limites por categoria
                ..._spendingLimits.entries.map((entry) => _buildLimitItem(entry.key, entry.value)),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      // Adicionar novo limite
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text('+ Adicionar Novo Limite'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryItem(Map<String, dynamic> category, String type) {
    final iconName = category['icon'] as String? ?? 'label';
    final colorValue = category['color'] as int? ?? 0xFF9E9E9E;
    final name = category['name'] as String? ?? '';
    
    // Mapear o nome do ícone para o ícone real
    IconData iconData = Icons.label;
    if (iconName == 'restaurant') iconData = Icons.restaurant;
    if (iconName == 'directions_car') iconData = Icons.directions_car;
    if (iconName == 'home') iconData = Icons.home;
    if (iconName == 'movie') iconData = Icons.movie;
    if (iconName == 'favorite') iconData = Icons.favorite;
    if (iconName == 'school') iconData = Icons.school;
    if (iconName == 'shopping_cart') iconData = Icons.shopping_cart;
    if (iconName == 'account_balance_wallet') iconData = Icons.account_balance_wallet;
    if (iconName == 'trending_up') iconData = Icons.trending_up;
    if (iconName == 'work') iconData = Icons.work;
    if (iconName == 'attach_money') iconData = Icons.attach_money;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Color(colorValue).withOpacity(0.2),
        child: Icon(iconData, color: Color(colorValue)),
      ),
      title: Text(name),
      trailing: const Icon(Icons.edit),
      onTap: () {
        // Editar categoria
      },
    );
  }
  
  Widget _buildLimitItem(String category, double amount) {
    final spent = amount * 0.8; // Exemplo: 80% do limite gasto
    final percentage = (spent / amount) * 100;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: spent / amount,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 90 ? Colors.red : Colors.blue,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'R\$ ${spent.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        
        const Divider(),
      ],
    );
  }
} 