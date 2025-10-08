import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/investment.dart';
import '../models/app_settings.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    final investmentModel = Provider.of<InvestmentModel>(context);
    final appSettings = Provider.of<AppSettings>(context);
    final isDarkMode = appSettings.isDarkMode;

    final userInvestments = investmentModel.userInvestments;
    final totalInvested = investmentModel.getTotalInvested();
    final totalCurrentValue = investmentModel.getTotalCurrentValue();
    final totalProfit = investmentModel.getTotalProfit();
    final profitPercentage = investmentModel.getTotalProfitPercentage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Portfólio'),
        elevation: 0,
      ),
      body: userInvestments.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Resumo do Portfólio
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDarkMode
                            ? [Colors.blue[900]!, Colors.blue[700]!]
                            : [Colors.blue[700]!, Colors.blue[500]!],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Valor Total do Portfólio',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _moneyFormat.format(totalCurrentValue),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(
                              'Investido',
                              _moneyFormat.format(totalInvested),
                              Icons.arrow_upward,
                            ),
                            _buildSummaryItem(
                              'Lucro',
                              _moneyFormat.format(totalProfit),
                              Icons.trending_up,
                              valueColor: totalProfit >= 0 ? Colors.greenAccent : Colors.redAccent,
                            ),
                            _buildSummaryItem(
                              'Retorno',
                              '${profitPercentage.toStringAsFixed(2)}%',
                              Icons.percent,
                              valueColor: profitPercentage >= 0 ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Distribuição por Categoria
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Distribuição por Categoria',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCategoryDistribution(investmentModel),
                      ],
                    ),
                  ),

                  // Lista de Investimentos
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seus Investimentos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userInvestments.length,
                          itemBuilder: (context, index) {
                            final investment = userInvestments[index];
                            return _buildInvestmentCard(investment, isDarkMode);
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Seu portfólio está vazio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comece a investir para construir seu patrimônio',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Investimento'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDistribution(InvestmentModel model) {
    final categoryTotals = model.getInvestmentsByCategory();
    final total = model.getTotalInvested();

    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    final categories = {
      'conservador': {'name': 'Conservador', 'color': Colors.green},
      'moderado': {'name': 'Moderado', 'color': Colors.orange},
      'arrojado': {'name': 'Arrojado', 'color': Colors.red},
    };

    return Column(
      children: categoryTotals.entries.map((entry) {
        final percentage = (entry.value / total) * 100;
        final categoryInfo = categories[entry.key] ?? {'name': entry.key, 'color': Colors.blue};
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: categoryInfo['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        categoryInfo['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(categoryInfo['color'] as Color),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInvestmentCard(investment, bool isDarkMode) {
    final currentValue = investment.calculateCurrentValue();
    final profit = investment.calculateProfit();
    final profitPercentage = investment.calculateProfitPercentage();
    final isPositive = profit >= 0;

    Color categoryColor;
    switch (investment.category) {
      case 'conservador':
        categoryColor = Colors.green;
        break;
      case 'moderado':
        categoryColor = Colors.orange;
        break;
      case 'arrojado':
        categoryColor = Colors.red;
        break;
      default:
        categoryColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showInvestmentDetails(investment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(investment.icon),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investment.investmentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          investment.institution,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red[400],
                    onPressed: () => _confirmRemoveInvestment(investment),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Investido',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _moneyFormat.format(investment.amount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Valor Atual',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _moneyFormat.format(currentValue),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Retorno',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            color: isPositive ? Colors.green : Colors.red,
                            size: 14,
                          ),
                          Text(
                            '${profitPercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
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

  void _showInvestmentDetails(investment) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(investment.investmentName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Instituição', investment.institution),
              _buildDetailRow('Categoria', _getCategoryName(investment.category)),
              _buildDetailRow('Tipo', _getTypeName(investment.type)),
              _buildDetailRow('Risco', _getRiskName(investment.risk)),
              _buildDetailRow('Data do Investimento', dateFormat.format(investment.dateInvested)),
              _buildDetailRow('Valor Investido', _moneyFormat.format(investment.amount)),
              _buildDetailRow('Taxa de Retorno', '${investment.yieldRate.toStringAsFixed(2)}% a.a.'),
              const Divider(height: 20),
              _buildDetailRow('Valor Atual', investment.formattedCurrentValue),
              _buildDetailRow('Lucro', investment.formattedProfit,
                  valueColor: investment.calculateProfit() >= 0 ? Colors.green : Colors.red),
              _buildDetailRow(
                'Retorno',
                '${investment.calculateProfitPercentage().toStringAsFixed(2)}%',
                valueColor: investment.calculateProfitPercentage() >= 0 ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'conservador':
        return 'Conservador';
      case 'moderado':
        return 'Moderado';
      case 'arrojado':
        return 'Arrojado';
      default:
        return category;
    }
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'renda_fixa':
        return 'Renda Fixa';
      case 'renda_variavel':
        return 'Renda Variável';
      case 'fundos':
        return 'Fundos';
      case 'acoes':
        return 'Ações';
      default:
        return type;
    }
  }

  String _getRiskName(String risk) {
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

  void _confirmRemoveInvestment(investment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Investimento'),
        content: Text(
          'Deseja remover o investimento "${investment.investmentName}" do seu portfólio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final investmentModel = Provider.of<InvestmentModel>(context, listen: false);
              investmentModel.removeUserInvestment(investment.id!);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Investimento removido com sucesso'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
