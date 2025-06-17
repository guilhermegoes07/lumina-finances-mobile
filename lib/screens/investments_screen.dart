import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../models/transaction.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  final _moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  String _selectedCategory = 'conservador';
  final _amountController = TextEditingController();
  bool _isLoading = false;

  final Map<String, Map<String, dynamic>> _categories = {
    'conservador': {
      'title': 'Investimentos Conservadores',
      'subtitle': '8% - 10% ao ano',
      'description': 'Baixo risco, alta liquidez',
      'color': Colors.green,
      'icon': Icons.shield,
    },
    'moderado': {
      'title': 'Investimentos Moderados',
      'subtitle': '10% - 12% ao ano',
      'description': 'Risco médio, boa diversificação',
      'color': Colors.orange,
      'icon': Icons.balance,
    },
    'arrojado': {
      'title': 'Investimentos Arrojados',
      'subtitle': '12% - 14% ao ano',
      'description': 'Alto risco, alto retorno',
      'color': Colors.red,
      'icon': Icons.trending_up,
    },
  };

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _investInProduct(Investment investment) async {
    final transactionModel = Provider.of<TransactionModel>(context, listen: false);
    final investmentModel = Provider.of<InvestmentModel>(context, listen: false);
    
    // Verificar se o usuário tem saldo suficiente
    if (transactionModel.balance < double.parse(_amountController.text.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saldo insuficiente para este investimento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.'));
      
      // Criar transação de investimento (despesa)
      final investmentTransaction = Transaction(
        title: 'Investimento: ${investment.name}',
        amount: amount,
        date: DateTime.now(),
        category: 'Investimento',
        type: 'expense',
        description: 'Investimento em ${investment.name} - ${investment.yieldRange} ao ano',
      );

      // Adicionar a transação
      await transactionModel.addTransaction(investmentTransaction);
      
      // Adicionar ao portfólio de investimentos do usuário
      await investmentModel.addUserInvestment(investment, amount);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Investimento de ${_moneyFormat.format(amount)} realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao realizar investimento: ${e.toString()}'),
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

  void _showInvestmentDialog(Investment investment) {
    final transactionModel = Provider.of<TransactionModel>(context, listen: false);
    _amountController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              investment.iconData,
              color: investment.colorValue,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                investment.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              investment.description,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Rentabilidade', investment.yieldRange, Colors.green),
            _buildInfoRow('Valor mínimo', _moneyFormat.format(investment.minAmount), Colors.blue),
            _buildInfoRow('Valor máximo', _moneyFormat.format(investment.maxAmount), Colors.blue),
            _buildInfoRow('Risco', _getRiskText(investment.risk), _getRiskColor(investment.risk)),
            _buildInfoRow('Liquidez', _getLiquidityText(investment.liquidity), Colors.orange),
            _buildInfoRow('Instituição', investment.institution, Colors.purple),
            const SizedBox(height: 16),
            Text(
              'Valor a investir:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0,00',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Saldo disponível: ${_moneyFormat.format(transactionModel.balance)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _investInProduct(investment),
            style: ElevatedButton.styleFrom(
              backgroundColor: investment.colorValue,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Investir'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _getRiskText(String risk) {
    switch (risk) {
      case 'baixo':
        return 'Baixo';
      case 'medio':
        return 'Médio';
      case 'alto':
        return 'Alto';
      default:
        return risk;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'baixo':
        return Colors.green;
      case 'medio':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getLiquidityText(String liquidity) {
    switch (liquidity) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Média';
      case 'baixa':
        return 'Baixa';
      default:
        return liquidity;
    }
  }

  Widget _buildInvestmentCard(Investment investment) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDarkMode ? 4 : 2,
      child: InkWell(
        onTap: () => _showInvestmentDialog(investment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: investment.colorValue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      investment.iconData,
                      color: investment.colorValue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          investment.institution,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: investment.colorValue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      investment.yieldRange,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: investment.colorValue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                investment.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip('Risco: ${_getRiskText(investment.risk)}', _getRiskColor(investment.risk)),
                  const SizedBox(width: 8),
                  _buildChip('Liquidez: ${_getLiquidityText(investment.liquidity)}', Colors.blue),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Min: ${_moneyFormat.format(investment.minAmount)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showInvestmentDialog(investment),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Investir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: investment.colorValue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final investmentModel = Provider.of<InvestmentModel>(context);
    final transactionModel = Provider.of<TransactionModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final investments = investmentModel.getInvestmentsByCategory(_selectedCategory);
    final categoryInfo = _categories[_selectedCategory]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugestões de Investimentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              // TODO: Implementar tela de portfólio
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Portfólio em desenvolvimento')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com saldo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.blue[50],
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Saldo Disponível',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _moneyFormat.format(transactionModel.balance),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Seletor de categoria
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: _categories.keys.map((category) {
                final isSelected = _selectedCategory == category;
                final info = _categories[category]!;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? info['color'].withOpacity(0.1)
                            : (isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected 
                            ? Border.all(color: info['color'], width: 2)
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            info['icon'],
                            color: isSelected ? info['color'] : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            info['subtitle'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? info['color'] : Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Informações da categoria
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryInfo['title'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  categoryInfo['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Lista de investimentos
          Expanded(
            child: investments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum investimento encontrado',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: investments.length,
                    itemBuilder: (context, index) {
                      return _buildInvestmentCard(investments[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 