import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bank_account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class BankAccountsScreen extends StatefulWidget {
  const BankAccountsScreen({Key? key}) : super(key: key);

  @override
  State<BankAccountsScreen> createState() => _BankAccountsScreenState();
}

class _BankAccountsScreenState extends State<BankAccountsScreen> {
  List<BankAccount> _accounts = [];
  bool _isLoading = true;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankNameController = TextEditingController();
  String _selectedAccountType = 'Conta Corrente';
  final _balanceController = TextEditingController();
  
  final List<String> _accountTypes = [
    'Conta Corrente',
    'Conta Poupança',
    'Conta Salário',
    'Investimentos',
    'Dinheiro',
    'Outros',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bankNameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }
  
  Future<String?> _getUserKey() async {
    final user = await AuthService.getCurrentUser();
    if (user == null || user['email'] == null) return null;
    return 'bankAccounts_${user['email']}';
  }
  
  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final key = await _getUserKey();
      if (key == null) {
        setState(() {
          _accounts = [];
          _isLoading = false;
        });
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getStringList(key) ?? [];
      
      if (accountsJson.isEmpty) {
        // Adicionar algumas contas de exemplo na primeira execução
        _accounts = [
          BankAccount(
            name: 'Minha Conta',
            bankName: 'Banco Brasil',
            accountType: 'Conta Corrente',
            balance: 2500.0,
          ),
          BankAccount(
            name: 'Poupança',
            bankName: 'Caixa',
            accountType: 'Conta Poupança',
            balance: 8000.0,
            iconName: 'savings',
          ),
          BankAccount(
            name: 'Investimentos',
            bankName: 'Corretora',
            accountType: 'Investimentos',
            balance: 15000.0,
            iconName: 'trending_up',
          ),
        ];
        
        await _saveAccounts();
      } else {
        _accounts = accountsJson.map((json) => 
          BankAccount.fromJson(jsonDecode(json))
        ).toList();
      }
    } catch (e) {
      // Tratar erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar contas: $e'),
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
  
  Future<void> _saveAccounts() async {
    try {
      final key = await _getUserKey();
      if (key == null) return;
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = _accounts.map((account) => 
        jsonEncode(account.toJson())
      ).toList();
      
      await prefs.setStringList(key, accountsJson);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar contas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  double get _totalBalance {
    return _accounts.fold(0, (sum, account) => sum + account.balance);
  }
  
  void _showAccountForm({BankAccount? account}) {
    final isEditing = account != null;
    
    // Resetar o formulário
    _nameController.text = isEditing ? account.name : '';
    _bankNameController.text = isEditing ? account.bankName : '';
    _selectedAccountType = isEditing ? account.accountType : 'Conta Corrente';
    _balanceController.text = isEditing ? account.balance.toString() : '0.00';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
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
                  isEditing ? 'Editar Conta' : 'Nova Conta',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da conta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
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
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do banco/instituição',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o nome do banco';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Tipo de conta (dropdown)
                DropdownButtonFormField<String>(
                  value: _selectedAccountType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de conta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _accountTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() {
                        _selectedAccountType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _balanceController,
                  decoration: const InputDecoration(
                    labelText: 'Saldo inicial (R\$)',
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
                    
                    if (amount < 0) {
                      return 'O valor não pode ser negativo';
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final name = _nameController.text;
                            final bankName = _bankNameController.text;
                            final accountType = _selectedAccountType;
                            final balance = double.parse(
                              _balanceController.text.replaceAll(',', '.'),
                            );
                            
                            if (isEditing) {
                              final updatedAccount = account.copyWith(
                                name: name,
                                bankName: bankName,
                                accountType: accountType,
                                balance: balance,
                              );
                              
                              setState(() {
                                final index = _accounts.indexWhere((a) => a.id == account.id);
                                if (index != -1) {
                                  _accounts[index] = updatedAccount;
                                }
                              });
                            } else {
                              final newAccount = BankAccount(
                                name: name,
                                bankName: bankName,
                                accountType: accountType,
                                balance: balance,
                                iconName: _getIconNameForType(accountType),
                              );
                              
                              setState(() {
                                _accounts.add(newAccount);
                              });
                            }
                            
                            _saveAccounts();
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
                          _showDeleteConfirmation(account);
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
  
  void _showDeleteConfirmation(BankAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: Text('Tem certeza que deseja excluir a conta "${account.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _accounts.removeWhere((a) => a.id == account.id);
              });
              _saveAccounts();
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
  
  void _showTransactionDialog(BankAccount account, bool isDeposit) {
    final amountController = TextEditingController();
    final String title = isDeposit ? 'Depositar' : 'Sacar';
    final String action = isDeposit ? 'Depositar' : 'Sacar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conta: ${account.name}'),
            const SizedBox(height: 8),
            Text(
              'Saldo atual: R\$ ${account.balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: isDeposit ? 'Valor a depositar (R\$)' : 'Valor a sacar (R\$)',
                border: const OutlineInputBorder(),
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
              final value = amountController.text;
              final amount = double.tryParse(value.replaceAll(',', '.'));
              
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                
                setState(() {
                  final index = _accounts.indexWhere((a) => a.id == account.id);
                  if (index != -1) {
                    final currentAccount = _accounts[index];
                    
                    if (isDeposit) {
                      currentAccount.deposit(amount);
                    } else {
                      // Verificar se há saldo suficiente
                      if (amount > currentAccount.balance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saldo insuficiente para esta operação'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      currentAccount.withdraw(amount);
                    }
                    
                    _saveAccounts();
                  }
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${isDeposit ? "Depósito" : "Saque"} de R\$ ${amount.toStringAsFixed(2)} realizado!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }
  
  void _showTransferDialog(BankAccount sourceAccount) {
    final amountController = TextEditingController();
    BankAccount? destinationAccount;
    
    // Filtrar contas para excluir a conta de origem
    final otherAccounts = _accounts.where((a) => a.id != sourceAccount.id).toList();
    
    if (otherAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa ter pelo menos duas contas para fazer uma transferência'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Definir a conta de destino inicial
    destinationAccount = otherAccounts.first;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Transferir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('De: ${sourceAccount.name} (R\$ ${sourceAccount.balance.toStringAsFixed(2)})'),
              const SizedBox(height: 16),
              
              // Dropdown para selecionar a conta de destino
              DropdownButtonFormField<BankAccount>(
                value: destinationAccount,
                decoration: const InputDecoration(
                  labelText: 'Para',
                  border: OutlineInputBorder(),
                ),
                items: otherAccounts.map((account) {
                  return DropdownMenuItem<BankAccount>(
                    value: account,
                    child: Text('${account.name} (${account.bankName})'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      destinationAccount = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor a transferir (R\$)',
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
                final value = amountController.text;
                final amount = double.tryParse(value.replaceAll(',', '.'));
                
                if (amount != null && amount > 0 && destinationAccount != null) {
                  // Verificar se há saldo suficiente
                  if (amount > sourceAccount.balance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saldo insuficiente para esta transferência'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.pop(context);
                  
                  setState(() {
                    final sourceIndex = _accounts.indexWhere((a) => a.id == sourceAccount.id);
                    final destIndex = _accounts.indexWhere((a) => a.id == destinationAccount!.id);
                    
                    if (sourceIndex != -1 && destIndex != -1) {
                      _accounts[sourceIndex].transfer(_accounts[destIndex], amount);
                      _saveAccounts();
                    }
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Transferência de R\$ ${amount.toStringAsFixed(2)} realizada!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Transferir'),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getIconNameForType(String accountType) {
    switch (accountType) {
      case 'Conta Corrente': return 'account_balance';
      case 'Conta Poupança': return 'savings';
      case 'Conta Salário': return 'work';
      case 'Investimentos': return 'trending_up';
      case 'Dinheiro': return 'payments';
      default: return 'account_balance_wallet';
    }
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'account_balance': return Icons.account_balance;
      case 'savings': return Icons.savings;
      case 'work': return Icons.work;
      case 'trending_up': return Icons.trending_up;
      case 'payments': return Icons.payments;
      default: return Icons.account_balance_wallet;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas Bancárias'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                // Card com saldo total
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    color: Theme.of(context).primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Saldo Total',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(_totalBalance),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_accounts.length} ${_accounts.length == 1 ? 'conta' : 'contas'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Lista de contas
                Expanded(
                  child: _accounts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhuma conta cadastrada',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Adicione suas contas para gerenciar',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _showAccountForm(),
                                icon: const Icon(Icons.add),
                                label: const Text('Adicionar Conta'),
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _accounts.length,
                          itemBuilder: (context, index) => _buildAccountCard(_accounts[index]),
                        ),
                ),
              ],
            ),
      floatingActionButton: _accounts.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAccountForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildAccountCard(BankAccount account) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showAccountForm(account: account),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getIconData(account.iconName),
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${account.bankName} - ${account.accountType}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormat.format(account.balance),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: account.balance >= 0
                          ? Theme.of(context).primaryColor
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.arrow_upward,
                    label: 'Depositar',
                    onPressed: () => _showTransactionDialog(account, true),
                  ),
                  _buildActionButton(
                    icon: Icons.arrow_downward,
                    label: 'Sacar',
                    onPressed: () => _showTransactionDialog(account, false),
                  ),
                  _buildActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Transferir',
                    onPressed: () => _showTransferDialog(account),
                  ),
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Editar',
                    onPressed: () => _showAccountForm(account: account),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
} 