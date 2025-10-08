import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'user_investment.dart';

class Investment {
  final int? id;
  final String name;
  final String description;
  final double minYield;
  final double maxYield;
  final double minAmount;
  final double maxAmount;
  final String category; // 'conservador', 'moderado', 'arrojado'
  final String type; // 'renda_fixa', 'renda_variavel', 'fundos', 'acoes'
  final String risk; // 'baixo', 'medio', 'alto'
  final String liquidity; // 'alta', 'media', 'baixa'
  final String institution; // 'banco', 'corretora', 'fintech'
  final String icon; // nome do ícone
  final String color; // cor em formato hex
  final bool isActive;

  Investment({
    this.id,
    required this.name,
    required this.description,
    required this.minYield,
    required this.maxYield,
    required this.minAmount,
    required this.maxAmount,
    required this.category,
    required this.type,
    required this.risk,
    required this.liquidity,
    required this.institution,
    required this.icon,
    required this.color,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minYield': minYield,
      'maxYield': maxYield,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'category': category,
      'type': type,
      'risk': risk,
      'liquidity': liquidity,
      'institution': institution,
      'icon': icon,
      'color': color,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Investment.fromMap(Map<String, dynamic> map) {
    return Investment(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      minYield: map['minYield'],
      maxYield: map['maxYield'],
      minAmount: map['minAmount'],
      maxAmount: map['maxAmount'],
      category: map['category'],
      type: map['type'],
      risk: map['risk'],
      liquidity: map['liquidity'],
      institution: map['institution'],
      icon: map['icon'],
      color: map['color'],
      isActive: map['isActive'] == 1,
    );
  }

  String get yieldRange => '${minYield.toStringAsFixed(1)}% - ${maxYield.toStringAsFixed(1)}%';
  String get amountRange => 'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(minAmount)} - R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '').format(maxAmount)}';
  
  Color get colorValue {
    try {
      return Color(int.parse(color.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  IconData get iconData {
    switch (icon) {
      case 'trending_up':
        return Icons.trending_up;
      case 'account_balance':
        return Icons.account_balance;
      case 'pie_chart':
        return Icons.pie_chart;
      case 'show_chart':
        return Icons.show_chart;
      case 'savings':
        return Icons.savings;
      case 'monetization_on':
        return Icons.monetization_on;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'currency_exchange':
        return Icons.currency_exchange;
      case 'home':
        return Icons.home;
      default:
        return Icons.trending_up;
    }
  }
}

class InvestmentModel extends ChangeNotifier {
  List<Investment> _investments = [];
  List<UserInvestment> _userInvestments = [];

  List<Investment> get investments => _investments;
  List<UserInvestment> get userInvestments => _userInvestments;

  InvestmentModel() {
    _loadDefaultInvestments();
    loadUserInvestments();
  }

  void _loadDefaultInvestments() {
    _investments = [
      // Investimentos Conservadores (8-10%)
      Investment(
        name: 'CDB Banco Inter',
        description: 'Certificado de Depósito Bancário com liquidez diária',
        minYield: 8.5,
        maxYield: 9.2,
        minAmount: 100.0,
        maxAmount: 1000000.0,
        category: 'conservador',
        type: 'renda_fixa',
        risk: 'baixo',
        liquidity: 'alta',
        institution: 'Banco Inter',
        icon: 'account_balance',
        color: '#2196F3',
      ),
      Investment(
        name: 'LCI/LCA Itaú',
        description: 'Letras de Crédito Imobiliário/Agropecuário',
        minYield: 8.8,
        maxYield: 9.5,
        minAmount: 1000.0,
        maxAmount: 500000.0,
        category: 'conservador',
        type: 'renda_fixa',
        risk: 'baixo',
        liquidity: 'media',
        institution: 'Itaú',
        icon: 'savings',
        color: '#4CAF50',
      ),
      Investment(
        name: 'Tesouro Selic',
        description: 'Título público com rentabilidade atrelada à Selic',
        minYield: 8.0,
        maxYield: 9.0,
        minAmount: 30.0,
        maxAmount: 1000000.0,
        category: 'conservador',
        type: 'renda_fixa',
        risk: 'baixo',
        liquidity: 'alta',
        institution: 'Tesouro Nacional',
        icon: 'account_balance_wallet',
        color: '#FF9800',
      ),

      // Investimentos Moderados (10-12%)
      Investment(
        name: 'Fundos Multimercado',
        description: 'Fundos que investem em diferentes classes de ativos',
        minYield: 10.5,
        maxYield: 11.8,
        minAmount: 500.0,
        maxAmount: 1000000.0,
        category: 'moderado',
        type: 'fundos',
        risk: 'medio',
        liquidity: 'media',
        institution: 'XP Investimentos',
        icon: 'pie_chart',
        color: '#9C27B0',
      ),
      Investment(
        name: 'Debêntures',
        description: 'Títulos de dívida de empresas privadas',
        minYield: 10.0,
        maxYield: 12.0,
        minAmount: 1000.0,
        maxAmount: 500000.0,
        category: 'moderado',
        type: 'renda_fixa',
        risk: 'medio',
        liquidity: 'baixa',
        institution: 'BTG Pactual',
        icon: 'monetization_on',
        color: '#607D8B',
      ),
      Investment(
        name: 'Fundos Imobiliários',
        description: 'Investimento em empreendimentos imobiliários',
        minYield: 10.2,
        maxYield: 11.5,
        minAmount: 100.0,
        maxAmount: 1000000.0,
        category: 'moderado',
        type: 'renda_variavel',
        risk: 'medio',
        liquidity: 'alta',
        institution: 'Rico Investimentos',
        icon: 'home',
        color: '#795548',
      ),

      // Investimentos Arrojados (12-14%)
      Investment(
        name: 'Ações Blue Chips',
        description: 'Ações de empresas grandes e consolidadas',
        minYield: 12.0,
        maxYield: 14.0,
        minAmount: 100.0,
        maxAmount: 1000000.0,
        category: 'arrojado',
        type: 'renda_variavel',
        risk: 'alto',
        liquidity: 'alta',
        institution: 'Clear Corretora',
        icon: 'show_chart',
        color: '#E91E63',
      ),
      Investment(
        name: 'Fundos de Ações',
        description: 'Fundos especializados em ações brasileiras',
        minYield: 12.5,
        maxYield: 13.8,
        minAmount: 500.0,
        maxAmount: 1000000.0,
        category: 'arrojado',
        type: 'fundos',
        risk: 'alto',
        liquidity: 'media',
        institution: 'Nubank Investimentos',
        icon: 'trending_up',
        color: '#8BC34A',
      ),
      Investment(
        name: 'Criptomoedas',
        description: 'Investimento em criptomoedas (Bitcoin, Ethereum)',
        minYield: 12.0,
        maxYield: 15.0,
        minAmount: 50.0,
        maxAmount: 1000000.0,
        category: 'arrojado',
        type: 'renda_variavel',
        risk: 'alto',
        liquidity: 'alta',
        institution: 'Binance',
        icon: 'currency_exchange',
        color: '#FF5722',
      ),
    ];
  }

  Future<String?> _getUserKey() async {
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return null;
    return 'investments_${user['email']}';
  }

  Future<void> loadUserInvestments() async {
    final key = await _getUserKey();
    if (key == null) {
      _userInvestments = [];
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    _userInvestments = jsonList.map((json) => UserInvestment.fromMap(jsonDecode(json))).toList();
    notifyListeners();
  }

  Future<void> addUserInvestment(Investment investment, double amount) async {
    final key = await _getUserKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];

    // Gerar id incremental
    int newId = 1;
    if (_userInvestments.isNotEmpty) {
      final ids = _userInvestments.where((t) => t.id != null).map((t) => t.id!).toList();
      if (ids.isNotEmpty) {
        newId = ids.reduce((a, b) => a > b ? a : b) + 1;
      }
    }

    final userInvestment = UserInvestment(
      id: newId,
      investmentName: investment.name,
      amount: amount,
      dateInvested: DateTime.now(),
      yieldRate: (investment.minYield + investment.maxYield) / 2,
      category: investment.category,
      type: investment.type,
      risk: investment.risk,
      institution: investment.institution,
      icon: investment.icon,
      color: investment.color,
    );

    jsonList.add(jsonEncode(userInvestment.toMap()));
    await prefs.setStringList(key, jsonList);
    await loadUserInvestments();
  }

  List<Investment> getInvestmentsByCategory(String category) {
    return _investments.where((inv) => inv.category == category).toList();
  }

  List<Investment> getInvestmentsByYieldRange(double minYield, double maxYield) {
    return _investments.where((inv) => 
      inv.minYield >= minYield && inv.maxYield <= maxYield
    ).toList();
  }

  double getTotalInvested() {
    return _userInvestments.fold(0.0, (sum, inv) => sum + inv.amount);
  }

  double getTotalCurrentValue() {
    return _userInvestments.fold(0.0, (sum, inv) => sum + inv.calculateCurrentValue());
  }

  double getTotalProfit() {
    return getTotalCurrentValue() - getTotalInvested();
  }

  double getTotalProfitPercentage() {
    final invested = getTotalInvested();
    if (invested == 0) return 0.0;
    return (getTotalProfit() / invested) * 100;
  }

  Map<String, double> getInvestmentsByCategory() {
    Map<String, double> categoryTotals = {};
    for (var inv in _userInvestments) {
      categoryTotals[inv.category] = (categoryTotals[inv.category] ?? 0) + inv.amount;
    }
    return categoryTotals;
  }

  Future<void> removeUserInvestment(int id) async {
    final key = await _getUserKey();
    if (key == null) return;
    
    _userInvestments.removeWhere((inv) => inv.id == id);
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _userInvestments.map((inv) => jsonEncode(inv.toMap())).toList();
    await prefs.setStringList(key, jsonList);
    notifyListeners();
  }
} 