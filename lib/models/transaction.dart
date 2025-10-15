import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'package:sqflite/sqflite.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class Transaction {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String type; // 'income' ou 'expense'
  final bool isRecurring;
  final String recurrenceFrequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final String description;
  final bool isPending; // Indica se é uma transação futura/pendente

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.isRecurring = false,
    this.recurrenceFrequency = 'monthly',
    this.description = '',
    this.isPending = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'category': category,
      'type': type,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceFrequency': recurrenceFrequency,
      'description': description,
      'isPending': isPending ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateFormat('yyyy-MM-dd').parse(map['date']),
      category: map['category'],
      type: map['type'],
      isRecurring: map['isRecurring'] == 1,
      recurrenceFrequency: map['recurrenceFrequency'],
      description: map['description'],
      isPending: map['isPending'] == 1,
    );
  }
}

class TransactionModel extends ChangeNotifier {
  List<Transaction> _transactions = [];

  List<Transaction> get transactions {
    final sortedTransactions = List<Transaction>.from(_transactions);
    sortedTransactions.sort((a, b) => b.date.compareTo(a.date)); // Mais recentes primeiro
    return sortedTransactions;
  }

  List<Transaction> get confirmedTransactions {
    return _transactions.where((t) => !t.isPending).toList();
  }

  List<Transaction> get pendingTransactions {
    return _transactions.where((t) => t.isPending).toList();
  }

  List<Transaction> get incomes {
    final incomeTransactions = confirmedTransactions.where((t) => t.type == 'income').toList();
    incomeTransactions.sort((a, b) => b.date.compareTo(a.date)); // Mais recentes primeiro
    return incomeTransactions;
  }
  
  List<Transaction> get expenses {
    final expenseTransactions = confirmedTransactions.where((t) => t.type == 'expense').toList();
    expenseTransactions.sort((a, b) => b.date.compareTo(a.date)); // Mais recentes primeiro
    return expenseTransactions;
  }

  double get balance => incomes.fold(0.0, (sum, item) => sum + item.amount) - 
                       expenses.fold(0.0, (sum, item) => sum + item.amount);

  double get totalIncome => incomes.fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpenses => expenses.fold(0.0, (sum, item) => sum + item.amount);

  TransactionModel() {
    loadTransactions();
  }

  static void reset(BuildContext context) {
    final model = Provider.of<TransactionModel>(context, listen: false);
    model._transactions = [];
    model.notifyListeners();
  }

  Future<String?> _getUserKey() async {
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return null;
    return 'transactions_${user['email']}';
  }

  Future<void> migrateTransactionsAddIds() async {
    final key = await _getUserKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    bool changed = false;
    int nextId = 1;
    // Descobrir o maior id já usado
    final List<Transaction> loaded = jsonList.map((json) {
      final map = jsonDecode(json);
      // Adicionar isPending se não existir
      if (!map.containsKey('isPending')) {
        map['isPending'] = 0;
      }
      return Transaction.fromMap(map);
    }).toList();
    final ids = loaded.where((t) => t.id != null).map((t) => t.id!).toList();
    if (ids.isNotEmpty) {
      nextId = ids.reduce((a, b) => a > b ? a : b) + 1;
    }
    final List<String> newJsonList = [];
    for (var t in loaded) {
      if (t.id == null) {
        final tWithId = Transaction(
          id: nextId,
          title: t.title,
          amount: t.amount,
          date: t.date,
          category: t.category,
          type: t.type,
          isRecurring: t.isRecurring,
          recurrenceFrequency: t.recurrenceFrequency,
          description: t.description,
          isPending: t.isPending,
        );
        newJsonList.add(jsonEncode(tWithId.toMap()));
        nextId++;
        changed = true;
      } else {
        newJsonList.add(jsonEncode(t.toMap()));
      }
    }
    if (changed) {
      await prefs.setStringList(key, newJsonList);
    }
  }

