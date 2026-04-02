import 'package:billing_app/screens/bill_screen.dart';
import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class CustomerDetails extends StatefulWidget {
  const CustomerDetails({super.key});

  @override
  State<CustomerDetails> createState() => _CustomerDetailsState();
}

class _CustomerDetailsState extends State<CustomerDetails> {
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> filteredCustomers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.rawQuery('''
      SELECT receiverName,
      COUNT(*) as totalInvoices,
      SUM(netTotal) as totalSpent,
      0 as totalPending,
      MAX(invoiceDate) as lastDate
      FROM invoices
      GROUP BY receiverName
      ORDER BY totalSpent DESC
    ''');

    setState(() {
      customers = data;
      filteredCustomers = data;
    });
  }

  void searchCustomer(String query) {
    final result = customers.where((cust) {
      final name = cust['receiverName'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredCustomers = result;
    });
  }

  void showCallPopup(String phone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Call Customer"),
        content: Text("Phone: $phone"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void showWhatsAppPopup(String phone) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("WhatsApp Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Number: $phone"),
            const SizedBox(height: 10),
            const TextField(
              decoration: InputDecoration(
                hintText: "Type Message...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }

  void createInvoice(Map<String, dynamic> customer) async {
    final db = await DatabaseHelper.instance.database;

    final lastInvoice = await db.rawQuery('''
      SELECT invoiceNo FROM invoices ORDER BY id DESC LIMIT 1
    ''');

    int nextInvoice = 1;

    if (lastInvoice.isNotEmpty) {
      nextInvoice = int.parse(lastInvoice.first['invoiceNo'].toString()) + 1;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillScreen(
          customerData: customer,
          invoiceNo: nextInvoice.toString(),
        ),
      ),
    );
  }

  void showCustomerPopup(Map<String, dynamic> cust) async {
    final db = await DatabaseHelper.instance.database;

    final invoices = await db.rawQuery(
      '''
      SELECT * FROM invoices WHERE receiverName = ?
    ''',
      [cust['receiverName']],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              cust['receiverName'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text("Total"),
                    Text(
                      "₹ ${cust['totalSpent'] ?? 0}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("Pending"),
                    Text(
                      "₹ ${cust['totalPending'] ?? 0}",
                      style: const TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Text("Last Purchase: ${cust['lastDate'] ?? '-'}"),

            const Divider(),

            Expanded(
              child: ListView.builder(
                itemCount: invoices.length,
                itemBuilder: (_, i) {
                  final inv = invoices[i];

                  return ListTile(
                    title: Text("Invoice: ${inv['invoiceNo']}"),
                    subtitle: Text("₹ ${inv['netTotal']}"),
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => showCallPopup(cust['receiverPhone']),
                  child: const Text("Call"),
                ),
                ElevatedButton(
                  onPressed: () => showWhatsAppPopup(cust['receiverPhone']),
                  child: const Text("WhatsApp"),
                ),
                ElevatedButton(
                  onPressed: () => createInvoice(cust),
                  child: const Text("Email"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customers")),

      body: Column(
        children: [
          // SEARCH ONLY (dropdown removed)
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: searchController,
              onChanged: searchCustomer,
              decoration: InputDecoration(
                hintText: "Search Customer",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          //  INVOICE STYLE GRID
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                double boxSize = 5 * 37.8; // 👉 same as invoice (5cm)

                int crossAxisCount = (constraints.maxWidth / boxSize)
                    .floor()
                    .clamp(1, 10);

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: filteredCustomers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.90, //  perfect square
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final cust = filteredCustomers[index];

                    return GestureDetector(
                      onTap: () => showCustomerPopup(cust),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic Customer ID and Name karvanu che
                            const Text(
                              "CUST-001",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              cust['receiverName'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.pink,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    "Pune, Maharashtra (27)", //  later dynamic karvanu che
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            // Phone
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Colors.pink,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  "9876543210", //  dynamic karvanu che
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "GSTIN: 27ABCDE1234F1Z5",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 3),

                            const Spacer(),

                            Row(
                              children: [
                                const Text(
                                  "Total",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "₹ ${cust['totalSpent'] ?? 0}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Row(
                              children: [
                                const Text(
                                  "Pending",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "₹ ${cust['totalPending'] ?? 0}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
