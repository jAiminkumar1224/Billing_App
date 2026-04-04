import 'package:billing_app/models/invoice_model.dart';
import 'package:billing_app/screens/bill_screen.dart';
import 'package:billing_app/services/pdf_service.dart';
import 'package:billing_app/services/print_bill.dart';
import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class AllInvoices extends StatefulWidget {
  const AllInvoices({super.key});

  @override
  State<AllInvoices> createState() => _AllInvoicesState();
}

class _AllInvoicesState extends State<AllInvoices> {
  List<Map<String, dynamic>> invoiceList = [];
  List<Map<String, dynamic>> filteredList = [];

  String searchText = "";
  String statusFilter = "All";

  @override
  void initState() {
    super.initState();
    loadInvoices();
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

  DateTime parseDate(dynamic date) {
    if (date is int) {
      return DateTime.fromMillisecondsSinceEpoch(date);
    } else {
      return DateTime.parse(date.toString());
    }
  }

  Future<void> loadInvoices() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.query('invoices', orderBy: 'id DESC');

    setState(() {
      invoiceList = data;
      filteredList = data;
    });
  }

  /// SEARCH + FILTER
  void applyFilter() {
    List<Map<String, dynamic>> temp = invoiceList;

    if (searchText.isNotEmpty) {
      temp = temp.where((inv) {
        return inv['invoiceNo'].toString().contains(searchText) ||
            (inv['receiverName'] ?? "").toString().toLowerCase().contains(
              searchText.toLowerCase(),
            );
      }).toList();
    }
    if (statusFilter != "All") {
      temp = temp.where((inv) => inv['paymentStatus'] == statusFilter).toList();
    }

    setState(() {
      filteredList = temp;
    });
  }

  /// GRID CARD
  Widget invoiceCard(Map<String, dynamic> inv) {
    bool isPaid = inv['paymentStatus'] == "Payment Received";
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                /// 🔵 HEADER (SMART)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inv['receiverName'] ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              const Text(
                                "Invoice",
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "INV-${inv['invoiceNo']}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                "Total",
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "₹ ${inv['netTotal']}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                "Status",
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                inv['paymentStatus'],
                                style: TextStyle(
                                  color:
                                      inv['paymentStatus'] == "Payment Received"
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "Date: ${formatDate(inv['invoiceDate'])}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                /// 📄 BODY
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Items",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Expanded(
                          child: FutureBuilder(
                            future: DatabaseHelper.instance.database.then((db) {
                              return db.query(
                                'invoice_items',
                                where: 'invoiceId = ?',
                                whereArgs: [inv['id']],
                              );
                            }),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final items =
                                  snapshot.data as List<Map<String, dynamic>>;

                              return ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (_, i) {
                                  final item = items[i];

                                  return Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListTile(
                                      title: Text(item['itemName']),
                                      subtitle: Text("Qty: ${item['qty']}"),
                                      trailing: Text("₹ ${item['amount']}"),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// 🔘 BUTTONS
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      actionBtn("Edit Bill", Icons.edit, () async {
                        Navigator.pop(context);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillScreen(
                              invoice: InvoiceModel(
                                id: inv['id'],
                                invoiceNo: inv['invoiceNo'],
                                invoiceDate: inv['invoiceDate'],
                                state: inv['state'],
                                stateCode: inv['stateCode'],
                                receiverName: inv['receiverName'],
                                receiverAddress: inv['receiverAddress'],
                                receiverGstin: inv['receiverGstin'],
                                receiverState: inv['receiverState'],
                                receiverStateCode:
                                    inv['receiverStateCode'] ?? '',
                                poNumber: inv['poNumber'],
                                poDate: inv['poDate'],
                                subtotal: inv['subtotal'],
                                discount: inv['discount'],
                                netTotal: inv['netTotal'],
                                paymentStatus: inv['paymentStatus'],
                                contactNumber: inv['contactNumber'] ?? '',
                                whatsappNumber: inv['whatsappNumber'] ?? '',
                                email: inv['email'] ?? '',
                              ),
                            ),
                          ),
                        );

                        if (result == true) loadInvoices();
                      }, isEnabled: !isPaid),

                      actionBtn("Download PDF", Icons.picture_as_pdf, () async {
                        final db = await DatabaseHelper.instance.database;

                        final itemsData = await db.query(
                          'invoice_items',
                          where: 'invoiceId = ?',
                          whereArgs: [inv['id']],
                        );

                        await PdfService().downloadBill(
                          invoiceNo: inv['invoiceNo'].toString(),
                          invoiceDate: parseDate(inv['invoiceDate']),
                          state: inv['state'],
                          stateCode: inv['stateCode'],
                          receiverStateCode: inv['receiverStateCode'],
                          receiverState: inv['receiverState'],
                          receiverName: inv['receiverName'],
                          receiverAddress: inv['receiverAddress'],
                          receiverGstin: inv['receiverGstin'],
                          poNumber: inv['poNumber'],
                          poDate: parseDate(inv['poDate']),
                          items: itemsData,
                          subTotal: inv['subtotal'],
                          discountAmount: inv['discount'],
                          netTotal: inv['netTotal'],
                          discountPercentText: "0",
                        );
                      }),

                      actionBtn("Print Bill", Icons.print, () {
                        printInvoiceFromDb(inv);
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "INV-${inv['invoiceNo']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(inv['receiverName'] ?? ""),

            const Spacer(),

            Text(formatDate(inv['invoiceDate'])),

            const SizedBox(height: 5),

            Text(
              "₹ ${inv['netTotal']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              inv['paymentStatus'] ?? "",
              style: TextStyle(
                color: inv['paymentStatus'] == "Payment Received"
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget actionBtn(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isEnabled = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: isEnabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEnabled
                  ? Colors.blue.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isEnabled ? Colors.blue : Colors.grey,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isEnabled ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  /// GRID SECTION
  Widget buildSection(String title, List<Map<String, dynamic>> list) {
    if (list.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        LayoutBuilder(
          builder: (context, constraints) {
            double boxSize = 5 * 37.8; // 5 cm

            int crossAxisCount = (constraints.maxWidth / boxSize).floor().clamp(
              1,
              10,
            );

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                return invoiceCard(list[index]);
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = filteredList;

    return Scaffold(
      appBar: AppBar(title: const Text("Invoices")),

      body: SingleChildScrollView(
        child: Column(
          children: [
            /// SEARCH
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Search Invoice / Customer",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  searchText = val;
                  applyFilter();
                },
              ),
            ),

            /// FILTER
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                filterButton("All"),
                filterButton("Payment Received"),
                filterButton("Pending"),
              ],
            ),

            const SizedBox(height: 10),
            buildSection(
              statusFilter == "All" ? "All Invoices" : statusFilter,
              all,
            ),
          ],
        ),
      ),
    );
  }

  Widget filterButton(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        onPressed: () {
          statusFilter = text;
          applyFilter();
        },
        child: Text(text),
      ),
    );
  }
}
