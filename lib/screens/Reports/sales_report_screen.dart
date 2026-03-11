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

  bool isFilterActive = false;
  String filterTitle = "Total Sales";

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  /// DATE FORMAT
  String formatDate(String date) {
    DateTime d = DateTime.parse(date);

    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  /// LOAD SALES
  Future<void> loadSales() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.query(
      'invoices',
      where: "paymentStatus = ?",
      whereArgs: ["Paid"],
      orderBy: "id DESC",
    );

    updateList(data);

    setState(() {
      isFilterActive = false;
      filterTitle = "All Sales";
      startDate = null;
      endDate = null;
    });
  }

  /// UPDATE LIST
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

  /// SEARCH
  Future<void> searchSales(String value) async {
    final db = await DatabaseHelper.instance.database;

    if (value.isEmpty) {
      loadSales();
      return;
    }

    final data = await db.query(
      "invoices",
      where:
          "paymentStatus='Paid' AND (invoiceNo LIKE ? OR receiverName LIKE ?)",
      whereArgs: ["%$value%", "%$value%"],
      orderBy: "id DESC",
    );

    updateList(data);
  }

  /// WEEKLY
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

    setState(() {
      startDate = monday;
      endDate = sunday;
      filterTitle = "This Week’s Sales";
      isFilterActive = true;
    });

    updateList(data);
  }

  /// MONTHLY
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

    setState(() {
      startDate = firstDay;
      endDate = lastDay;
      filterTitle = "This Month’s Sales";
      isFilterActive = true;
    });

    updateList(data);
  }

  /// YEARLY
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

    setState(() {
      startDate = firstDay;
      endDate = lastDay;
      filterTitle = "This Year’s Sales";
      isFilterActive = true;
    });

    updateList(data);
  }

  /// CUSTOM DATE RANGE
  /// CUSTOM DATE RANGE POPUP
  Future<void> openDateRangePopup() async {
    DateTime? tempStart = startDate;
    DateTime? tempEnd = endDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(12),

          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 400,
                height: 420,

                child: Column(
                  children: [
                    /// HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Range",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// SELECTED RANGE TEXT
                    Text(
                      tempStart == null
                          ? "Start Date - End Date"
                          : "${showDate(tempStart!)} → ${tempEnd == null ? '' : showDate(tempEnd!)}",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 15),

                    /// CALENDAR
                    Expanded(
                      child: CalendarDatePicker(
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),

                        onDateChanged: (date) {
                          setStateDialog(() {
                            if (tempStart == null) {
                              tempStart = date;
                            } else if (tempEnd == null) {
                              tempEnd = date;

                              if (tempEnd!.isBefore(tempStart!)) {
                                final t = tempStart;
                                tempStart = tempEnd;
                                tempEnd = t;
                              }
                            } else {
                              tempStart = date;
                              tempEnd = null;
                            }
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// SAVE BUTTON
                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        child: const Text("Save"),

                        onPressed: () async {
                          if (tempStart != null && tempEnd != null) {
                            startDate = tempStart;
                            endDate = tempEnd;

                            final db = await DatabaseHelper.instance.database;

                            final data = await db.rawQuery(
                              """
SELECT * FROM invoices
WHERE paymentStatus='Paid'
AND date(invoiceDate) BETWEEN date(?) AND date(?)
ORDER BY id DESC
""",
                              [
                                startDate!.toIso8601String(),
                                endDate!.toIso8601String(),
                              ],
                            );

                            setState(() {
                              filterTitle = "Sales for Selected Period";
                              isFilterActive = true;
                            });

                            updateList(data);

                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// CLEAR FILTER
  void clearFilter() {
    loadSales();
  }

  /// DATE FORMATTER
  String showDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales Report")),

      body: Column(
        children: [
          /// TOTAL SALES
          /// SALES SUMMARY CARD
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// TITLE
                Text(
                  filterTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                /// SALES AMOUNT
                Text(
                  "₹ ${totalSales.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                /// TOTAL BILLS
                Text(
                  "$totalBills Bills",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          /// FILTER BAR
          if (isFilterActive && startDate != null && endDate != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      "$filterTitle : ${showDate(startDate!)} → ${showDate(endDate!)}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),

                  GestureDetector(
                    onTap: clearFilter,
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),

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
                    onPressed: openDateRangePopup,
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
                    title: Text("${index + 1}. ${inv['receiverName'] ?? ""}"),
                    subtitle: Text(
                      "Invoice: ${inv['invoiceNo']} | ${formatDate(inv['invoiceDate'])}",
                    ),
                    trailing: Text(
                      "₹ ${inv['netTotal']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
