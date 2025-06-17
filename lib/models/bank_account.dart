import 'dart:math';

class BankAccount {
  final String id;
  String name;
  String bankName;
  String accountType;
  double balance;
  String iconName;
  
  BankAccount({
    String? id,
    required this.name,
    required this.bankName,
    required this.accountType,
    this.balance = 0.0,
    this.iconName = 'account_balance',
  }) : id = id ?? _generateId();
  
  // Método simples para gerar IDs únicos
  static String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // Adicionar saldo à conta
  void deposit(double amount) {
    if (amount <= 0) return;
    balance += amount;
  }
  
  // Retirar saldo da conta
  bool withdraw(double amount) {
    if (amount <= 0) return false;
    if (amount > balance) return false;
    
    balance -= amount;
    return true;
  }
  
  // Transferir saldo para outra conta
  bool transfer(BankAccount destination, double amount) {
    if (amount <= 0 || amount > balance) return false;
    
    balance -= amount;
    destination.balance += amount;
    return true;
  }
  
  // Converter a conta para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bankName': bankName,
      'accountType': accountType,
      'balance': balance,
      'iconName': iconName,
    };
  }
  
  // Criar uma conta a partir de JSON
  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      bankName: json['bankName'] as String,
      accountType: json['accountType'] as String,
      balance: (json['balance'] as num).toDouble(),
      iconName: json['iconName'] as String? ?? 'account_balance',
    );
  }
  
  // Criar uma cópia da conta com alterações opcionais
  BankAccount copyWith({
    String? name,
    String? bankName,
    String? accountType,
    double? balance,
    String? iconName,
  }) {
    return BankAccount(
      id: id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      balance: balance ?? this.balance,
      iconName: iconName ?? this.iconName,
    );
  }
} 