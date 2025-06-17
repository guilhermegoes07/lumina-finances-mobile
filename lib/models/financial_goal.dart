import 'package:flutter/foundation.dart';
import 'dart:math';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class FinancialGoal {
  final String id;
  String name;
  double targetAmount;
  double currentAmount;
  DateTime? deadline;
  String description;
  String iconName;
  
  FinancialGoal({
    String? id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    this.description = '',
    this.iconName = 'savings',
  }) : id = id ?? _generateId();
  
  // Método simples para gerar IDs únicos
  static String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  double get progressPercentage => 
      targetAmount > 0 ? (currentAmount / targetAmount) : 0.0;
  
  bool get isCompleted => currentAmount >= targetAmount;
  
  int get daysLeft {
    if (deadline == null) return -1;
    final today = DateTime.now();
    return deadline!.difference(today).inDays;
  }
  
  String get daysLeftText {
    if (deadline == null) return 'Sem prazo';
    if (daysLeft < 0) return 'Prazo expirado';
    if (daysLeft == 0) return 'Último dia';
    return '$daysLeft dias restantes';
  }
  
  // Calcular quanto ainda falta para atingir o objetivo
  double get remainingAmount => targetAmount - currentAmount;
  
  // Adicionar um valor ao objetivo
  void addContribution(double amount) {
    if (amount <= 0) return;
    currentAmount += amount;
    if (currentAmount > targetAmount) {
      currentAmount = targetAmount;
    }
  }
  
  // Calcular quanto falta por mês para atingir o objetivo até o prazo
  double getMonthlySavingTarget() {
    if (deadline == null || isCompleted) return 0.0;
    
    final today = DateTime.now();
    final difference = deadline!.difference(today);
    
    // Se o prazo já passou ou é hoje, retorna o valor restante
    if (difference.inDays <= 0) return remainingAmount;
    
    // Calcula quantos meses faltam (aproximadamente)
    final monthsLeft = difference.inDays / 30.0;
    
    // Retorna quanto precisa economizar por mês
    return remainingAmount / monthsLeft;
  }
  
  double get dailySavingNeeded {
    if (isCompleted || deadline == null) return 0;
    
    final days = daysLeft;
    if (days <= 0) return remainingAmount;
    
    return remainingAmount / days;
  }
  
  // Estimar data de conclusão baseado no ritmo atual de contribuições
  DateTime? estimatedCompletionDate(double monthlyContribution) {
    if (isCompleted) return DateTime.now();
    if (monthlyContribution <= 0) return null;
    
    // Calcula quantos meses faltam no ritmo atual
    final monthsLeft = remainingAmount / monthlyContribution;
    
    // Adiciona esses meses à data atual
    final today = DateTime.now();
    return DateTime(
      today.year,
      today.month + monthsLeft.ceil(),
      today.day,
    );
  }
  
  // Gerar dica de economia
  String getSavingTip() {
    if (isCompleted) {
      return 'Parabéns! Você atingiu seu objetivo "$name".';
    }
    
    if (deadline == null) {
      return 'Defina uma data limite para "$name" para receber dicas personalizadas.';
    }
    
    if (daysLeft <= 0) {
      return 'O prazo para "$name" foi atingido. Considere ajustar a data ou aumentar suas contribuições.';
    }
    
    if (dailySavingNeeded < 10) {
      return 'Economize apenas R\$ ${dailySavingNeeded.toStringAsFixed(2)} por dia para atingir seu objetivo "$name" no prazo.';
    } else {
      final weeklyAmount = dailySavingNeeded * 7;
      return 'Economize R\$ ${weeklyAmount.toStringAsFixed(2)} por semana para atingir seu objetivo "$name" no prazo.';
    }
  }
  
  // Converter o objetivo para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline?.millisecondsSinceEpoch,
      'description': description,
      'iconName': iconName,
    };
  }
  
  // Criar um objetivo a partir de JSON
  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: json['targetAmount'] as double,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      deadline: json['deadline'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['deadline'] as int) 
          : null,
      description: json['description'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'savings',
    );
  }
  
  // Criar uma cópia do objetivo com alterações opcionais
  FinancialGoal copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? description,
    String? iconName,
  }) {
    return FinancialGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
    );
  }
}

class FinancialGoalModel extends ChangeNotifier {
  List<FinancialGoal> _goals = [];

  List<FinancialGoal> get goals => _goals;
  
  List<FinancialGoal> get activeGoals => 
      _goals.where((goal) => !goal.isCompleted).toList();
  
  List<FinancialGoal> get completedGoals => 
      _goals.where((goal) => goal.isCompleted).toList();

  FinancialGoalModel() {
    loadGoals();
  }

  static void reset(BuildContext context) {
    final model = Provider.of<FinancialGoalModel>(context, listen: false);
    model._goals = [];
    model.notifyListeners();
  }

  Future<String?> _getUserKey() async {
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return null;
    return 'goals_${user['email']}';
  }

  Future<void> loadGoals() async {
    final key = await _getUserKey();
    if (key == null) {
      _goals = [];
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    _goals = jsonList.map((json) => FinancialGoal.fromJson(jsonDecode(json))).toList();
    notifyListeners();
  }

  Future<void> addGoal(FinancialGoal goal) async {
    final key = await _getUserKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    jsonList.add(jsonEncode(goal.toJson()));
    await prefs.setStringList(key, jsonList);
    await loadGoals();
  }

  Future<void> updateGoal(FinancialGoal goal) async {
    final key = await _getUserKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      jsonList[index] = jsonEncode(goal.toJson());
      await prefs.setStringList(key, jsonList);
      await loadGoals();
    }
  }

  Future<void> deleteGoal(String id) async {
    final key = await _getUserKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    final index = _goals.indexWhere((g) => g.id == id);
    if (index != -1) {
      jsonList.removeAt(index);
      await prefs.setStringList(key, jsonList);
      await loadGoals();
    }
  }

  Future<void> addContribution(String goalId, double amount) async {
    final index = _goals.indexWhere((g) => g.id == goalId);
    if (index != -1) {
      final updated = _goals[index].copyWith(
        currentAmount: _goals[index].currentAmount + amount,
      );
      await updateGoal(updated);
    }
  }
} 