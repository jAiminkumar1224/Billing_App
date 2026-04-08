import 'package:billing_app/screens/login_screen.dart';
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
  final VoidCallback? onReturn;

  const AppSidebar({super.key, required this.selectedIndex, this.onReturn});

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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BillScreen()),
              ).then((_) {
                if (onReturn != null) {
                  onReturn!();
                }
              });
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

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAEA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
            ),
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

    final data = await db.query(
      'invoices',
      orderBy: 'CAST(invoiceNo AS INTEGER) DESC',
    );

    var totalResult = await db.rawQuery(
      "SELECT SUM(netTotal) as total FROM invoices WHERE paymentStatus = 'Payment Received'",
    );

    totalSales = totalResult.first['total'] == null
        ? 0
        : (totalResult.first['total'] as num).toDouble();

    totalInvoices = data.length;

    double totalPendingCalc = 0;

    for (var bill in data) {
      double total = ((bill['netTotal'] as num?) ?? 0).toDouble();
      double paid = ((bill['paidAmount'] as num?) ?? 0).toDouble();

      double remaining = total - paid;

      if (remaining > 0) {
        totalPendingCalc += remaining;
      }
    }

    pendingAmount = totalPendingCalc;

    pendingList = await db.query(
      'invoices',
      where: "paymentStatus != ?",
      whereArgs: ["Payment Received"],
      orderBy: 'invoiceDate DESC',
    );

    topCustomers = await db.rawQuery('''
    SELECT receiverName, SUM(netTotal) as totalSpent
    FROM invoices
    GROUP BY receiverName
    ORDER BY totalSpent DESC
    LIMIT 5
  ''');

    ///     TOTAL CUSTOMERS
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),

      body: Row(
        children: [
          AppSidebar(selectedIndex: 1, onReturn: loadAllData),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _modernCard(
                          title: "Revenue",
                          value: "₹ $totalSales",
                          color: Colors.green,
                          icon: Icons.show_chart,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SalesReportScreen(),
                              ),
                            ).then((_) => loadAllData());
                          },
                        ),
                      ),

                      Expanded(
                        child: _modernCard(
                          title: "Invoices",
                          value: "$totalInvoices",
                          color: Colors.blue,
                          icon: Icons.receipt_long,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllInvoices(),
                              ),
                            ).then((_) => loadAllData());
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _modernCard(
                          title: "Outstanding",
                          value: "₹ $pendingAmount",
                          color: Colors.red,
                          icon: Icons.warning_amber,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PendingBills(),
                              ),
                            ).then((_) => loadAllData());
                          },
                        ),
                      ),

                      Expanded(
                        child: _modernCard(
                          title: "Clients",
                          value: "$totalCustomers",
                          color: Colors.purple,
                          icon: Icons.people,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CustomerDetails(),
                              ),
                            ).then((_) => loadAllData());
                          },
                        ),
                      ),
                    ],
                  ),

                  /// ================= RECENT ACTIVITY ================
                  const SizedBox(height: 10),

                  ///  MAIN CONTENT AREA
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _recentTable()),

                      const SizedBox(width: 16),
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

  Widget _modernCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 10),

            /// VALUE
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 12),

            /// ICON
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(icon, color: color.withOpacity(0.7), size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Activity",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 300,
            width: double.infinity,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("No.")),
                DataColumn(label: Text("Invoice")),
                DataColumn(label: Text("Client")),
                DataColumn(label: Text("Date")),
                DataColumn(label: Text("Amount")),
                DataColumn(label: Text("Status")),
              ],
              rows: invoiceList.take(5).toList().asMap().entries.map((e) {
                final index = e.key;
                final invoice = e.value;
                return DataRow(
                  cells: [
                    DataCell(Text("${index + 1}")),
                    DataCell(Text(invoice['invoiceNo'].toString())),
                    DataCell(Text(invoice['receiverName'].toString())),
                    DataCell(Text(_formatDate(invoice['createdAt']))),
                    DataCell(Text("₹ ${invoice['netTotal']}")),

                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(invoice['paymentStatus']),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          invoice['paymentStatus'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == "Payment Received") return Colors.green;
    if (status == "Partial") return Colors.orange;
    return Colors.red;
  }

  String _formatDate(String rawDateTime) {
  final date = DateTime.parse(rawDateTime);

  int hour = date.hour;
  String period = "AM";

  if (hour >= 12) {
    period = "PM";
    if (hour > 12) hour -= 12;
  }

  if (hour == 0) {
    hour = 12;
  }

  String minute = date.minute.toString().padLeft(2, '0');

  return "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year} "
      "$hour:$minute $period";
}
}
