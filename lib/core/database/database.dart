import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'beleza_app.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // CLIENTES
        await db.execute('''
          CREATE TABLE clients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT
          )
        ''');

        // SERVIÇOS
        await db.execute('''
          CREATE TABLE services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL
          )
        ''');

        // ATENDIMENTOS
        await db.execute('''
          CREATE TABLE appointments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id INTEGER,
            service_id INTEGER,
            date TEXT,
            value REAL
          )
        ''');
      },
    );

    return _db!;
  }
}