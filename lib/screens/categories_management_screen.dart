import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen> {
  List<Map<String, dynamic>> _expenseCategories = [];
  List<Map<String, dynamic>> _incomeCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final expenseCategories = await DatabaseService.getCategories('expense');
      final incomeCategories = await DatabaseService.getCategories('income');

      setState(() {
        _expenseCategories = expenseCategories;
        _incomeCategories = incomeCategories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar categorias: $e')),
        );
      }
    }
  }

  Future<void> _addCategory(String type) async {
    final nameController = TextEditingController();
    String selectedIcon = 'label';
    Color selectedColor = Colors.blue;

    final icons = [
      'label', 'restaurant', 'directions_car', 'home', 'movie', 'favorite',
      'school', 'shopping_cart', 'account_balance_wallet', 'trending_up',
      'work', 'attach_money', 'sports_soccer', 'phone_iphone', 'wifi',
      'local_gas_station', 'local_hospital', 'fitness_center', 'pets', 'child_care',
    ];

    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
      Colors.pink, Colors.teal, Colors.amber, Colors.indigo, Colors.cyan,
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              title: Text('Nova Categoria de ${type == 'expense' ? 'Despesa' : 'Receita'}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Categoria',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ícone:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: icons.map((iconName) {
                        final isSelected = selectedIcon == iconName;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = iconName;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? (isDarkMode ? Colors.blue[700] : Colors.blue[100])
                                  : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _getIconData(iconName),
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Cor:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: colors.map((color) {
                        final isSelected = selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Digite um nome para a categoria')),
                      );
                      return;
                    }

                    try {
                      await DatabaseService.addCategory({
                        'name': nameController.text,
                        'type': type,
                        'icon': selectedIcon,
                        'color': selectedColor.value,
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadCategories();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Categoria adicionada com sucesso')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao adicionar categoria: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'directions_car': return Icons.directions_car;
      case 'home': return Icons.home;
      case 'movie': return Icons.movie;
      case 'favorite': return Icons.favorite;
      case 'school': return Icons.school;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'trending_up': return Icons.trending_up;
      case 'work': return Icons.work;
      case 'attach_money': return Icons.attach_money;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'phone_iphone': return Icons.phone_iphone;
      case 'wifi': return Icons.wifi;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'local_hospital': return Icons.local_hospital;
      case 'fitness_center': return Icons.fitness_center;
      case 'pets': return Icons.pets;
      case 'child_care': return Icons.child_care;
      default: return Icons.label;
    }
  }

  Future<void> _deleteCategory(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a categoria "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DatabaseService.deleteCategory(id);
        _loadCategories();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Categoria excluída com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir categoria: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Categorias'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Despesas'),
              Tab(text: 'Receitas'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildCategoryList(_expenseCategories, 'expense', isDarkMode),
                  _buildCategoryList(_incomeCategories, 'income', isDarkMode),
                ],
              ),
      ),
    );
  }

  Widget _buildCategoryList(List<Map<String, dynamic>> categories, String type, bool isDarkMode) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final color = Color(category['color'] as int);
              final icon = _getIconData(category['icon'] as String);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(category['name'] as String),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCategory(
                      category['id'] as int,
                      category['name'] as String,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _addCategory(type),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Categoria'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }
}
