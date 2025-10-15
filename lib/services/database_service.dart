import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'lumina_finances.db');
    
    return openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    // Tabela de transações
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        date TEXT,
        category TEXT,
        type TEXT,
        isRecurring INTEGER,
        recurrenceFrequency TEXT,
        description TEXT
      )
    ''');

    // Tabela de objetivos financeiros
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        targetAmount REAL,
        currentAmount REAL,
        startDate TEXT,
        targetDate TEXT,
        icon TEXT,
        description TEXT
      )
    ''');

    // Tabela de categorias
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        type TEXT,
        icon TEXT,
        color INTEGER
      )
    ''');

    // Inserir categorias padrão
    await _insertDefaultCategories(db);
  }

  static Future<void> _insertDefaultCategories(Database db) async {
    List<Map<String, dynamic>> expenseCategories = [
      {'name': 'Alimentação', 'type': 'expense', 'icon': 'restaurant', 'color': 0xFFFF5252},
      {'name': 'Transporte', 'type': 'expense', 'icon': 'directions_car', 'color': 0xFF448AFF},
      {'name': 'Moradia', 'type': 'expense', 'icon': 'home', 'color': 0xFF9C27B0},
      {'name': 'Lazer', 'type': 'expense', 'icon': 'movie', 'color': 0xFF4CAF50},
      {'name': 'Saúde', 'type': 'expense', 'icon': 'favorite', 'color': 0xFFFF9800},
      {'name': 'Educação', 'type': 'expense', 'icon': 'school', 'color': 0xFF795548},
      {'name': 'Compras', 'type': 'expense', 'icon': 'shopping_cart', 'color': 0xFFE91E63},
    ];

    List<Map<String, dynamic>> incomeCategories = [
      {'name': 'Salário', 'type': 'income', 'icon': 'account_balance_wallet', 'color': 0xFF00C853},
      {'name': 'Investimentos', 'type': 'income', 'icon': 'trending_up', 'color': 0xFF00BCD4},
      {'name': 'Freelance', 'type': 'income', 'icon': 'work', 'color': 0xFFAB47BC},
      {'name': 'Outros', 'type': 'income', 'icon': 'attach_money', 'color': 0xFF8BC34A},
    ];

    final batch = db.batch();
    
    for (var category in [...expenseCategories, ...incomeCategories]) {
      batch.insert('categories', category);
    }
    
    await batch.commit();
  }

  // Métodos auxiliares para gerenciar categorias
  static Future<List<Map<String, dynamic>>> getCategories(String type) async {
    final db = await database;
    return db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
    );
  }

  static Future<void> addCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.insert('categories', category);
  }

  static Future<void> updateCategory(int id, Map<String, dynamic> category) async {
    final db = await database;
    await db.update(
      'categories',
      category,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
} 