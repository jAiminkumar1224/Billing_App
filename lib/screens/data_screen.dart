import 'package:flutter/material.dart';
import 'package:billing_app/database/database_helper.dart';
import 'bill_screen.dart';

import 'Reports/sales_report_screen.dart';
import 'Reports/all_invoices.dart';
import 'Reports/pending_bills.dart';
import 'Reports/customer_details.dart';

/// ================= SIDEBAR =================
class AppSidebar extends StatelessWidget {
  final int selectedIndex;

  const AppSidebar({super.key, required this.selectedIndex});

  Widget buildItem({
    required BuildContext context,
    required IconData icon,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE6F0FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),

          buildItem(
            context: context,
            icon: Icons.receipt_long,
            index: 0,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BillScreen()),
              );
            },
          ),

          buildItem(
            context: context,
            icon: Icons.storage,
            index: 1,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DataScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ================= MAIN SCREEN =================
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

  Future<void> loadAllData() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.query('invoices', orderBy: 'invoiceDate DESC');

    var total = await db.rawQuery(
      "SELECT SUM(netTotal) as total FROM invoices WHERE paymentStatus = 'Payment Received'",
    );

    totalSales = total.first['total'] == null
        ? 0
        : (total.first['total'] as num).toDouble();

    totalInvoices = data.length;

    var pending = await db.rawQuery(
      "SELECT SUM(netTotal) as total FROM invoices WHERE paymentStatus='Pending'",
    );

    pendingAmount = pending.first['total'] == null
        ? 0
        : (pending.first['total'] as num).toDouble();

    pendingList = await db.query(
      'invoices',
      where: "paymentStatus='Pending'",
      orderBy: 'invoiceDate DESC',
    );

    topCustomers = await db.rawQuery('''
SELECT receiverName, SUM(netTotal) as totalSpent
FROM invoices
GROUP BY receiverName
ORDER BY totalSpent DESC
LIMIT 5
''');

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
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text('Business Dashboard'),
      ),

      body: Row(
        children: [
          const AppSidebar(selectedIndex: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
          SizedBox(
            width: 140,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BillScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Bill'),
            ),
          ),

            const SizedBox(width: 12),

            SizedBox(
              width: 140,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
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