  Future<void> loadTransactions() async {
    final key = await _getUserKey();
    if (key == null) {
      _transactions = [];
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    _transactions = jsonList.map((json) {
      final map = jsonDecode(json);
      // Adicionar isPending se não existir (para retrocompatibilidade)
      if (!map.containsKey('isPending')) {
        map['isPending'] = 0;
      }
      return Transaction.fromMap(map);
    }).toList();
    // MIGRAÇÃO: garantir que todas as transações tenham id
    await migrateTransactionsAddIds();
    // Recarregar se houve migração
    final jsonList2 = prefs.getStringList(key) ?? [];
    if (jsonList2.length != jsonList.length || jsonList2.toString() != jsonList.toString()) {
      _transactions = jsonList2.map((json) {
        final map = jsonDecode(json);
        if (!map.containsKey('isPending')) {
          map['isPending'] = 0;
        }
        return Transaction.fromMap(map);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final key = await _getUserKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];

    // Gerar id incremental
    int newId = 1;
    if (_transactions.isNotEmpty) {
      final ids = _transactions.where((t) => t.id != null).map((t) => t.id!).toList();
      if (ids.isNotEmpty) {
        newId = ids.reduce((a, b) => a > b ? a : b) + 1;
      }
    }
    final transactionWithId = transaction.id == null
        ? Transaction(
            id: newId,
            title: transaction.title,
            amount: transaction.amount,
            date: transaction.date,
            category: transaction.category,
            type: transaction.type,
            isRecurring: transaction.isRecurring,
            recurrenceFrequency: transaction.recurrenceFrequency,
            description: transaction.description,
            isPending: transaction.isPending,
          )
        : transaction;

    jsonList.add(jsonEncode(transactionWithId.toMap()));
    await prefs.setStringList(key, jsonList);
    await loadTransactions();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final key = await _getUserKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      jsonList[index] = jsonEncode(transaction.toMap());
      await prefs.setStringList(key, jsonList);
      await loadTransactions();
    }
  }

  Future<void> deleteTransaction(int id) async {
    final key = await _getUserKey();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index != -1) {
      jsonList.removeAt(index);
      await prefs.setStringList(key, jsonList);
      await loadTransactions();
    }
  }

  List<Transaction> getTransactionsByPeriod({
    required DateTime startDate,
    required DateTime endDate,
    String? category,
  }) {
    final filteredTransactions = _transactions.where((t) {
      final isInDateRange = t.date.isAfter(startDate) && 
                           t.date.isBefore(endDate.add(const Duration(days: 1)));
      final matchesCategory = category == null || t.category == category;
      return isInDateRange && matchesCategory;
    }).toList();
    
    filteredTransactions.sort((a, b) => b.date.compareTo(a.date)); // Mais recentes primeiro
    return filteredTransactions;
  }

  List<Transaction> getTransactionsByMonth(int year, int month) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Último dia do mês
    
    return getTransactionsByPeriod(
      startDate: startDate,
      endDate: endDate,
    );
  }

  double getExpensesByCategory(String category) {
    return expenses
        .where((t) => t.category == category)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> getExpensesByCategoryMap() {
    final Map<String, double> result = {};
    
    for (var transaction in expenses) {
      if (result.containsKey(transaction.category)) {
        result[transaction.category] = result[transaction.category]! + transaction.amount;
      } else {
        result[transaction.category] = transaction.amount;
      }
    }
    
    return result;
  }

  // Métodos para previsão de saldo
  double getPredictedBalanceForMonth(int year, int month) {
    final currentBalance = balance;
    final now = DateTime.now();
    final targetDate = DateTime(year, month + 1, 0); // Último dia do mês
    
    // Se for um mês passado, retorna o saldo atual
    if (targetDate.isBefore(now)) {
      return currentBalance;
    }
    
    // Calcula transações pendentes até o fim do mês
    final pendingInMonth = pendingTransactions.where((t) {
      return t.date.year == year && t.date.month == month;
    }).toList();
    
    double predictedChange = 0.0;
    for (var t in pendingInMonth) {
      if (t.type == 'income') {
        predictedChange += t.amount;
      } else {
        predictedChange -= t.amount;
      }
    }
    
    return currentBalance + predictedChange;
  }

  Map<String, dynamic> getMonthForecast(int year, int month) {
    final confirmedIncome = confirmedTransactions
        .where((t) => t.type == 'income' && t.date.year == year && t.date.month == month)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final confirmedExpense = confirmedTransactions
        .where((t) => t.type == 'expense' && t.date.year == year && t.date.month == month)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final pendingIncome = pendingTransactions
        .where((t) => t.type == 'income' && t.date.year == year && t.date.month == month)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final pendingExpense = pendingTransactions
        .where((t) => t.type == 'expense' && t.date.year == year && t.date.month == month)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    return {
      'confirmedIncome': confirmedIncome,
      'confirmedExpense': confirmedExpense,
      'pendingIncome': pendingIncome,
      'pendingExpense': pendingExpense,
      'predictedBalance': getPredictedBalanceForMonth(year, month),
    };
  }
} 