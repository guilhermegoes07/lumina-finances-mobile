import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class ExportImportService {
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Exporta as transações para um arquivo JSON
  static Future<File> exportTransactions({
    required List<Transaction> transactions,
    String? fileName,
  }) async {
    try {
      // Obter o diretório apropriado
      Directory? directory;
      
      if (Platform.isAndroid) {
        // Para Android, tentar primeiro o diretório externo de downloads
        try {
          // Tentar a pasta pública de Downloads
          final possiblePaths = [
            '/storage/emulated/0/Download',
            '/storage/emulated/0/Downloads',
          ];
          
          for (var path in possiblePaths) {
            final dir = Directory(path);
            if (await dir.exists()) {
              directory = dir;
              break;
            }
          }
          
          // Se não encontrou, usar o diretório de documentos externos
          if (directory == null) {
            directory = await getExternalStorageDirectory();
            if (directory != null) {
              // Criar subpasta "Lumina" dentro do diretório do app
              directory = Directory('${directory.path}/Extratos');
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }
            }
          }
        } catch (e) {
          // Fallback para diretório de documentos do app
          directory = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isIOS) {
        // Para iOS, usar o diretório de documentos
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Para outras plataformas, usar documentos
        directory = await getApplicationDocumentsDirectory();
      }
      
      if (directory == null) {
        throw Exception('Não foi possível acessar o diretório de armazenamento');
      }
      
      // Criar nome do arquivo se não fornecido
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName = 'extrato_lumina_$timestamp.json';
      final actualFileName = fileName ?? defaultFileName;
      
      // Criar o arquivo
      final file = File('${directory.path}/$actualFileName');
      
      // Preparar dados para exportação
      final exportData = {
        'app': 'Lumina Finances',
        'version': '1.0.0',
        'export_date': DateTime.now().toIso8601String(),
        'total_transactions': transactions.length,
        'transactions': transactions.map((transaction) => {
          'id': transaction.id,
          'title': transaction.title,
          'amount': transaction.amount,
          'date': _dateFormat.format(transaction.date),
          'category': transaction.category,
          'type': transaction.type,
          'is_recurring': transaction.isRecurring,
          'recurrence_frequency': transaction.recurrenceFrequency,
          'description': transaction.description,
        }).toList(),
      };
      
      // Escrever o JSON no arquivo
      final jsonString = JsonEncoder.withIndent('  ').convert(exportData);
      await file.writeAsString(jsonString);
      
      return file;
    } catch (e) {
      throw Exception('Erro ao exportar transações: $e');
    }
  }

  /// Importa transações de um arquivo JSON
  static Future<List<Transaction>> importTransactions(File file) async {
    try {
      // Verificar se o arquivo existe
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado');
      }
      
      // Ler o conteúdo do arquivo
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      // Verificar se é um arquivo válido do Lumina Finances
      if (data['app'] != 'Lumina Finances') {
        throw Exception('Arquivo não é um extrato válido do Lumina Finances');
      }
      
      // Extrair as transações
      final List<dynamic> transactionsData = data['transactions'] ?? [];
      
      final List<Transaction> transactions = transactionsData.map((transactionData) {
        return Transaction(
          title: transactionData['title'] ?? '',
          amount: (transactionData['amount'] ?? 0.0).toDouble(),
          date: _parseDate(transactionData['date'] ?? ''),
          category: transactionData['category'] ?? 'Outros',
          type: transactionData['type'] ?? 'expense',
          isRecurring: transactionData['is_recurring'] ?? false,
          recurrenceFrequency: transactionData['recurrence_frequency'] ?? 'monthly',
          description: transactionData['description'] ?? '',
        );
      }).toList();
      
      return transactions;
    } catch (e) {
      throw Exception('Erro ao importar transações: $e');
    }
  }

  /// Valida se um arquivo JSON é um extrato válido
  static Future<bool> validateImportFile(File file) async {
    try {
      if (!await file.exists()) {
        return false;
      }
      
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      // Verificações básicas
      if (data['app'] != 'Lumina Finances') {
        return false;
      }
      
      if (data['transactions'] == null || data['transactions'] is! List) {
        return false;
      }
      
      // Verificar se pelo menos uma transação tem os campos obrigatórios
      final List<dynamic> transactions = data['transactions'];
      if (transactions.isNotEmpty) {
        final firstTransaction = transactions.first;
        if (firstTransaction['title'] == null ||
            firstTransaction['amount'] == null ||
            firstTransaction['date'] == null ||
            firstTransaction['type'] == null) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Parse da data com fallback para data atual em caso de erro
  static DateTime _parseDate(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Obter estatísticas do arquivo de importação
  static Future<Map<String, dynamic>> getImportStatistics(File file) async {
    try {
      if (!await file.exists()) {
        throw Exception('Arquivo não encontrado');
      }
      
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      final List<dynamic> transactions = data['transactions'] ?? [];
      
      double totalIncome = 0.0;
      double totalExpense = 0.0;
      int incomeCount = 0;
      int expenseCount = 0;
      
      for (var transaction in transactions) {
        final amount = (transaction['amount'] ?? 0.0).toDouble();
        final type = transaction['type'] ?? 'expense';
        
        if (type == 'income') {
          totalIncome += amount;
          incomeCount++;
        } else {
          totalExpense += amount;
          expenseCount++;
        }
      }
      
      return {
        'total_transactions': transactions.length,
        'total_income': totalIncome,
        'total_expense': totalExpense,
        'income_count': incomeCount,
        'expense_count': expenseCount,
        'export_date': data['export_date'],
        'app_version': data['version'],
      };
    } catch (e) {
      throw Exception('Erro ao obter estatísticas: $e');
    }
  }
}