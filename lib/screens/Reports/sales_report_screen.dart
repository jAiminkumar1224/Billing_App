import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  List<Map<String, dynamic>> salesList = [];

  double totalSales = 0;
  int totalBills = 0;

  final TextEditingController searchController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  String filterTitle = "All Sales";

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  /// ================= DATE FORMAT =================
  String formatDate(String date) {
    DateTime d = DateTime.parse(date);

    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  /// ================= LOAD SALES =================
  Future<void> loadSales() async {
    final db = await DatabaseHelper.instance.database;

    /// ONLY PAID BILLS
    final data = await db.query(
      'invoices',
      where: "paymentStatus = ?",
      whereArgs: ["Paid"],
      orderBy: "id DESC",
    );

    final total = await db.rawQuery(
      "SELECT SUM(netTotal) as total FROM invoices WHERE paymentStatus = 'Paid'",
    );

    setState(() {
      salesList = data;

      totalSales = total.first["total"] == null
          ? 0
          : (total.first["total"] as num).toDouble();

      totalBills = data.length;

      startDate = null;
      endDate = null;

      filterTitle = "All Sales";
    });
  }

  /// ================= GET ITEMS =================
  Future<String> getItems(int invoiceId) async {
    final db = await DatabaseHelper.instance.database;

    final items = await db.query(
      "invoice_items",
      where: "invoiceId = ?",
      whereArgs: [invoiceId],
    );

    if (items.isEmpty) return "";

    return items.map((e) => e["itemName"]).join("\n");
  }

  /// ================= SEARCH =================
  Future<void> searchSales(String value) async {
    final db = await DatabaseHelper.instance.database;

    if (value.isEmpty) {
      loadSales();
      return;
    }

    final data = await db.query(
      "invoices",
      where:
          "paymentStatus = 'Paid' AND (invoiceNo LIKE ? OR receiverName LIKE ?)",
      whereArgs: ["%$value%", "%$value%"],
      orderBy: "id DESC",
    );

    updateList(data);
  }

  /// ================= WEEKLY =================
  Future<void> loadWeekly() async {
    final db = await DatabaseHelper.instance.database;

    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    DateTime sunday = monday.add(const Duration(days: 6));

    final data = await db.rawQuery(
      """
SELECT * FROM invoices
WHERE paymentStatus='Paid'
AND date(invoiceDate) BETWEEN date(?) AND date(?)
ORDER BY id DESC
""",
      [monday.toIso8601String(), sunday.toIso8601String()],
    );

    startDate = monday;
    endDate = sunday;

    filterTitle = "Current Week";

    updateList(data);
  }

  /// ================= MONTHLY =================
  Future<void> loadMonthly() async {
    final db = await DatabaseHelper.instance.database;

    DateTime now = DateTime.now();

    DateTime firstDay = DateTime(now.year, now.month, 1);
    DateTime lastDay = DateTime(now.year, now.month + 1, 0);

    final data = await db.rawQuery(
      """
SELECT * FROM invoices
WHERE paymentStatus='Paid'
AND date(invoiceDate) BETWEEN date(?) AND date(?)
ORDER BY id DESC
""",
      [firstDay.toIso8601String(), lastDay.toIso8601String()],
    );

    startDate = firstDay;
    endDate = lastDay;

    filterTitle = "Current Month";

    updateList(data);
  }

  /// ================= YEARLY =================
  Future<void> loadYearly() async {
    final db = await DatabaseHelper.instance.database;

    DateTime now = DateTime.now();

    DateTime firstDay = DateTime(now.year, 1, 1);
    DateTime lastDay = DateTime(now.year, 12, 31);

    final data = await db.rawQuery(
      """
SELECT * FROM invoices
WHERE paymentStatus='Paid'
AND date(invoiceDate) BETWEEN date(?) AND date(?)
ORDER BY id DESC
""",
      [firstDay.toIso8601String(), lastDay.toIso8601String()],
    );

    startDate = firstDay;
    endDate = lastDay;

    filterTitle = "Current Year";

    updateList(data);
  }

  /// ================= CUSTOM =================
  Future<void> loadCustom() async {
    if (startDate == null || endDate == null) return;

    final db = await DatabaseHelper.instance.database;

    final data = await db.rawQuery(
      """
SELECT * FROM invoices
WHERE paymentStatus='Paid'
AND date(invoiceDate) BETWEEN date(?) AND date(?)
ORDER BY id DESC
""",
      [startDate!.toIso8601String(), endDate!.toIso8601String()],
    );

    filterTitle = "Custom Range";

    updateList(data);
  }

  /// ================= UPDATE LIST =================
  void updateList(List<Map<String, dynamic>> data) {
    double total = 0;

    for (var i in data) {
      total += (i["netTotal"] as num).toDouble();
    }

    setState(() {
      salesList = data;
      totalSales = total;
      totalBills = data.length;
    });
  }

  /// ================= DATE PICKERS =================
  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      helpText: "Select Start Date",
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        startDate = picked;
      });
    }
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      helpText: "Select End Date",
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        endDate = picked;
      });
    }
  }

  /// ================= CLEAR FILTER =================
  void clearFilter() {
    startDate = null;
    endDate = null;

    loadSales();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales Report")),

      body: Column(
        children: [

          /// TOTAL SALES
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Total Sales : ₹ $totalSales",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              onChanged: searchSales,
              decoration: const InputDecoration(
                hintText: "Search Invoice / Customer",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loadWeekly,
                    child: const Text("Weekly"),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loadMonthly,
                    child: const Text("Monthly"),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: loadYearly,
                    child: const Text("Yearly"),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await pickStartDate();
                      await pickEndDate();
                      loadCustom();
                    },
                    child: const Text("Custom"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// SALES LIST
          Expanded(
            child: ListView.builder(
              itemCount: salesList.length,
              itemBuilder: (context, index) {

                final inv = salesList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      "${index + 1}. ${inv['receiverName'] ?? ""}",
                    ),
                    subtitle: Text(
                      "Invoice: ${inv['invoiceNo']} | ${formatDate(inv['invoiceDate'])}",
                    ),
                    trailing: Text(
                      "₹ ${inv['netTotal']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}