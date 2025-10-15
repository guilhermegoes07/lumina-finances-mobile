import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class SavingsBox {
  final int? id;
  final String name;
  final double initialAmount;
  final DateTime entryDate;
  final DateTime? exitDate;
  final double cdiRate; // Taxa CDI em porcentagem anual
  final String description;

  SavingsBox({
    this.id,
    required this.name,
    required this.initialAmount,
    required this.entryDate,
    this.exitDate,
    this.cdiRate = 100.0, // 100% do CDI como padrão
    this.description = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initialAmount': initialAmount,
      'entryDate': entryDate.toIso8601String(),
      'exitDate': exitDate?.toIso8601String(),
      'cdiRate': cdiRate,
      'description': description,
    };
  }

  factory SavingsBox.fromMap(Map<String, dynamic> map) {
    return SavingsBox(
      id: map['id'],
      name: map['name'],
      initialAmount: map['initialAmount'],
      entryDate: DateTime.parse(map['entryDate']),
      exitDate: map['exitDate'] != null ? DateTime.parse(map['exitDate']) : null,
      cdiRate: map['cdiRate'] ?? 100.0,
      description: map['description'] ?? '',
    );
  }

  // Calcula o valor atual com base no CDI e tempo decorrido
  double getCurrentValue() {
    final now = DateTime.now();
    final endDate = exitDate ?? now;
    
    // Se a data de entrada for futura, retorna o valor inicial
    if (entryDate.isAfter(now)) {
      return initialAmount;
    }

    // Se a data de saída já passou, calcula até a data de saída
    final calculationDate = exitDate != null && exitDate!.isBefore(now) ? exitDate! : now;
    
    // Calcula a quantidade de dias
    final days = calculationDate.difference(entryDate).inDays;
    
    // CDI médio de referência: 13.65% ao ano (pode ser configurável)
    final cdiYearlyRate = 0.1365;
    final effectiveRate = (cdiRate / 100.0) * cdiYearlyRate;
    
    // Fórmula: M = C * (1 + i)^t
    // Onde i é a taxa diária e t é o número de dias
    final dailyRate = effectiveRate / 365;
    final currentValue = initialAmount * pow(1 + dailyRate, days);
    
    return currentValue;
  }

  double pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  // Calcula o rendimento bruto
  double getGrossProfit() {
    return getCurrentValue() - initialAmount;
  }

  // Calcula o imposto de renda com base no tempo de investimento
  double getIncomeTax() {
    final now = DateTime.now();
    final days = (exitDate ?? now).difference(entryDate).inDays;
    
    double taxRate;
    if (days <= 180) {
      taxRate = 0.225; // 22.5% para até 6 meses
    } else if (days <= 360) {
      taxRate = 0.20; // 20% de 6 a 12 meses
    } else if (days <= 720) {
      taxRate = 0.175; // 17.5% de 1 a 2 anos
    } else {
      taxRate = 0.15; // 15% acima de 2 anos
    }
    
    return getGrossProfit() * taxRate;
  }

  // Calcula o IOF (aplicado apenas nos primeiros 30 dias)
  double getIOF() {
    final now = DateTime.now();
    final days = (exitDate ?? now).difference(entryDate).inDays;
    
    if (days >= 30) {
      return 0.0; // Sem IOF após 30 dias
    }
    
    // Tabela regressiva de IOF
    final iofRate = (30 - days) * 0.0033; // 0.33% por dia até 30 dias
    return getGrossProfit() * iofRate;
  }

  // Calcula o rendimento líquido (após impostos)
  double getNetProfit() {
    return getGrossProfit() - getIncomeTax() - getIOF();
  }

  // Calcula o valor final líquido
  double getFinalValue() {
    return initialAmount + getNetProfit();
  }
}

class SavingsBoxModel extends ChangeNotifier {
  List<SavingsBox> _savingsBoxes = [];

  List<SavingsBox> get savingsBoxes => _savingsBoxes;

  SavingsBoxModel() {
    loadSavingsBoxes();
  }

  Future<String?> _getUserKey() async {
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return null;
    return 'savings_boxes_${user['email']}';
  }

  Future<void> loadSavingsBoxes() async {
    final key = await _getUserKey();
    if (key == null) {
      _savingsBoxes = [];
      notifyListeners();
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    _savingsBoxes = jsonList.map((json) => SavingsBox.fromMap(jsonDecode(json))).toList();
    notifyListeners();
  }

  Future<void> addSavingsBox(SavingsBox savingsBox) async {
    final key = await _getUserKey();
    if (key == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    
    // Gerar ID incremental
    int newId = 1;
    if (_savingsBoxes.isNotEmpty) {
      final ids = _savingsBoxes.where((s) => s.id != null).map((s) => s.id!).toList();
      if (ids.isNotEmpty) {
        newId = ids.reduce((a, b) => a > b ? a : b) + 1;
      }
    }
    
    final savingsBoxWithId = savingsBox.id == null
        ? SavingsBox(
            id: newId,
            name: savingsBox.name,
            initialAmount: savingsBox.initialAmount,
            entryDate: savingsBox.entryDate,
            exitDate: savingsBox.exitDate,
            cdiRate: savingsBox.cdiRate,
            description: savingsBox.description,
          )
        : savingsBox;
    
    jsonList.add(jsonEncode(savingsBoxWithId.toMap()));
    await prefs.setStringList(key, jsonList);
    await loadSavingsBoxes();
  }

  Future<void> updateSavingsBox(SavingsBox savingsBox) async {
    final key = await _getUserKey();
    if (key == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    final index = _savingsBoxes.indexWhere((s) => s.id == savingsBox.id);
    if (index != -1) {
      jsonList[index] = jsonEncode(savingsBox.toMap());
      await prefs.setStringList(key, jsonList);
      await loadSavingsBoxes();
    }
  }

  Future<void> deleteSavingsBox(int id) async {
    final key = await _getUserKey();
    if (key == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(key) ?? [];
    final index = _savingsBoxes.indexWhere((s) => s.id == id);
    if (index != -1) {
      jsonList.removeAt(index);
      await prefs.setStringList(key, jsonList);
      await loadSavingsBoxes();
    }
  }

  double get totalInvested {
    return _savingsBoxes.fold(0.0, (sum, box) => sum + box.initialAmount);
  }

  double get totalCurrentValue {
    return _savingsBoxes.fold(0.0, (sum, box) => sum + box.getCurrentValue());
  }

  double get totalProfit {
    return _savingsBoxes.fold(0.0, (sum, box) => sum + box.getNetProfit());
  }
}
