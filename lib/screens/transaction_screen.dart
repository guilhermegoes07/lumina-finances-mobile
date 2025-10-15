import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class TransactionScreen extends StatefulWidget {
  final Transaction? transaction;
  
  const TransactionScreen({super.key, this.transaction});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = '';
  String _transactionType = 'expense'; // 'income' ou 'expense'
  bool _isRecurring = false;
  String _recurrenceFrequency = 'monthly';
  bool _isPending = false; // Nova flag para transações pendentes
  bool _isLoading = false;
  
  List<String> _expenseCategories = [];
  List<String> _incomeCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description;
      _selectedDate = widget.transaction!.date;
      _selectedCategory = widget.transaction!.category;
      _transactionType = widget.transaction!.type;
      _isRecurring = widget.transaction!.isRecurring;
      _recurrenceFrequency = widget.transaction!.recurrenceFrequency;
      _isPending = widget.transaction!.isPending;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final expenseCategoriesMap = await DatabaseService.getCategories('expense');
      final incomeCategoriesMap = await DatabaseService.getCategories('income');

      setState(() {
        _expenseCategories = expenseCategoriesMap.map((c) => c['name'] as String).toList();
        _incomeCategories = incomeCategoriesMap.map((c) => c['name'] as String).toList();
        
        if (_selectedCategory.isEmpty) {
          _selectedCategory = _transactionType == 'expense' 
              ? (_expenseCategories.isNotEmpty ? _expenseCategories.first : '')
              : (_incomeCategories.isNotEmpty ? _incomeCategories.first : '');
        }
      });
    } catch (e) {
      // Tratar erro
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedCategory.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final transactionModel = Provider.of<TransactionModel>(context, listen: false);
      
      double amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.'));
      
      final transaction = Transaction(
        id: widget.transaction?.id,
        title: _titleController.text,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        type: _transactionType,
        isRecurring: _isRecurring,
        recurrenceFrequency: _recurrenceFrequency,
        description: _descriptionController.text,
        isPending: _isPending,
      );
      
      if (widget.transaction != null) {
        await transactionModel.updateTransaction(transaction);
      } else {
        await transactionModel.addTransaction(transaction);
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    final categories = _transactionType == 'expense' ? _expenseCategories : _incomeCategories;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: isDarkMode ? Colors.white : Colors.black87,
    );
    final borderColor = isDarkMode ? Colors.grey[700] : Colors.grey[400];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Editar Transação' : 'Adicionar Transação'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Abas para tipo de transação
              Row(
                children: [
                  Expanded(
                    child: _buildTypeTab('Entrada', 'income'),
                  ),
                  Expanded(
                    child: _buildTypeTab('Saída', 'expense'),
                  ),
                  Expanded(
                    child: _buildTypeTab('Objetivo', 'goal'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Valor
              Text(
                'Valor',
                style: textStyle,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '0,00',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe um valor';
                  }
                  // Validar formato numérico
                  final cleanValue = value.replaceAll(',', '.');
                  final numValue = double.tryParse(cleanValue);
                  if (numValue == null) {
                    return 'Valor inválido. Use apenas números';
                  }
                  if (numValue <= 0) {
                    return 'O valor deve ser maior que zero';
                  }
                  if (numValue > 999999999) {
                    return 'Valor muito alto';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Categoria
              Text(
                'Categoria',
                style: textStyle,
              ),
              const SizedBox(height: 8),
              Theme(
                // Sobrescrever o tema para itens de dropdown selecionados
                data: Theme.of(context).copyWith(
                  canvasColor: Theme.of(context).scaffoldBackgroundColor,
                  // Melhorar visibilidade do item selecionado
                  textSelectionTheme: TextSelectionTheme.of(context).copyWith(
                    selectionColor: isDarkMode ? Colors.blue[800] : Colors.blue[100],
                  ),
                ),
                child: DropdownButtonFormField<String>(
                value: categories.contains(_selectedCategory) ? _selectedCategory : (categories.isNotEmpty ? categories.first : null),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
                  ),
                  dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma categoria';
                  }
                  return null;
                },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Data
              Text(
                'Data',
                style: textStyle,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: isDarkMode
                            ? ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.blue,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF303030),
                                  onSurface: Colors.white,
                                ),
                              )
                            : ThemeData.light(),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd MMM, yyyy', 'pt_BR').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Descrição
              Text(
                'Descrição',
                style: textStyle,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Adicione uma descrição',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  filled: true,
                  fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
                ),
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              
              // Transação recorrente
              Row(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      checkboxTheme: CheckboxThemeData(
                        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Theme.of(context).primaryColor;
                          }
                          return isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
                        }),
                        checkColor: MaterialStateProperty.all(Colors.white),
                      ),
                    ),
                    child: Checkbox(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value!;
                      });
                    },
                  ),
                  ),
                  Text(
                    'Transação recorrente',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () {
                      // Mostrar informações sobre transações recorrentes
                    },
                  ),
                ],
              ),

              // Transação pendente
              Row(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      checkboxTheme: CheckboxThemeData(
                        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.selected)) {
                            return Colors.amber;
                          }
                          return isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
                        }),
                        checkColor: MaterialStateProperty.all(Colors.white),
                      ),
                    ),
                    child: Checkbox(
                      value: _isPending,
                      onChanged: (value) {
                        setState(() {
                          _isPending = value!;
                        });
                      },
                    ),
                  ),
                  Text(
                    'Transação pendente (futura)',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Transação Pendente'),
                          content: const Text(
                            'Marque esta opção para transações futuras que ainda não foram efetivadas. '
                            'Elas serão consideradas na previsão de saldo.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              if (_isRecurring) ...[
                const SizedBox(height: 8),
                Theme(
                  // Sobrescrever o tema para dropdown de frequência
                  data: Theme.of(context).copyWith(
                    canvasColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: DropdownButtonFormField<String>(
                  value: _recurrenceFrequency,
                  decoration: InputDecoration(
                    labelText: 'Frequência',
                      labelStyle: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                  ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
                    ),
                    dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'daily',
                        child: Text(
                          'Diária',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text(
                          'Semanal',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text(
                          'Mensal',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'yearly',
                        child: Text(
                          'Anual',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _recurrenceFrequency = value!;
                    });
                  },
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Botão de salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode ? Colors.white : Colors.white,
                          ),
                        )
                      : const Text(
                          'Adicionar Transação',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, String type) {
    final isSelected = _transactionType == type;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Cores adaptativas para o modo claro/escuro
    final selectedColor = Theme.of(context).primaryColor;
    final unselectedColor = isDarkMode ? Colors.white : Colors.black87;
    final disabledColor = isDarkMode ? Colors.grey[600] : Colors.grey[400];
    
    // Definir plano de fundo para melhorar contraste
    final selectedBackground = isDarkMode ? selectedColor.withOpacity(0.2) : Colors.transparent;
    
    return GestureDetector(
      onTap: () {
        if (type != 'goal') { // 'goal' está desabilitado por enquanto
          setState(() {
            _transactionType = type;
            
            // Atualizar categoria se necessário
            if (type == 'expense' && _expenseCategories.isNotEmpty) {
              _selectedCategory = _expenseCategories.first;
            } else if (type == 'income' && _incomeCategories.isNotEmpty) {
              _selectedCategory = _incomeCategories.first;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedBackground : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? selectedColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
              color: type == 'goal' 
                  ? disabledColor 
                  : (isSelected ? selectedColor : unselectedColor),
            ),
          ),
        ),
      ),
    );
  }
} 