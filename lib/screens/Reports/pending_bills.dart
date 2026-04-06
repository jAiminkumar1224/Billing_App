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

    bool isFullPayment = true; // toggle state
    String errorText = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double total = ((bill['netTotal'] as num?) ?? 0).toDouble();
            double entered = double.tryParse(amountController.text) ?? 0;

            double dueAmount = total - entered;

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
                        ///   TOGGLE BUTTON
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            width: 140,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Stack(
                              children: [
                                ///    SLIDER
                                AnimatedAlign(
                                  duration: const Duration(milliseconds: 250),
                                  alignment: isFullPayment
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  child: Container(
                                    width: 70,
                                    margin: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: isFullPayment
                                          ? Colors.green
                                          : Colors.orange,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),

                                ///    BUTTONS
                                Row(
                                  children: [
                                    /// FULL PAYMENT
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isFullPayment = true;
                                            amountController.clear();
                                            errorText = "";
                                          });
                                        },
                                        child: Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 18,
                                            color: isFullPayment
                                                ? Colors.white
                                                : Colors.green,
                                          ),
                                        ),
                                      ),
                                    ),

                                    /// PARTIAL PAYMENT
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            isFullPayment = false;
                                            amountController.clear();
                                            errorText = "";
                                          });
                                        },
                                        child: Center(
                                          child: Icon(
                                            Icons.percent,
                                            size: 18,
                                            color: !isFullPayment
                                                ? Colors.white
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        ///   ICON
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isFullPayment
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFullPayment
                                ? Icons.payment
                                : Icons.account_balance_wallet,
                            color: isFullPayment ? Colors.green : Colors.orange,
                            size: 30,
                          ),
                        ),

                        const SizedBox(height: 15),

                        ///   TITLE
                        Text(
                          isFullPayment ? "Confirm Payment" : "Partial Payment",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        ///   BILL AMOUNT
                        Text(
                          "Bill Amount: ₹ $total",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ///   INPUT
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.currency_rupee),
                            hintText: isFullPayment
                                ? "Enter Full Amount"
                                : "Enter Paid Amount",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        ///   PARTIAL INFO
                        if (!isFullPayment)
                          Column(
                            children: [
                              Text(
                                "Due Amount: ₹ ${dueAmount.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),

                        ///   ERROR
                        if (errorText.isNotEmpty)
                          Text(
                            errorText,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),

                        const SizedBox(height: 25),

                        ///   BUTTONS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),

                            ElevatedButton.icon(
                              onPressed: () async {
                                if (isFullPayment) {
                                  if (entered == total) {
                                    Navigator.pop(context);
                                    await markAsPaid(bill['id']);
                                  } else {
                                    setState(() {
                                      errorText = "Enter full amount!";
                                    });
                                  }
                                } else {
                                  if (entered > 0 && entered < total) {
                                    Navigator.pop(context);

                                    // TODO: Save partial payment in DB
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Partial Payment Saved"),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      errorText = "Invalid partial amount!";
                                    });
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFullPayment
                                    ? Colors.green
                                    : Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                              label: Text(
                                isFullPayment ? "Confirm" : "Partial Pay",
                                style: const TextStyle(color: Colors.white),
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
          ///   TOP CARD (TOTAL PENDING)
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

          ///   SEARCH BAR
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

          ///   LIST
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
