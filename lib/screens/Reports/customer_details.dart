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

  String selectedView = "List";

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

  // 📞 CALL POPUP
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

  // 💬 WHATSAPP POPUP
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

  // ➕ CREATE INVOICE (PREFILL)
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
          customerData: customer, // 👉 PREFILL DATA
          invoiceNo: nextInvoice.toString(),
        ),
      ),
    );
  }

  // 📊 CUSTOMER BIG POPUP
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
            // 🔝 HEADER
            Text(
              cust['receiverName'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // 📊 SUMMARY
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

            // 📄 LEFT → INVOICES LIST
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

            // ⚡ ACTIONS
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
                  child: const Text("Create Invoice"),
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
          //  SEARCH
          Row(
            children: [
              Expanded(
                child: Padding(
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
              ),

              // 📂 VIEW DROPDOWN
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: selectedView,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.view_module),
                    items: const [
                      DropdownMenuItem(value: "Small", child: Text("Small")),
                      DropdownMenuItem(value: "Medium", child: Text("Medium")),
                      DropdownMenuItem(value: "Large", child: Text("Large")),
                      DropdownMenuItem(value: "List", child: Text("List")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedView = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),

          // 👥 LIST
          Expanded(
            child: selectedView == "List"
                ? ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final cust = filteredCustomers[index];

                      return Card(
                        child: ListTile(
                          onTap: () => showCustomerPopup(cust),
                          title: Text(
                            cust['receiverName'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Pending: ₹ ${cust['totalPending'] ?? 0}",
                          ),
                          trailing: Text(
                            "₹ ${cust['totalSpent'] ?? 0}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: selectedView == "Small"
                          ? 5
                          : selectedView == "Medium"
                          ? 3
                          : 2,
                      childAspectRatio: 1,
                    ),
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final cust = filteredCustomers[index];

                      return GestureDetector(
                        onTap: () => showCustomerPopup(cust),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  cust['receiverName'],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text("₹ ${cust['totalSpent'] ?? 0}"),
                                Text(
                                  "Pending: ₹ ${cust['totalPending'] ?? 0}",
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
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
