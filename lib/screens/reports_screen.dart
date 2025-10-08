import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../services/export_import_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = '1M';
  late DateTime _startDate;
  late DateTime _endDate;
  final _moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _setPeriod('1M');
  }

  void _setPeriod(String period) {
    final now = DateTime.now();
    DateTime start;
    if (period == '1M') {
      start = DateTime(now.year, now.month, 1);
    } else if (period == '3M') {
      start = DateTime(now.year, now.month - 2, 1);
    } else if (period == '6M') {
      start = DateTime(now.year, now.month - 5, 1);
    } else {
      start = DateTime(now.year - 1, now.month, 1);
    }
    setState(() {
      _selectedPeriod = period;
      _startDate = start;
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
  }

  Future<void> _exportTransactions() async {
    try {
      final transactionModel = Provider.of<TransactionModel>(context, listen: false);
      final transactions = transactionModel.transactions;
      
      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não há transações para exportar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Solicitar permissão de armazenamento no Android
      if (Platform.isAndroid) {
        // Verificar versão do Android
        bool permissionGranted = false;
        
        // Tentar permissão de armazenamento padrão primeiro
        PermissionStatus storageStatus = await Permission.storage.status;
        
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }
        
        if (storageStatus.isGranted) {
          permissionGranted = true;
        } else if (storageStatus.isPermanentlyDenied) {
          // Permissão negada permanentemente, mostrar dialog para abrir configurações
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Permissão Necessária'),
                content: const Text(
                  'Para exportar o extrato, é necessário permitir o acesso ao armazenamento.\n\n'
                  'Deseja abrir as configurações do aplicativo?'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Abrir Configurações'),
                  ),
                ],
              );
            },
          );
          
          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
          return;
        } else {
          // Tentar permissão alternativa para Android 13+
          PermissionStatus manageStatus = await Permission.manageExternalStorage.status;
          
          if (!manageStatus.isGranted) {
            manageStatus = await Permission.manageExternalStorage.request();
          }
          
          if (manageStatus.isGranted) {
            permissionGranted = true;
          }
        }
        
        if (!permissionGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de armazenamento negada. Não é possível exportar o arquivo.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      }

      // Mostrar indicador de carregamento
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Exportando extrato...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final file = await ExportImportService.exportTransactions(
        transactions: transactions,
      );
      
      final fileName = file.path.split('/').last;
      final folderName = Platform.isAndroid ? 'Downloads' : 'Documentos';
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ Extrato exportado com sucesso!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Arquivo: $fileName'),
                Text('Local: Pasta $folderName'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _exportAndShareTransactions() async {
    try {
      final transactionModel = Provider.of<TransactionModel>(context, listen: false);
      final transactions = transactionModel.transactions;
      
      if (transactions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não há transações para exportar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar indicador de carregamento
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Preparando extrato...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Exportar para um arquivo temporário (não precisa de permissões)
      final file = await ExportImportService.exportTransactions(
        transactions: transactions,
      );
      
      // Compartilhar o arquivo usando o share nativo do sistema
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Extrato Lumina Finances',
        text: 'Extrato com ${transactions.length} transações exportado do Lumina Finances',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Extrato compartilhado com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else if (result.status == ShareResultStatus.dismissed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compartilhamento cancelado'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _importTransactions() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        
        // Validar arquivo
        final isValid = await ExportImportService.validateImportFile(file);
        if (!isValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arquivo inválido. Selecione um arquivo de extrato válido do Lumina Finances.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Obter estatísticas do arquivo
        final stats = await ExportImportService.getImportStatistics(file);
        
        // Mostrar dialog de confirmação
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar Importação'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Arquivo: ${result.files.single.name}'),
                  const SizedBox(height: 8),
                  Text('Total de transações: ${stats['total_transactions']}'),
                  Text('Entradas: ${stats['income_count']} (${_moneyFormat.format(stats['total_income'])})'),
                  Text('Saídas: ${stats['expense_count']} (${_moneyFormat.format(stats['total_expense'])})'),
                  const SizedBox(height: 8),
                  const Text('Deseja importar essas transações?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Importar'),
                ),
              ],
            );
          },
        );

        if (confirmed == true) {
          // Importar transações
          final importedTransactions = await ExportImportService.importTransactions(file);
          final transactionModel = Provider.of<TransactionModel>(context, listen: false);
          
          for (var transaction in importedTransactions) {
            await transactionModel.addTransaction(transaction);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${importedTransactions.length} transações importadas com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao importar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionModel = Provider.of<TransactionModel>(context);
    final transactions = transactionModel.getTransactionsByPeriod(
      startDate: _startDate,
      endDate: _endDate,
    );
    final expenses = transactions.where((t) => t.type == 'expense').toList();
    final incomes = transactions.where((t) => t.type == 'income').toList();
    final totalExpenses = expenses.fold(0.0, (sum, t) => sum + t.amount);
    final totalIncomes = incomes.fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncomes - totalExpenses;
    final expensesByCategory = <String, double>{};
    for (var t in expenses) {
      expensesByCategory[t.category] = (expensesByCategory[t.category] ?? 0) + t.amount;
    }
    final sortedCategories = expensesByCategory.keys.toList()
      ..sort((a, b) => expensesByCategory[b]!.compareTo(expensesByCategory[a]!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Filtros de período
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Período',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

          // Ações de Extrato
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gerenciar Extrato',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportTransactions,
                          icon: const Icon(Icons.save_alt, size: 20),
                          label: const Text('Salvar', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportAndShareTransactions,
                          icon: const Icon(Icons.share, size: 20),
                          label: const Text('Compartilhar', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _importTransactions,
                          icon: const Icon(Icons.file_upload, size: 20),
                          label: const Text('Importar', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Salve na pasta Downloads, compartilhe via WhatsApp/Email ou importe de outro dispositivo.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Gráfico de pizza (despesas por categoria)
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Despesas por Categoria',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  expensesByCategory.isEmpty
                      ? const Center(child: Text('Sem despesas no período'))
                      : Center(
                          child: AspectRatio(
                            aspectRatio: 1.2,
                            child: _buildPieChart(expensesByCategory),
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Gráfico de barras (entradas/saídas por mês)
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Entradas e Saídas Mensais',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1.8, // Proporção mais larga para gráfico de barras
                    child: _buildBarChart(transactions),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lista detalhada de categorias
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalhamento por Categoria',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ...sortedCategories.map((cat) => ListTile(
                        title: Text(cat),
                        trailing: Text(_moneyFormat.format(expensesByCategory[cat])),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Resumo
          Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Entradas:'),
                      Text(_moneyFormat.format(totalIncomes), style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saídas:'),
                      Text(_moneyFormat.format(totalExpenses), style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo no período:'),
                      Text(_moneyFormat.format(balance), style: TextStyle(color: balance >= 0 ? Colors.green : Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => _setPeriod(period),
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('Sem dados'));
    }
    final colors = [
      Colors.blue, Colors.orange, Colors.green, Colors.purple, Colors.red, Colors.teal, Colors.brown
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxHeight < constraints.maxWidth ? constraints.maxHeight : constraints.maxWidth) * 0.6;
        return Stack(
          children: [
            Center(
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  painter: _PieChartPainter(data, total, colors),
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(size * 0.13),
                  child: Text(
                    'Total\n${_moneyFormat.format(total)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBarChart(List<Transaction> transactions) {
    // Agrupa por mês
    final Map<String, double> incomes = {};
    final Map<String, double> expenses = {};
    for (var t in transactions) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      if (t.type == 'income') {
        incomes[key] = (incomes[key] ?? 0) + t.amount;
      } else if (t.type == 'expense') {
        expenses[key] = (expenses[key] ?? 0) + t.amount;
      }
    }
    final allKeys = {...incomes.keys, ...expenses.keys}.toList()
      ..sort((a, b) => a.compareTo(b));
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = 18.0;
        final maxBarHeight = constraints.maxHeight - 40;
        final maxIncome = incomes.values.isEmpty ? 0 : incomes.values.reduce((a, b) => a > b ? a : b);
        final maxExpense = expenses.values.isEmpty ? 0 : expenses.values.reduce((a, b) => a > b ? a : b);
        final maxValue = [maxIncome, maxExpense, 1.0].reduce((a, b) => a > b ? a : b);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: allKeys.map((key) {
            final income = incomes[key] ?? 0;
            final expense = expenses[key] ?? 0;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(_monthLabel(key), style: const TextStyle(fontSize: 10)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: barWidth,
                        height: (income / maxValue) * maxBarHeight,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: barWidth,
                        height: (expense / maxValue) * maxBarHeight,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    const months = [
      '', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return '${months[month]}/$year';
  }
}

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double total;
  final List<Color> colors;

  _PieChartPainter(this.data, this.total, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22;
    final radius = size.width / 2;
    double start = -3.14 / 2;
    int colorIndex = 0;
    data.forEach((cat, value) {
      final sweep = (value / total) * 3.14 * 2;
      paint.color = colors[colorIndex % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius / 1.18),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
      colorIndex++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 