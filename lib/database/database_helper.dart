import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('billing.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceNo TEXT,
  invoiceDate TEXT,
  receiverName TEXT,
  receiverAddress TEXT,
  subtotal REAL,
  discount REAL,
  netTotal REAL,
  paymentStatus TEXT
)
''');

    await db.execute('''
CREATE TABLE invoice_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceId INTEGER,
  itemName TEXT,
  qty INTEGER,
  rate REAL,
  amount REAL
)
''');
  }

  Future<List<Map<String, dynamic>>> getSalesRegisterItems() async {
    final db = await database;

    final result = await db.rawQuery('''
SELECT 
    invoices.invoiceDate,
    invoices.invoiceNo,
    invoice_items.itemName,
    invoice_items.qty,
    invoice_items.rate,
    invoice_items.amount
FROM invoices
JOIN invoice_items 
ON invoices.id = invoice_items.invoiceId
WHERE invoices.paymentStatus='Paid'
ORDER BY invoices.invoiceNo ASC
''');

    return result;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
