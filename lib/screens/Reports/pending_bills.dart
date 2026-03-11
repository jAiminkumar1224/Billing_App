import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class PendingBills extends StatefulWidget {
  const PendingBills({super.key});

  @override
  State<PendingBills> createState() => _PendingBillsState();
}

class _PendingBillsState extends State<PendingBills> {
  List<Map<String, dynamic>> pendingList = [];

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

    setState(() {
      pendingList = data;
    });
  }

  /// MARK BILL AS PAID
  Future<void> markAsPaid(int id) async {
    final db = await DatabaseHelper.instance.database;

    /// UPDATE ONLY (NO INSERT)
    int updated = await db.update(
      'invoices',
      {'paymentStatus': 'Paid'},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (updated > 0) {
      /// REMOVE FROM LIST UI
      setState(() {
        //pendingList.removeWhere((bill) => bill['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bill moved to Sales")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Bills"),
      ),

      body: pendingList.isEmpty
          ? const Center(
              child: Text(
                "No Pending Bills",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final bill = pendingList[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      bill['receiverName'] ?? "",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),

                    subtitle: Text(
                      "Invoice ${bill['invoiceNo']}",
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// AMOUNT
                        Text(
                          "₹ ${bill['netTotal']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// PAID BUTTON
                        ElevatedButton(
                          onPressed: () {
                            markAsPaid(bill['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: const Text("Paid"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}