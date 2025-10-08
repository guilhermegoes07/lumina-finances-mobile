import 'package:intl/intl.dart';

class UserInvestment {
  final int? id;
  final String investmentName;
  final double amount;
  final DateTime dateInvested;
  final double yieldRate;
  final String category;
  final String type;
  final String risk;
  final String institution;
  final String icon;
  final String color;

  UserInvestment({
    this.id,
    required this.investmentName,
    required this.amount,
    required this.dateInvested,
    required this.yieldRate,
    required this.category,
    required this.type,
    required this.risk,
    required this.institution,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'investmentName': investmentName,
      'amount': amount,
      'dateInvested': dateInvested.toIso8601String(),
      'yieldRate': yieldRate,
      'category': category,
      'type': type,
      'risk': risk,
      'institution': institution,
      'icon': icon,
      'color': color,
    };
  }

  factory UserInvestment.fromMap(Map<String, dynamic> map) {
    return UserInvestment(
      id: map['id'],
      investmentName: map['investmentName'],
      amount: map['amount'],
      dateInvested: DateTime.parse(map['dateInvested']),
      yieldRate: map['yieldRate'],
      category: map['category'],
      type: map['type'],
      risk: map['risk'],
      institution: map['institution'],
      icon: map['icon'],
      color: map['color'],
    );
  }

  double calculateCurrentValue() {
    final daysSinceInvestment = DateTime.now().difference(dateInvested).inDays;
    final yearlyRate = yieldRate / 100;
    final dailyRate = yearlyRate / 365;
    final currentValue = amount * (1 + (dailyRate * daysSinceInvestment));
    return currentValue;
  }

  double calculateProfit() {
    return calculateCurrentValue() - amount;
  }

  double calculateProfitPercentage() {
    return (calculateProfit() / amount) * 100;
  }

  String get formattedAmount => NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(amount);
  String get formattedCurrentValue => NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(calculateCurrentValue());
  String get formattedProfit => NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(calculateProfit());
}
