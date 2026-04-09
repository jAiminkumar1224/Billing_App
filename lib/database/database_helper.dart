import 'package:billing_app/models/invoice_item_model.dart';
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

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE invoices ADD COLUMN paidAmount REAL DEFAULT 0",
      );

      await db.execute(
        "ALTER TABLE invoices ADD COLUMN dueAmount REAL DEFAULT 0",
      );
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE payments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoiceId INTEGER,
          amount REAL,
          createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (invoiceId) REFERENCES invoices(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 5) {
      try {
        await db.execute(
          "ALTER TABLE invoices ADD COLUMN createdAt TEXT DEFAULT CURRENT_TIMESTAMP",
        );
      } catch (e) {
        print("createdAt column already exists");
      }
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE invoices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceNo TEXT UNIQUE,
  invoiceDate TEXT,

  state TEXT,
  stateCode TEXT,

  receiverName TEXT,
  receiverAddress TEXT,
  receiverGstin TEXT,
  receiverState TEXT,
  receiverStateCode TEXT,
  contactNumber TEXT,
  whatsappNumber TEXT,
  email TEXT,

  poNumber TEXT,
  poDate TEXT,

  subtotal REAL,
  discount REAL,
  netTotal REAL,

  paidAmount REAL DEFAULT 0,
  dueAmount REAL DEFAULT 0,

  paymentStatus TEXT,
  createdAt TEXT DEFAULT CURRENT_TIMESTAMP
)
''');

    await db.execute('''
CREATE TABLE invoice_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceId INTEGER,
  itemName TEXT,
  uom TEXT,
  qty INTEGER,
  rate REAL,
  amount REAL,
  FOREIGN KEY (invoiceId) REFERENCES invoices(id) ON DELETE CASCADE
)
''');

    await db.execute('''
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  invoiceId INTEGER,
  amount REAL,
  createdAt TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (invoiceId) REFERENCES invoices(id) ON DELETE CASCADE
)
''');
  }

  /// ==========================================================
  /// TEMPORARY METHOD : DELETE ALL DATABASE DATA
  /// ----------------------------------------------------------
  /// This will remove:
  /// 1. All Payments
  /// 2. All Invoice Items
  /// 3. All Invoices
  ///
  /// USE ONLY FOR TESTING / DEVELOPMENT
  /// REMOVE AFTER ONE TIME USE
  /// ==========================================================
  // Future<void> clearAllData() async {
  //   final db = await database;

  //   await db.delete('payments');
  //   await db.delete('invoice_items');
  //   await db.delete('invoices');

  //   print("ALL DATABASE DATA CLEARED SUCCESSFULLY");
  // }

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

  Future<List<InvoiceItemModel>> getItemsByInvoiceId(int invoiceId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [invoiceId],
    );

    return result
        .map(
          (e) => InvoiceItemModel(
            id: e['id'] as int?,
            invoiceId: e['invoiceId'] as int,
            itemName: e['itemName'].toString(),
            uom: e['uom'].toString(),
            qty: e['qty'] as int,
            rate: (e['rate'] as num).toDouble(),
            amount: (e['amount'] as num).toDouble(),
          ),
        )
        .toList();
  }
}