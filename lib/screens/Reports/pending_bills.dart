import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class PendingBills extends StatefulWidget {
  const PendingBills({super.key});

  @override
  State<PendingBills> createState() => _PendingBillsState();
}

class _PendingBillsState extends State<PendingBills> {
  List<Map<String, dynamic>> pendingList = [];
  List<Map<String, dynamic>> filteredList = [];

  double totalPending = 0;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPending();
  }

  /// LOAD ALL PENDING BILLS
  Future<void> loadPending() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.query(
      'invoices',
      where: "paymentStatus = ?",
      whereArgs: ["Pending"],
      orderBy: 'invoiceDate DESC',
    );

    double total = 0;
    for (var bill in data) {
      total += ((bill['netTotal'] as num?) ?? 0).toDouble();
    }

    setState(() {
      pendingList = data;
      filteredList = data;
      totalPending = total;
    });
  }

  /// SEARCH FUNCTION
  void filterSearch(String value) {
    final results =
        pendingList.where((bill) {
          final name = (bill['receiverName'] ?? "").toString().toLowerCase();
          final invoice = (bill['invoiceNo'] ?? "").toString().toLowerCase();

          return name.contains(value.toLowerCase()) ||
              invoice.contains(value.toLowerCase());
        }).toList();

    setState(() {
      filteredList = results;
    });
  }

  /// MARK BILL AS PAID
  Future<void> markAsPaid(int id) async {
    final db = await DatabaseHelper.instance.database;

    int updated = await db.update(
      'invoices',
      {'paymentStatus': 'Paid'},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (updated > 0) {
      await loadPending();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bill moved to Sales")),
      );
    }
  }

  String formatDate(String? date) {
    if (date == null) return "";
    DateTime dt = DateTime.parse(date);
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Bills")),

      body: Column(
        children: [
          /// 🔹 TOP CARD (TOTAL PENDING)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Pending",
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  "₹ ${totalPending.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text("${pendingList.length} Bills"),
              ],
            ),
          ),

          /// 🔹 SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: searchController,
              onChanged: filterSearch,
              decoration: InputDecoration(
                hintText: "Search Invoice / Customer",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// 🔹 LIST
          Expanded(
            child: filteredList.isEmpty
                ? const Center(child: Text("No Pending Bills"))
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final bill = filteredList[index];

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// LEFT SIDE
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bill['receiverName'] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Invoice: ${bill['invoiceNo']} | ${formatDate(bill['invoiceDate'])}",
                                  style: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),

                            /// RIGHT SIDE
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹ ${bill['netTotal']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                GestureDetector(
                                  onTap: () => markAsPaid(bill['id']),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "Paid",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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