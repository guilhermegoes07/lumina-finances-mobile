import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/financial_goal.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../models/transaction.dart';

class FinancialGoalsScreen extends StatefulWidget {
  const FinancialGoalsScreen({Key? key}) : super(key: key);

  @override
  State<FinancialGoalsScreen> createState() => _FinancialGoalsScreenState();
}

class _FinancialGoalsScreenState extends State<FinancialGoalsScreen> {
  bool _isLoading = true;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Carregar dados via Provider
      final goalModel = Provider.of<FinancialGoalModel>(context, listen: false);
      await goalModel.loadGoals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar objetivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showGoalForm({FinancialGoal? goal}) {
    final isEditing = goal != null;
    
    // Resetar o formulário
    _nameController.text = isEditing ? goal.name : '';
    _targetAmountController.text = isEditing ? goal.targetAmount.toString() : '';
    _descriptionController.text = isEditing ? goal.description : '';
    _selectedDeadline = isEditing ? goal.deadline : null;
    
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: bottomInset + 8,
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
                Text(
                  isEditing ? 'Editar Objetivo' : 'Novo Objetivo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do objetivo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.star_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe um nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _targetAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Valor a atingir (R\$)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
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
                const SizedBox(height: 12),
                
                // Data limite (opcional)
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                    );
                    
                    if (pickedDate != null) {
                      setModalState(() {
                        _selectedDeadline = pickedDate;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data limite (opcional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _selectedDeadline != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDeadline!)
                          : 'Selecione uma data',
                      style: TextStyle(
                        color: _selectedDeadline != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final name = _nameController.text;
                            final targetAmount = double.parse(
                              _targetAmountController.text.replaceAll(',', '.'),
                            );
                            final description = _descriptionController.text;
                            
                            final goalModel = Provider.of<FinancialGoalModel>(context, listen: false);
                            if (isEditing) {
                              final updatedGoal = goal.copyWith(
                                name: name,
                                targetAmount: targetAmount,
                                deadline: _selectedDeadline,
                                description: description,
                              );
                              
                              goalModel.updateGoal(updatedGoal);
                            } else {
                              final newGoal = FinancialGoal(
                                name: name,
                                targetAmount: targetAmount,
                                deadline: _selectedDeadline,
                                description: description,
                              );
                              
                              goalModel.addGoal(newGoal);
                            }
                            
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(isEditing ? 'Salvar' : 'Adicionar'),
                      ),
                    ),
                    if (isEditing) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteConfirmation(goal);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showDeleteConfirmation(FinancialGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Objetivo'),
        content: Text('Tem certeza que deseja excluir o objetivo "${goal.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final goalModel = Provider.of<FinancialGoalModel>(context, listen: false);
              goalModel.deleteGoal(goal.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
  
  void _showAddContributionDialog(FinancialGoal goal) {
    final contributionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Contribuição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Objetivo: ${goal.name}'),
            const SizedBox(height: 8),
            Text(
              'Progresso: ${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Falta: R\$ ${goal.remainingAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contributionController,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final value = contributionController.text;
              final amount = double.tryParse(value.replaceAll(',', '.'));
              
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                
                final goalModel = Provider.of<FinancialGoalModel>(context, listen: false);
                goalModel.addContribution(goal.id, amount);
                
                // Adicionar uma transação de despesa para refletir a contribuição na meta
                final transactionModel = Provider.of<TransactionModel>(context, listen: false);
                final transaction = Transaction(
                  title: 'Contribuição: ${goal.name}',
                  amount: amount,
                  date: DateTime.now(),
                  category: 'Metas Financeiras',
                  type: 'expense',
                  description: 'Contribuição para meta: ${goal.name}',
                );
                
                transactionModel.addTransaction(transaction);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Contribuição de R\$ ${amount.toStringAsFixed(2)} adicionada! Saldo atualizado.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final goalModel = Provider.of<FinancialGoalModel>(context);
    final goals = goalModel.goals;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Objetivos Financeiros'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : goals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhum objetivo cadastrado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crie objetivos para organizar suas economias',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showGoalForm(),
                        icon: const Icon(Icons.add),
                        label: const Text('Criar Objetivo'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Status
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.flag,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Status',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showGoalForm(),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Novo'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatusItem(
                                  'Total: ${goals.length}',
                                  Icons.flag_outlined,
                                  Colors.blue,
                                ),
                                _buildStatusItem(
                                  'Ativos: ${goals.where((g) => !g.isCompleted).length}',
                                  Icons.play_arrow,
                                  Colors.orange,
                                ),
                                _buildStatusItem(
                                  'Concluídos: ${goals.where((g) => g.isCompleted).length}',
                                  Icons.check_circle_outline,
                                  Colors.green,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Metas ativas
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Metas Ativas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Lista de metas ativas
                    ...goals
                        .where((goal) => !goal.isCompleted)
                        .map((goal) => _buildGoalCard(goal))
                        .toList(),
                    
                    const SizedBox(height: 24),
                    
                    // Metas concluídas
                    if (goals.any((goal) => goal.isCompleted)) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Metas Concluídas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Lista de metas concluídas
                      ...goals
                          .where((goal) => goal.isCompleted)
                          .map((goal) => _buildGoalCard(goal))
                          .toList(),
                    ],
                  ],
                ),
      floatingActionButton: !_isLoading
          && goals.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showGoalForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildGoalCard(FinancialGoal goal) {
    final progressPercentage = goal.progressPercentage;
    final progressText = '${(progressPercentage * 100).toStringAsFixed(0)}%';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showGoalForm(goal: goal),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconData(goal.iconName),
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (goal.description.isNotEmpty)
                          Text(
                            goal.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        progressText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(progressPercentage),
                        ),
                      ),
                      if (goal.deadline != null)
                        Text(
                          goal.daysLeftText,
                          style: TextStyle(
                            fontSize: 12,
                            color: goal.daysLeft < 30
                                ? Colors.red
                                : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progressPercentage),
                ),
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atual: R\$ ${goal.currentAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Meta: R\$ ${goal.targetAmount.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddContributionDialog(goal),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Contribuir'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return Colors.green;
    if (percentage >= 0.7) return const Color(0xFF0CB288); // Teal
    if (percentage >= 0.4) return Colors.blue;
    if (percentage >= 0.2) return Colors.orange;
    return Colors.red;
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'savings': return Icons.savings;
      case 'home': return Icons.home;
      case 'directions_car': return Icons.directions_car;
      case 'school': return Icons.school;
      case 'beach_access': return Icons.beach_access;
      case 'trip': return Icons.flight_takeoff;
      case 'health': return Icons.health_and_safety;
      default: return Icons.savings;
    }
  }
  
  Widget _buildStatusItem(String text, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
} 