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
  List<double> payments = [];

  double totalPending = 0;

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPending();
  }

  void showPaymentPopup(Map<String, dynamic> bill) async {
    TextEditingController amountController = TextEditingController();

    final db = await DatabaseHelper.instance.database;

    List<Map<String, dynamic>> payments = await db.query(
      'payments',
      where: 'invoiceId = ?',
      whereArgs: [bill['id']],
    );

    double total = ((bill['netTotal'] as num?) ?? 0).toDouble();
    double previousPaid = ((bill['paidAmount'] as num?) ?? 0).toDouble();

    bool hasPartial = previousPaid > 0;

    bool isFullPayment = !hasPartial;

    String errorText = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double remaining = total - previousPaid;

            double totalPaidFromList = payments.fold(
              0,
              (sum, e) => sum + ((e['amount'] as num?) ?? 0),
            );

            String paidBreakdown = payments.isEmpty
                ? "₹ 0"
                : payments
                          .map(
                            (e) =>
                                "₹${(e['amount'] as num).toStringAsFixed(0)}",
                          )
                          .join(" + ") +
                      " = ₹${totalPaidFromList.toStringAsFixed(0)}";

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
                        /// TOGGLE
                        if (!hasPartial)
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 140,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: paidBreakdown.isEmpty
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ).withOpacity(0.5),
                                          blurRadius: 8,
                                          // offset: const Offset(0, 3),
                                        ),
                                      ],
                              ),
                              child: Stack(
                                children: [
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            setState(() {
                                              isFullPayment = true;
                                            });
                                          },
                                          child: Container(
                                            height: double.infinity,
                                            alignment: Alignment.center,
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

                                      Expanded(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            setState(() {
                                              isFullPayment = false;
                                            });
                                          },
                                          child: Container(
                                            height: double.infinity,
                                            alignment: Alignment.center,
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
                        const SizedBox(height: 15),

                        /// TITLE
                        Text(
                          isFullPayment ? "Confirm Payment" : "Partial Payment",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// AMOUNTS
                        Column(
                          children: [
                            Text("Bill Amount: ₹ $total"),
                            if (previousPaid > 0)
                              Text(
                                "Paid: $paidBreakdown",
                                style: const TextStyle(color: Colors.green),
                              ),
                            if (previousPaid > 0)
                              Text(
                                "Remaining: ₹ $remaining",
                                style: const TextStyle(color: Colors.red),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// INPUT
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.currency_rupee),
                            hintText: isFullPayment
                                ? "Enter Full Amount"
                                : "Enter Paid Amount",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        if (errorText.isNotEmpty)
                          Text(
                            errorText,
                            style: const TextStyle(color: Colors.red),
                          ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),

                            ElevatedButton(
                              onPressed: () async {
                                double entered =
                                    double.tryParse(
                                      amountController.text.trim(),
                                    ) ??
                                    0;

                                if (entered <= 0) {
                                  setState(() {
                                    errorText = "Enter valid amount";
                                  });
                                  return;
                                }

                                if (entered > 0) {
                                  double newPaid = previousPaid + entered;

                                  if (newPaid > total) {
                                    setState(() {
                                      errorText = "Amount exceeds total";
                                    });
                                    return;
                                  }

                                  await db.insert('payments', {
                                    'invoiceId': bill['id'],
                                    'amount': entered,
                                  });

                                  double newDue = total - newPaid;

                                  await db.update(
                                    'invoices',
                                    {
                                      'paidAmount': newPaid,
                                      'dueAmount': newDue,
                                      'paymentStatus': newDue == 0
                                          ? 'Payment Received'
                                          : (newPaid == 0
                                                ? 'Pending'
                                                : 'Partial'),
                                    },
                                    where: 'id = ?',
                                    whereArgs: [bill['id']],
                                  );
                                }

                                Navigator.pop(context);
                                await loadPending();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFullPayment
                                    ? Colors.green
                                    : Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
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
      where: "paymentStatus != ?",
      whereArgs: ["Payment Received"],
      orderBy: 'id DESC',
    );

    double totalPendingCalc = 0;

    for (var bill in data) {
      double billTotal = ((bill['netTotal'] as num?) ?? 0).toDouble();
      double paid = ((bill['paidAmount'] as num?) ?? 0).toDouble();

      double due = billTotal - paid;

      if (due > 0) {
        totalPendingCalc += due;
      }
    }

    setState(() {
      pendingList = data;
      filteredList = data;
      totalPending = totalPendingCalc;
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
                      double paid = ((bill['paidAmount'] as num?) ?? 0)
                          .toDouble();

                      double total = ((bill['netTotal'] as num?) ?? 0)
                          .toDouble();

                      double remaining = total - paid;

                      bool isPartial = paid > 0 && remaining > 0;

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
                                      color: isPartial
                                          ? Colors.orange
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          isPartial
                                              ? "Partial Payment Received"
                                              : "Payment Received",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
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
