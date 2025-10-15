import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/app_settings.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final _moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  int _selectedMonthOffset = 0; // 0 = mês atual, 1 = próximo mês, etc.

  @override
  Widget build(BuildContext context) {
    final transactionModel = Provider.of<TransactionModel>(context);
    final appSettings = Provider.of<AppSettings>(context);
    final isDarkMode = appSettings.isDarkMode;
    
    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month + _selectedMonthOffset, 1);
    final forecast = transactionModel.getMonthForecast(targetDate.year, targetDate.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão Financeira'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Seletor de mês
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _selectedMonthOffset > 0
                            ? () {
                                setState(() {
                                  _selectedMonthOffset--;
                                });
                              }
                            : null,
                      ),
                      Text(
                        DateFormat('MMMM yyyy', 'pt_BR').format(targetDate),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _selectedMonthOffset < 12
                            ? () {
                                setState(() {
                                  _selectedMonthOffset++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Saldo previsto
          Card(
            color: isDarkMode ? Colors.amber[900] : Colors.amber[100],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: isDarkMode ? Colors.amber[200] : Colors.amber[900],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saldo Previsto para o Final do Mês',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.amber[200] : Colors.amber[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _moneyFormat.format(forecast['predictedBalance']),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.amber[200] : Colors.amber[900],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Detalhamento
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detalhamento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Divider(height: 24),
                  
                  // Entradas confirmadas
                  _buildDetailRow(
                    'Entradas Confirmadas',
                    forecast['confirmedIncome'],
                    Colors.green,
                    Icons.check_circle,
                  ),
                  const SizedBox(height: 12),
                  
                  // Saídas confirmadas
                  _buildDetailRow(
                    'Saídas Confirmadas',
                    forecast['confirmedExpense'],
                    Colors.red,
                    Icons.check_circle,
                  ),
                  const Divider(height: 24),
                  
                  // Entradas pendentes
                  _buildDetailRow(
                    'Entradas Pendentes',
                    forecast['pendingIncome'],
                    Colors.green,
                    Icons.schedule,
                  ),
                  const SizedBox(height: 12),
                  
                  // Saídas pendentes
                  _buildDetailRow(
                    'Saídas Pendentes',
                    forecast['pendingExpense'],
                    Colors.red,
                    Icons.schedule,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transações pendentes
          if (transactionModel.pendingTransactions.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transações Pendentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Divider(height: 24),
                    ...transactionModel.pendingTransactions
                        .where((t) =>
                            t.date.year == targetDate.year &&
                            t.date.month == targetDate.month)
                        .map((t) => _buildPendingTransactionItem(t, isDarkMode))
                        .toList(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          _moneyFormat.format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTransactionItem(Transaction transaction, bool isDarkMode) {
    final isIncome = transaction.type == 'income';
    final color = isIncome ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _moneyFormat.format(transaction.amount),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
