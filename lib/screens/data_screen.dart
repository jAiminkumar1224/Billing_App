import 'package:flutter/material.dart';
import 'package:billing_app/database/database_helper.dart';
import 'bill_screen.dart';

import 'Reports/sales_report_screen.dart';
import 'Reports/all_invoices.dart';
import 'Reports/pending_bills.dart';
import 'Reports/customer_details.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  List<Map<String, dynamic>> invoiceList = [];
  List<Map<String, dynamic>> topCustomers = [];
  List<Map<String, dynamic>> pendingList = [];

  double totalSales = 0;
  int totalInvoices = 0;
  double pendingAmount = 0;
  int totalCustomers = 0;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  /// ================= LOAD ALL DATA =================
  Future<void> loadAllData() async {
    final db = await DatabaseHelper.instance.database;

    /// all invoices
    final data = await db.query('invoices', orderBy: 'invoiceDate DESC');

    /// total sales
    var total = await db.rawQuery(
      "SELECT SUM(netTotal) as total FROM invoices WHERE paymentStatus = 'Paid'",
    );

    totalSales = total.first['total'] == null
        ? 0
        : (total.first['total'] as num).toDouble();

    /// total invoices
    totalInvoices = data.length;

    /// pending
    var pending = await db.rawQuery(
      "SELECT SUM(netTotal) as total FROM invoices WHERE paymentStatus='Pending'",
    );
    pendingAmount = pending.first['total'] == null
        ? 0
        : pending.first['total'] as double;

    /// pending list
    pendingList = await db.query(
      'invoices',
      where: "paymentStatus='Pending'",
      orderBy: 'invoiceDate DESC',
    );

    /// top customers
    topCustomers = await db.rawQuery('''
SELECT receiverName, SUM(netTotal) as totalSpent
FROM invoices
GROUP BY receiverName
ORDER BY totalSpent DESC
LIMIT 5
''');

    /// total customers
    var cust = await db.rawQuery(
      "SELECT COUNT(DISTINCT receiverName) as total FROM invoices",
    );
    totalCustomers = cust.first['total'] == null
        ? 0
        : cust.first['total'] as int;

    setState(() {
      invoiceList = data;
    });
  }

  /// ================= SEARCH =================
  Future<void> searchData(String value) async {
    if (value.isEmpty) {
      loadAllData();
      return;
    }

    final db = await DatabaseHelper.instance.database;

    final data = await db.query(
      'invoices',
      where: 'invoiceNo LIKE ? OR receiverName LIKE ?',
      whereArgs: ['%$value%', '%$value%'],
      orderBy: 'invoiceDate DESC',
    );

    setState(() {
      invoiceList = data;
    });
  }

  /// ================= WEEKLY =================
  Future<void> loadWeekly() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.rawQuery('''
SELECT * FROM invoices
WHERE date(invoiceDate) >= date('now','-6 days')
ORDER BY invoiceDate DESC
''');

    setState(() {
      invoiceList = data;
    });
  }

  /// ================= MONTHLY =================
  Future<void> loadMonthly() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.rawQuery('''
SELECT * FROM invoices
WHERE strftime('%m', invoiceDate)=strftime('%m','now')
AND strftime('%Y', invoiceDate)=strftime('%Y','now')
ORDER BY invoiceDate DESC
''');

    setState(() {
      invoiceList = data;
    });
  }

  /// ================= YEARLY =================
  Future<void> loadYearly() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.rawQuery('''
SELECT * FROM invoices
WHERE strftime('%Y', invoiceDate)=strftime('%Y','now')
ORDER BY invoiceDate DESC
''');

    setState(() {
      invoiceList = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// DASHBOARD
            Row(
              children: [
                _card(
                  "Total Sales",
                  "₹ $totalSales",
                  Icons.currency_rupee,
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SalesReportScreen(),
                      ),
                    ).then((_) {
                      loadAllData();
                    });
                  },
                ),
                _card(
                  "Invoices",
                  "$totalInvoices",
                  Icons.receipt,
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AllInvoices(),
                      ),
                    ).then((_) {
                      loadAllData();
                    });
                  },
                ),
              ],
            ),
            Row(
              children: [
                _card(
                  "Pending",
                  "₹ $pendingAmount",
                  Icons.pending_actions,
                  Colors.red,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PendingBills(),
                      ),
                    ).then((_) {
                      loadAllData();
                    });
                  },
                ),
                _card(
                  "Customers",
                  "$totalCustomers",
                  Icons.people,
                  Colors.purple,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerDetails(),
                      ),
                    ).then((_) {
                      loadAllData();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// SEARCH
            TextField(
              controller: searchController,
              onChanged: searchData,
              decoration: InputDecoration(
                hintText: "Search Invoice / Customer",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// FILTER BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loadWeekly,
                    child: const Text("Weekly"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loadMonthly,
                    child: const Text("Monthly"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loadYearly,
                    child: const Text("Yearly"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// INVOICE LIST
            _sectionTitle("All Invoices"),
            Container(
              height: 300,
              decoration: _box(),
              child: ListView.builder(
                itemCount: invoiceList.length,
                itemBuilder: (context, index) {
                  final inv = invoiceList[index];
                  return ListTile(
                    title: Text(inv['receiverName'] ?? ""),
                    subtitle: Text(
                      "Inv: ${inv['invoiceNo']}  |  ${inv['invoiceDate']}",
                    ),
                    trailing: Text("₹ ${inv['netTotal']}"),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            /// TOP CUSTOMER
            _sectionTitle("Top Customers"),
            Container(
              height: 180,
              decoration: _box(),
              child: ListView.builder(
                itemCount: topCustomers.length,
                itemBuilder: (c, i) {
                  return ListTile(
                    title: Text(topCustomers[i]['receiverName']),
                    trailing: Text("₹ ${topCustomers[i]['totalSpent']}"),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            /// PENDING
            _sectionTitle("Pending Payments"),
            Container(
              height: 180,
              decoration: _box(),
              child: ListView.builder(
                itemCount: pendingList.length,
                itemBuilder: (c, i) {
                  final p = pendingList[i];
                  return ListTile(
                    title: Text(p['receiverName']),
                    subtitle: Text("Inv ${p['invoiceNo']}"),
                    trailing: Text("₹ ${p['netTotal']}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(16),
          decoration: _box(),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(title),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
