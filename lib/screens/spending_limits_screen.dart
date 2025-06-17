import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class SpendingLimit {
  final String category;
  final double amount;
  final double spent;

  SpendingLimit({
    required this.category,
    required this.amount,
    this.spent = 0.0,
  });

  double get progress => spent / amount;

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'spent': spent,
    };
  }

  factory SpendingLimit.fromJson(Map<String, dynamic> json) {
    return SpendingLimit(
      category: json['category'] as String,
      amount: json['amount'] as double,
      spent: json['spent'] as double,
    );
  }
}

class SpendingLimitsScreen extends StatefulWidget {
  const SpendingLimitsScreen({Key? key}) : super(key: key);

  @override
  State<SpendingLimitsScreen> createState() => _SpendingLimitsScreenState();
}

class _SpendingLimitsScreenState extends State<SpendingLimitsScreen> {
  List<SpendingLimit> _limits = [];
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = true;

  Future<String?> _getUserKey() async {
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return null;
    return 'spendingLimits_${user['email']}';
  }

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadLimits() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final key = await _getUserKey();
      if (key == null) {
        setState(() {
          _limits = [];
          _isLoading = false;
        });
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final limitsJson = prefs.getStringList(key) ?? [];
      _limits = limitsJson.map((json) => SpendingLimit.fromJson(jsonDecode(json))).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar limites: $e'),
          backgroundColor: Colors.red,
        ),
      );
      _limits = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveLimits() async {
    try {
      final key = await _getUserKey();
      if (key == null) return;
      final prefs = await SharedPreferences.getInstance();
      final limitsJson = _limits
          .map((limit) => jsonEncode(limit.toJson()))
          .toList();
      await prefs.setStringList(key, limitsJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar limites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addLimit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Adicionar Novo Limite',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe uma categoria';
                  }
                  
                  // Verificar se a categoria já existe
                  final categoryExists = _limits.any(
                    (limit) => limit.category.toLowerCase() == value.toLowerCase(),
                  );
                  
                  if (categoryExists) {
                    return 'Esta categoria já existe';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor Limite (R\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe um valor';
                  }
                  
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null) {
                    return 'Valor inválido';
                  }
                  
                  if (amount <= 0) {
                    return 'O valor deve ser maior que zero';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final category = _categoryController.text;
                    final amount = double.parse(
                      _amountController.text.replaceAll(',', '.'),
                    );
                    
                    final newLimit = SpendingLimit(
                      category: category,
                      amount: amount,
                    );
                    
                    setState(() {
                      _limits.add(newLimit);
                    });
                    
                    _saveLimits();
                    
                    // Limpar campos
                    _categoryController.clear();
                    _amountController.clear();
                    
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Adicionar'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _editLimit(int index) {
    final limit = _limits[index];
    _categoryController.text = limit.category;
    _amountController.text = limit.amount.toString();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Editar Limite',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe uma categoria';
                  }
                  
                  // Verificar se a categoria já existe (exceto a categoria atual)
                  final categoryExists = _limits.any(
                    (l) => l.category.toLowerCase() == value.toLowerCase() && 
                           l.category != limit.category,
                  );
                  
                  if (categoryExists) {
                    return 'Esta categoria já existe';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor Limite (R\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe um valor';
                  }
                  
                  final amount = double.tryParse(value.replaceAll(',', '.'));
                  if (amount == null) {
                    return 'Valor inválido';
                  }
                  
                  if (amount <= 0) {
                    return 'O valor deve ser maior que zero';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final category = _categoryController.text;
                          final amount = double.parse(
                            _amountController.text.replaceAll(',', '.'),
                          );
                          
                          setState(() {
                            _limits[index] = SpendingLimit(
                              category: category,
                              amount: amount,
                              spent: limit.spent,
                            );
                          });
                          
                          _saveLimits();
                          
                          // Limpar campos
                          _categoryController.clear();
                          _amountController.clear();
                          
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Salvar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Remover Limite'),
                          content: Text(
                            'Tem certeza que deseja remover o limite para ${limit.category}?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Fechar o diálogo
                                Navigator.pop(context); // Fechar o modal
                                
                                setState(() {
                                  _limits.removeAt(index);
                                });
                                
                                _saveLimits();
                                
                                // Limpar campos
                                _categoryController.clear();
                                _amountController.clear();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Remover'),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Remover'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Limites de Gastos'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Explicação
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Controle seus gastos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Configure limites para cada categoria de gasto e receba notificações quando estiver próximo de atingir o limite.',
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Lista de limites
                ..._limits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final limit = entry.value;
                  
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _editLimit(index),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    limit.category,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'R\$ ${limit.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: limit.progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                limit.progress > 0.9
                                    ? Colors.red
                                    : limit.progress > 0.7
                                        ? Colors.orange
                                        : Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Gasto: R\$ ${limit.spent.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  '${(limit.progress * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: limit.progress > 0.9
                                        ? Colors.red
                                        : limit.progress > 0.7
                                            ? Colors.orange
                                            : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 16),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLimit,
        child: const Icon(Icons.add),
      ),
    );
  }
} 