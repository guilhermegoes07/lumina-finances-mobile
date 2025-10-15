import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/user_profile.dart';
import '../models/financial_goal.dart';
import '../models/app_settings.dart';
import 'transaction_screen.dart';
import 'settings_screen.dart';
import 'financial_goals_screen.dart';
import 'reports_screen.dart';
import 'investments_screen.dart';
import 'forecast_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'ai_assistant_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  String _selectedPeriod = '3M'; // 1M, 3M, 6M, 1A
  final _moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _percentFormat = NumberFormat.decimalPercentPattern(locale: 'pt_BR', decimalDigits: 1);
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn && mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen(isLogin: true)),
        (route) => false,
      );
    }
  }

  Future<void> _loadData() async {
    final transactionModel = Provider.of<TransactionModel>(context, listen: false);
    await transactionModel.loadTransactions();
  }

  List<Map<String, dynamic>> _getMonthlySummary(List<Transaction> transactions) {
    // Agrupa transações por mês/ano
    final Map<String, double> monthTotals = {};
    for (var t in transactions) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      monthTotals[key] = (monthTotals[key] ?? 0) + (t.type == 'income' ? t.amount : -t.amount);
    }
    // Ordena do mais recente para o mais antigo
    final sortedKeys = monthTotals.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((key) {
      final parts = key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final date = DateTime(year, month);
      return {
        'label': '${_monthName(month)} ${year}',
        'value': monthTotals[key]!,
        'date': date,
      };
    }).toList();
  }

  String _monthName(int month) {
    const months = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    final transactionModel = Provider.of<TransactionModel>(context);
    final userProfile = Provider.of<UserProfile>(context);
    final goalModel = Provider.of<FinancialGoalModel>(context);
    final appSettings = Provider.of<AppSettings>(context);
    
    // Visão mensal dinâmica
    final monthlySummary = _getMonthlySummary(transactionModel.transactions);
    final totalAcumulado = monthlySummary.isNotEmpty ? monthlySummary.first['value'] as double : 0.0;
    final variacao = (monthlySummary.length > 1 && monthlySummary[1]['value'] != 0)
        ? ((monthlySummary.first['value'] - monthlySummary[1]['value']) / monthlySummary[1]['value']) * 100
        : 0.0;

    // Calcular saldo previsto se a opção estiver ativa
    final now = DateTime.now();
    final predictedBalance = appSettings.showForecast 
        ? transactionModel.getPredictedBalanceForMonth(now.year, now.month)
        : transactionModel.balance;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Lumina Finances', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                userProfile.profileType,
                style: TextStyle(fontSize: 12, color: Colors.black),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Mostrar notificações
            },
          ),
          IconButton(
            icon: Icon(
              Icons.psychology_alt_outlined,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.blueAccent[100] 
                  : Colors.blue,
            ),
            tooltip: 'Assistente de IA',
            onPressed: () {
              // Mostrar o assistente de IA
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIAssistantScreen()),
              );
            },
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: userProfile.avatarUrl.isEmpty
                    ? Text(
                        userProfile.name.isNotEmpty
                            ? userProfile.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.black87),
                      )
                    : null,
                backgroundImage: userProfile.avatarUrl.isNotEmpty
                    ? NetworkImage(userProfile.avatarUrl)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Saldo Atual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        appSettings.showForecast ? 'Saldo Previsto' : 'Saldo Atual',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                      if (appSettings.showForecast)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForecastScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 14,
                                  color: Colors.amber[800],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Ver Previsão',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _moneyFormat.format(predictedBalance),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: appSettings.showForecast ? Colors.amber[700] : null,
                    ),
                  ),
                  if (appSettings.showForecast && transactionModel.pendingTransactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${transactionModel.pendingTransactions.length} transações pendentes',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildSummaryItem(
                        'Entradas',
                        _moneyFormat.format(transactionModel.incomes.fold(0.0, (sum, item) => sum + item.amount)),
                        Colors.green,
                        'income',
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryItem(
                        'Saídas',
                        _moneyFormat.format(transactionModel.expenses.fold(0.0, (sum, item) => sum + item.amount)),
                        Colors.red,
                        'expense',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Metas Financeiras
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 0.8), // Aproximadamente 0.05rem
                  child: Text(
                    'Metas Financeiras',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FinancialGoalsScreen()),
                    );
                  },
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            
            // Lista de metas
            if (goalModel.goals.isEmpty)
              _buildEmptyGoalsCard()
            else
              ...goalModel.goals.take(2).map((goal) => _buildGoalCard(goal)).toList(),
            
            const SizedBox(height: 24),
            
            // Visão Mensal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 0.8), // Aproximadamente 0.05rem
                  child: Text(
                    'Visão Mensal',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                  ),
                ),
                Row(
                  children: [
                    _buildPeriodChip('1M'),
                    _buildPeriodChip('3M'),
                    _buildPeriodChip('6M'),
                    _buildPeriodChip('1A'),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Acumulado',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _moneyFormat.format(totalAcumulado),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Variação',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            variacao >= 0
                                ? '+${variacao.toStringAsFixed(1)}%'
                                : '${variacao.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: variacao >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Padding(
                    padding: const EdgeInsets.only(left: 0.8), // Aproximadamente 0.05rem
                    child: Text(
                      'Gráfico de Linha - Evolução Mensal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.black87,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  monthlySummary.length >= 2
                      ? Container(
                          height: 200,
                          width: double.infinity,
                          padding: const EdgeInsets.only(right: 16, top: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[850] // Fundo levemente mais claro para o gráfico no modo escuro
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Theme.of(context).brightness == Brightness.dark
                                ? Border.all(color: Colors.grey[700]!, width: 1)
                                : null,
                          ),
                          child: _buildMonthlyChart(monthlySummary),
                        )
                      : Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Dados insuficientes para gerar o gráfico',
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                  
                  const SizedBox(height: 16),
                  
                  // Lista de meses reais
                  ...monthlySummary.take(6).map((m) => _buildMonthItem(m['label'], m['value'],
                    transactionModel.getTransactionsByMonth(m['date'].year, m['date'].month).length)),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Últimas Transações
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 0.8), // Aproximadamente 0.05rem
                  child: Text(
                    'Últimas Transações',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black87,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TransactionListScreen()),
                    );
                  },
                  child: const Text('Ver todas'),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            if (transactionModel.transactions.isEmpty)
              _buildEmptyTransactionsCard()
            else
              ...transactionModel.transactions
                  .take(5)
                  .map((t) => _buildTransactionItem(t))
                  .toList(),
            
            const SizedBox(height: 16),
          
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Investimentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Adicionar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            label: 'Relatórios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            // Investimentos
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InvestmentsScreen()),
            );
          } else if (index == 2) {
            // Adicionar transação
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionScreen()),
            );
          } else if (index == 3) {
            // Relatórios
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportsScreen()),
            );
          } else if (index == 4) {
            // Configurações
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          }
        },
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color, String transactionType) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // Criar uma transação temporária com o tipo pré-selecionado
          final tempTransaction = Transaction(
            title: '',
            amount: 0.0,
            date: DateTime.now(),
            category: '',
            type: transactionType,
            isRecurring: false,
            recurrenceFrequency: 'monthly',
            description: '',
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionScreen(transaction: tempTransaction),
            ),
          ).then((result) {
            // Recarregar dados quando retornar da tela de transação
            if (result == true) {
              _loadData();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(isDarkMode ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: isDarkMode ? color.withOpacity(0.7) : color.withOpacity(0.6),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? color.withOpacity(0.9) : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final isSelected = _selectedPeriod == period;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? Colors.blue[700] : Colors.blue) 
              : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16),
          border: isDarkMode && !isSelected 
              ? Border.all(color: Colors.grey[700]!, width: 1) 
              : null,
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected 
                ? Colors.white 
                : (isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(FinancialGoal goal) {
    final progress = goal.progressPercentage * 100;
    final daysLeft = goal.daysLeft;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mutedTextColor = isDarkMode ? Colors.white70 : Colors.grey[600];
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${_moneyFormat.format(goal.currentAmount)} / ${_moneyFormat.format(goal.targetAmount)}',
                style: TextStyle(
                  fontSize: 14,
                  color: mutedTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 75 ? Colors.green : Colors.blue,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                daysLeft > 0
                    ? '$daysLeft dias restantes'
                    : 'Prazo atingido',
                style: TextStyle(
                  fontSize: 14,
                  color: daysLeft > 0 ? mutedTextColor : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGoalsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 48,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma meta financeira definida',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Defina suas metas e acompanhe seu progresso',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FinancialGoalsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Criar uma meta'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthItem(String month, double value, int transactions) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white70 : Colors.grey[600];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          left: BorderSide(
            color: Colors.blue,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$transactions transações',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _moneyFormat.format(value),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '+18%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isExpense = transaction.type == 'expense';
    final iconData = isExpense ? Icons.arrow_upward : Icons.arrow_downward;
    final iconColor = isExpense ? Colors.red : Colors.green;
    final formattedDate = DateFormat.yMMMd('pt_BR').format(transaction.date);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mutedTextColor = isDarkMode ? Colors.white70 : Colors.grey[600];

    return InkWell(
      onTap: () => _showTransactionDetailsModal(transaction),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                iconData,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 16),
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
                    '${transaction.category} • $formattedDate',
                    style: TextStyle(
                      fontSize: 12,
                      color: mutedTextColor,
                    ),
                  ),
                  if (transaction.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        transaction.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: mutedTextColor,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${_moneyFormat.format(transaction.amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetailsModal(Transaction transaction) {
    final isExpense = transaction.type == 'expense';
    final iconColor = isExpense ? Colors.red : Colors.green;
    final formattedDate = DateFormat.yMMMMd('pt_BR').format(transaction.date);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                    color: iconColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      transaction.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: transaction.id == null ? 'Não é possível excluir transação antiga' : 'Remover',
                    onPressed: transaction.id == null
                        ? () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Não é possível excluir transações antigas. Adicione uma nova para testar a exclusão!'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        : () async {
                            Navigator.pop(context);
                            final transactionModel = Provider.of<TransactionModel>(context, listen: false);
                            await transactionModel.deleteTransaction(transaction.id!);
                          },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${transaction.category} • $formattedDate',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Valor: ${isExpense ? '-' : '+'}${_moneyFormat.format(transaction.amount)}',
                style: TextStyle(fontSize: 16, color: iconColor, fontWeight: FontWeight.bold),
              ),
              if (transaction.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(transaction.description),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyTransactionsCard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma transação registrada',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece a registrar suas receitas e despesas',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Adicionar transação'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(List<Map<String, dynamic>> data) {
    // Garantir que temos dados suficientes
    if (data.length < 2) {
      return const Center(child: Text('Dados insuficientes'));
    }

    // Organizar os dados do mais antigo para o mais recente
    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Encontrar os valores mínimo e máximo para ajustar a escala do gráfico
    double minY = 0;
    double maxY = 0;

    for (var item in sortedData) {
      final value = item['value'] as double;
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    // Adicionar uma margem de 10% para visualização melhor
    minY = minY * 1.1;
    maxY = maxY * 1.1;

    // Detectar se estamos no modo escuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Cor do texto adaptável ao tema - mais contrastante no modo escuro
    final textColor = isDarkMode ? Colors.white : Colors.grey[800];
    
    // Cor da grade adaptável ao tema - mais visível no modo escuro
    final gridColor = isDarkMode ? Colors.white30 : Colors.grey.withOpacity(0.2);
    
    // Cor dos pontos/linhas adaptável ao tema - mais vibrante no modo escuro
    final lineColor = isDarkMode ? Colors.lightBlue[300]! : Theme.of(context).primaryColor;
    final dotColor = isDarkMode ? Colors.lightBlue[300]! : Theme.of(context).primaryColor;
    final areaColor = isDarkMode ? Colors.lightBlue[300]!.withOpacity(0.25) : lineColor.withOpacity(0.15);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: gridColor,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  _moneyFormat.format(value).split(',')[0],
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: isDarkMode ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= sortedData.length || value.toInt() < 0) {
                  return const SizedBox();
                }
                
                // Abreviação do mês
                final month = sortedData[value.toInt()]['label'].toString().split(' ')[0];
                return Text(
                  month.substring(0, 3), // Primeiros 3 caracteres
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: isDarkMode ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(sortedData.length, (index) {
              return FlSpot(index.toDouble(), sortedData[index]['value'] as double);
            }),
            isCurved: true,
            color: lineColor,
            barWidth: isDarkMode ? 4 : 3, // Linha mais grossa no modo escuro
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: isDarkMode ? 5 : 4, // Pontos maiores no modo escuro
                  color: dotColor,
                  strokeWidth: 2,
                  strokeColor: isDarkMode ? Colors.black : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: areaColor,
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: isDarkMode ? Colors.grey[800]! : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                final value = barSpot.y;
                return LineTooltipItem(
                  _moneyFormat.format(value),
                  TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
        minX: 0,
        maxX: sortedData.length - 1.0,
        minY: minY < 0 ? minY : 0, // Permitir valores negativos
        maxY: maxY,
        backgroundColor: isDarkMode ? Colors.grey[900] : null, // Fundo levemente mais claro para o modo escuro
      ),
    );
  }
}

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final transactionModel = Provider.of<TransactionModel>(context);
    final transactions = transactionModel.transactions;
    return Scaffold(
      appBar: AppBar(title: const Text('Todas as Transações')),
      body: transactions.isEmpty
          ? Center(child: Text('Nenhuma transação encontrada'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final t = transactions[index];
                return TransactionItem(
                  transaction: t,
                  onTap: (transaction) {
                    // Chama o modal de detalhes do dashboard
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        final isExpense = transaction.type == 'expense';
                        final iconColor = isExpense ? Colors.red : Colors.green;
                        final formattedDate = DateFormat.yMMMMd('pt_BR').format(transaction.date);
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: iconColor,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      transaction.title,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    tooltip: transaction.id == null ? 'Não é possível excluir transação antiga' : 'Remover',
                                    onPressed: transaction.id == null
                                        ? () {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Não é possível excluir transações antigas. Adicione uma nova para testar a exclusão!'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                          }
                                        : () async {
                                            Navigator.pop(context);
                                            final transactionModel = Provider.of<TransactionModel>(context, listen: false);
                                            await transactionModel.deleteTransaction(transaction.id!);
                                          },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${transaction.category} • $formattedDate',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Valor: ${isExpense ? '-' : '+'}${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(transaction.amount)}',
                                style: TextStyle(fontSize: 16, color: iconColor, fontWeight: FontWeight.bold),
                              ),
                              if (transaction.description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(transaction.description),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
} 