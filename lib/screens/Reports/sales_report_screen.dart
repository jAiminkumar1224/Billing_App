import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

import 'package:billing_app/services/sales_report_pdf.dart';

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
  String formatDate(dynamic date) {
    DateTime d;

    if (date is int) {
      d = DateTime.fromMillisecondsSinceEpoch(date);
    } else {
      d = DateTime.parse(date.toString());
    }

    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  Future<void> pickDateAndExport({required bool isPDF}) async {
    await openDateRangePopup();

    // user e date select kari hoy to j export karvu
    if (startDate != null && endDate != null) {
      if (isPDF) {
        exportSalesPDF();
      } else {
        exportSalesExcel();
      }
    }
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

  Future<void> openDateRangePopup() async {
    DateTime? tempStart;
    DateTime? tempEnd;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(12),

          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      Row(
                        children: [
                          /// START DATE
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Start Date",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tempStart == null
                                        ? "--/--/----"
                                        : showDate(tempStart!),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// END DATE
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "End Date",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tempEnd == null
                                        ? "--/--/----"
                                        : showDate(tempEnd!),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      /// CALENDAR
                      Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color.fromARGB(
                              255,
                              118,
                              181,
                              237,
                            ), // selected circle color
                            onPrimary: Colors.white, // selected text color
                            onSurface: Colors.black,
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                          splashColor: Colors.blue.withValues(alpha: 0.2),
                          highlightColor: Colors.blue.withValues(alpha: 0.1),

                          primaryColor: Colors.blue,
                        ),
                        child: SizedBox(
                          height: 300,
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
                      ),

                      const SizedBox(height: 10),

                      /// SAVE BUTTON
                      Row(
                        children: [
                          /// RESET BUTTON
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setStateDialog(() {
                                  tempStart = null;
                                  tempEnd = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Reset",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          /// SAVE BUTTON
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: (tempStart != null && tempEnd != null)
                                  ? () async {
                                      startDate = tempStart;
                                      endDate = tempEnd;

                                      final db = await DatabaseHelper
                                          .instance
                                          .database;

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
                                        filterTitle =
                                            "Sales for Selected Period";
                                        isFilterActive = true;
                                      });

                                      updateList(data);
                                      Navigator.pop(context);
                                    }
                                  : null,
                              child: const Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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

  String formatFileDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  /// DATE FORMATTER
  String showDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  void exportSalesPDF() async {
    final itemsList = await DatabaseHelper.instance.getSalesRegisterItems();

    DateTime fromDate;
    DateTime toDate;

    if (isFilterActive && startDate != null && endDate != null) {
      fromDate = startDate!;
      toDate = endDate!;
    } else {
      if (salesList.isNotEmpty) {
        final first = salesList.last['invoiceDate'];
        final last = salesList.first['invoiceDate'];

        fromDate = parseDate(first);
        toDate = parseDate(last);
      } else {
        fromDate = DateTime.now();
        toDate = DateTime.now();
      }
    }

    final pdfFile = await generateSalesReportPDF(
      itemsList,
      fromDate: fromDate,
      toDate: toDate,
    );

/// USER SELECT LOCATION
String fileName;

if (startDate != null && endDate != null) {
  fileName =
      "Sales_Report_${formatFileDate(startDate!)}_to_${formatFileDate(endDate!)}.pdf";
} else {
  fileName = "Sales_Report.pdf";
}

String? outputPath = await FilePicker.platform.saveFile(
  dialogTitle: 'Save PDF',
  fileName: fileName,
);

    if (outputPath != null) {
      final newFile = File(outputPath);
      await newFile.writeAsBytes(await pdfFile.readAsBytes());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("PDF saved at: $outputPath")));
    }
  }

void exportSalesExcel() async {
  String csv = "Date,Invoice,Customer,Amount\n";

  for (var sale in salesList) {
    csv +=
        "${formatDate(sale['invoiceDate'])},"
        "${sale['invoiceNo']},"
        "${sale['receiverName']},"
        "${sale['netTotal']}\n";
  }

  /// USER SELECT LOCATION
  String fileName;

  if (startDate != null && endDate != null) {
    fileName =
        "Sales_Report_${formatFileDate(startDate!)}_to_${formatFileDate(endDate!)}.csv";
  } else {
    fileName = "Sales_Report.csv";
  }

  String? outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save Excel',
    fileName: fileName,
  );

  if (outputPath != null) {
    final file = File(outputPath);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Excel saved at: $outputPath")));
  }
}

  DateTime parseDate(dynamic date) {
    if (date is int) {
      return DateTime.fromMillisecondsSinceEpoch(date);
    } else {
      return DateTime.parse(date.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales Report")),

      body: Column(
        children: [
          /// SALES SUMMARY CARD WITH ACTION PANEL
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

            child: Row(
              children: [
                /// LEFT SIDE (SALES INFO)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filterTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "₹ ${totalSales.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "$totalBills Bills",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                /// RIGHT SIDE ACTION PANEL
                Column(
                  children: [
                    /// EXPORT PDF
                    IconButton(
                      tooltip: "Export as PDF",
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      onPressed: () {
                        pickDateAndExport(isPDF: true);
                      },
                    ),

                    const SizedBox(height: 8),

                    /// EXPORT EXCEL
                    IconButton(
                      tooltip: "Export as Excel",
                      icon: const Icon(Icons.table_chart, color: Colors.green),
                      onPressed: () {
                        pickDateAndExport(isPDF: false);
                      },
                    ),
                  ],
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
                      "Invoice: ${inv['invoiceNo'].toString()} | ${formatDate(inv['invoiceDate'])}",
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
