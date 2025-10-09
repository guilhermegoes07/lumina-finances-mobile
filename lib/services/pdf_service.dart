import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart';
import '../models/financial_goal.dart';

class PdfService {
  static final _moneyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  static Future<File> generateTransactionsReport({
    required List<Transaction> transactions,
    required double balance,
    required double totalIncome,
    required double totalExpenses,
  }) async {
    final pdf = pw.Document();

    // Agrupar transações por categoria
    final Map<String, double> expensesByCategory = {};
    final Map<String, double> incomeByCategory = {};
    
    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        expensesByCategory[transaction.category] = 
            (expensesByCategory[transaction.category] ?? 0) + transaction.amount;
      } else {
        incomeByCategory[transaction.category] = 
            (incomeByCategory[transaction.category] ?? 0) + transaction.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabeçalho
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Lumina Finances',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Relatório de Transações',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Resumo Financeiro
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Resumo Financeiro',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem('Saldo Atual', _moneyFormat.format(balance), PdfColors.blue700),
                      _buildSummaryItem('Receitas', _moneyFormat.format(totalIncome), PdfColors.green700),
                      _buildSummaryItem('Despesas', _moneyFormat.format(totalExpenses), PdfColors.red700),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Despesas por Categoria
            if (expensesByCategory.isNotEmpty) ...[
              pw.Text(
                'Despesas por Categoria',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Categoria', 'Valor', '% do Total'],
                data: expensesByCategory.entries.map((entry) {
                  final percentage = (entry.value / totalExpenses * 100).toStringAsFixed(1);
                  return [
                    entry.key,
                    _moneyFormat.format(entry.value),
                    '$percentage%',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue700,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellHeight: 30,
              ),
              pw.SizedBox(height: 24),
            ],

            // Receitas por Categoria
            if (incomeByCategory.isNotEmpty) ...[
              pw.Text(
                'Receitas por Categoria',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Categoria', 'Valor', '% do Total'],
                data: incomeByCategory.entries.map((entry) {
                  final percentage = (entry.value / totalIncome * 100).toStringAsFixed(1);
                  return [
                    entry.key,
                    _moneyFormat.format(entry.value),
                    '$percentage%',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.green700,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellHeight: 30,
              ),
              pw.SizedBox(height: 24),
            ],

            // Lista de Transações
            pw.Text(
              'Histórico de Transações',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table.fromTextArray(
              headers: ['Data', 'Descrição', 'Categoria', 'Valor', 'Tipo'],
              data: transactions.map((transaction) {
                return [
                  _dateFormat.format(transaction.date),
                  transaction.title,
                  transaction.category,
                  _moneyFormat.format(transaction.amount),
                  transaction.type == 'income' ? 'Receita' : 'Despesa',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey700,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
            ),

            pw.SizedBox(height: 32),

            // Rodapé
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Relatório gerado em ${_dateFormat.format(DateTime.now())} às ${DateFormat('HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ];
        },
      ),
    );

    // Salvar o arquivo
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final filename = 'lumina_finances_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static Future<File> generateGoalsReport({
    required List<FinancialGoal> goals,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabeçalho
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Lumina Finances',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Relatório de Metas Financeiras',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Lista de Metas
            pw.Text(
              'Suas Metas Financeiras',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),

            ...goals.map((goal) {
              final progress = (goal.currentAmount / goal.targetAmount * 100).toStringAsFixed(1);
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 16),
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      goal.name,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Meta: ${_moneyFormat.format(goal.targetAmount)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                        pw.Text(
                          'Atual: ${_moneyFormat.format(goal.currentAmount)}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Progresso: $progress%',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.blue700,
                          ),
                        ),
                        if (goal.deadline != null)
                          pw.Text(
                            'Prazo: ${_dateFormat.format(goal.deadline!)}',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    if (goal.description.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Text(
                        goal.description,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),

            pw.SizedBox(height: 32),

            // Rodapé
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Text(
              'Relatório gerado em ${_dateFormat.format(DateTime.now())} às ${DateFormat('HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ];
        },
      ),
    );

    // Salvar o arquivo
    final directory = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final filename = 'lumina_finances_metas_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
    final file = File('${directory.path}/$filename');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
