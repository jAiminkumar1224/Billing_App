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

  void showPaymentPopup(Map<String, dynamic> bill) {
    TextEditingController amountController = TextEditingController();
    String errorText = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payment,
                            color: Colors.green,
                            size: 30,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Title
                        const Text(
                          "Confirm Payment",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Bill Amount
                        Text(
                          "Bill Amount: ₹ ${bill['netTotal']}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Input Field
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.currency_rupee),
                            hintText: "Enter Received Amount",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Error Message
                        if (errorText.isNotEmpty)
                          Text(
                            errorText,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),

                        const SizedBox(height: 25),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                            ),

                            ElevatedButton.icon(
                              onPressed: () async {
                                double entered =
                                    double.tryParse(amountController.text) ?? 0;

                                double actual =
                                    ((bill['netTotal'] as num?) ?? 0)
                                        .toDouble();

                                if (entered == actual) {
                                  Navigator.pop(context);
                                  await markAsPaid(bill['id']);
                                } else {
                                  setState(() {
                                    errorText =
                                        "Amount does not match bill amount!";
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.check,color: Colors.white,),
                              label: const Text(
                                "Confirm",
                                style: TextStyle(fontSize: 15,color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// LOAD ALL PENDING BILLS
  Future<void> loadPending() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.query(
      'invoices',
      where: "paymentStatus = ?",
      whereArgs: ["Pending"],
      orderBy: 'id DESC',
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
    final results = pendingList.where((bill) {
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
      {'paymentStatus': 'Payment Received'},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (updated > 0) {
      await loadPending();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bill moved to Sales")));
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
                                  style: const TextStyle(color: Colors.black54),
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
                                  onTap: () => showPaymentPopup(bill),
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
                                      "Payment Received",
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
