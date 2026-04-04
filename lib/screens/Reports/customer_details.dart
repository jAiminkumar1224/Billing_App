import 'package:billing_app/screens/bill_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
SELECT 
  receiverName,
  MAX(receiverAddress) as receiverAddress,

  MAX(receiverState) as receiverState,
  MAX(receiverStateCode) as receiverStateCode,

  MAX(state) as state,
  MAX(stateCode) as stateCode,
  MAX(contactNumber) as contactNumber,
  MAX(receiverGstin) as receiverGstin,
  MAX(email) as email,
  MAX(whatsappNumber) as whatsappNumber,

  (
    SELECT poNumber 
    FROM invoices i2 
    WHERE i2.receiverName = invoices.receiverName 
    AND poNumber IS NOT NULL 
    AND poNumber != ''
    ORDER BY id DESC 
    LIMIT 1
  ) as poNumber,

  COUNT(*) as totalInvoices,
  SUM(netTotal) as totalSpent,

  SUM(CASE 
      WHEN paymentStatus = 'Pending' 
      THEN netTotal 
      ELSE 0 
  END) as totalPending,

  MAX(invoiceDate) as lastDate

FROM invoices
GROUP BY receiverName
ORDER BY totalSpent DESC''');

    setState(() {
      customers = data;
      filteredCustomers = data;
    });
  }

  String? whatsappNumber;

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
        content: Row(
          children: [
            Icon(Icons.phone, color: Colors.green),
            const SizedBox(width: 10),
            Text(phone),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void showWhatsAppPopup(Map<String, dynamic> cust) {
    String existingNumber = cust['whatsappNumber'] ?? '';

    TextEditingController controller = TextEditingController(
      text: existingNumber,
    );

    bool isNumberSaved = existingNumber.trim().isNotEmpty;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("WhatsApp Customer"),
        content: isNumberSaved
            ? Row(
                children: [
                  const Icon(Icons.message, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      existingNumber,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )
            : TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: "Enter WhatsApp Number",
                  border: OutlineInputBorder(),
                ),
              ),
        actions: isNumberSaved
            ? [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ]
            : [
                TextButton(
                  onPressed: () async {
                    if (controller.text.trim().isEmpty) return;

                    final db = await DatabaseHelper.instance.database;

                    await db.rawUpdate(
                      '''
                    UPDATE invoices 
                    SET whatsappNumber = ? 
                    WHERE receiverName = ?
                    ''',
                      [controller.text.trim(), cust['receiverName']],
                    );

                    Navigator.pop(context);
                    loadCustomers();
                  },
                  child: const Text("Save"),
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

  //    STAT CARD
  Widget _statCard(String title, dynamic value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 5),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              "₹ ${value ?? 0}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //    ACTION BUTTON
  Widget _actionBtn(String title, IconData icon, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(fontSize: 14)),
      ],
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
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    //   HERO HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
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
                            cust['receiverName'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "GSTIN: ${cust['receiverGstin'] ?? '-'}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            cust['contactNumber'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    //   FLOATING CARDS
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            _statCard(
                              "Total",
                              cust['totalSpent'],
                              Colors.black,
                            ),
                            _statCard(
                              "Pending",
                              cust['totalPending'],
                              Colors.red,
                            ),
                            _statCard(
                              "Paid",
                              ((cust['totalSpent'] ?? 0) -
                                  (cust['totalPending'] ?? 0)),
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    //   TABS
                    const TabBar(
                      labelColor: Colors.black,
                      labelStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      tabs: [
                        Tab(text: "Info"),
                        Tab(text: "Invoices"),
                      ],
                    ),

                    Expanded(
                      child: TabBarView(
                        children: [
                          //   INFO TAB
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Address",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "${cust['receiverAddress']}, ${cust['receiverState']} (${cust['receiverStateCode']})",
                                ),
                                const SizedBox(height: 15),

                                const Text(
                                  "Email",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),

                                GestureDetector(
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: cust['email'] ?? ""),
                                    );

                                    setModalState(() => isCopied = true);

                                    Future.delayed(Duration(seconds: 1), () {
                                      if (mounted) {
                                        setModalState(() => isCopied = false);
                                      }
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCopied
                                          ? Colors.green.withOpacity(
                                              0.15,
                                            ) //      highlight color
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cust['email'] ?? "-",
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          isCopied
                                              ? Icons.check
                                              : Icons.copy, //      icon change
                                          size: 18,
                                          color: isCopied
                                              ? const Color.fromARGB(
                                                  255,
                                                  39,
                                                  120,
                                                  201,
                                                )
                                              : Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          //   INVOICE TAB
                          ListView.builder(
                            itemCount: invoices.length,
                            itemBuilder: (_, i) {
                              final inv = invoices[i];

                              return ListTile(
                                title: Text("Invoice #${inv['invoiceNo']}"),
                                subtitle: Text("₹ ${inv['netTotal']}"),
                                trailing: Text(
                                  (inv['paymentStatus'] as String?) ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: inv['paymentStatus'] == "Pending"
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    //   ACTION BUTTONS
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _actionBtn(
                            "Call",
                            Icons.phone,
                            () => showCallPopup(cust['contactNumber']),
                          ),
                          _actionBtn(
                            "WhatsApp",
                            Icons.message,
                            () => showWhatsAppPopup(cust),
                          ),
                          _actionBtn(
                            "New Invoice",
                            Icons.add,
                            () => createInvoice(cust),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool isCopied = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customers")),

      body: Column(
        children: [
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
                double boxSize = 5 * 37.8;

                int crossAxisCount = (constraints.maxWidth / boxSize)
                    .floor()
                    .clamp(1, 10);

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: filteredCustomers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.90,
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
                              color: Colors.grey.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "CUST-${(index + 1).toString().padLeft(3, '0')}",
                              style: const TextStyle(
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
                                    "${cust['receiverAddress']}, ${cust['receiverState']} (${cust['receiverStateCode']})",
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 14,
                                  color: Colors.pink,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cust['contactNumber'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "GSTIN: ${cust['receiverGstin'] ?? ''}",
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
