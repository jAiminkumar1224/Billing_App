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

    final data = await db.query('invoices', orderBy: 'invoiceDate DESC');

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

  /// SECTION FILTER
  List<Map<String, dynamic>> getSection(String type) {
    DateTime now = DateTime.now();

    return filteredList.where((inv) {
      DateTime d = parseDate(inv['invoiceDate']);

      if (type == "today") {
        return d.day == now.day && d.month == now.month && d.year == now.year;
      } else if (type == "week") {
        DateTime start = now.subtract(Duration(days: now.weekday - 1));
        DateTime end = start.add(const Duration(days: 6));
        return d.isAfter(start.subtract(const Duration(days: 1))) &&
            d.isBefore(end.add(const Duration(days: 1)));
      } else {
        return true;
      }
    }).toList();
  }

  /// GRID CARD
  Widget invoiceCard(Map<String, dynamic> inv) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InvoicePreviewScreen(invoice: inv)),
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
                color: inv['paymentStatus'] == "Paid"
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
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
            // 👉 1 cm ≈ 37.8 px (approx)
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
                childAspectRatio: 1, // perfect square 🔥
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
    final today = getSection("today");
    final week = getSection("week");
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
                filterButton("Paid"),
                filterButton("Pending"),
              ],
            ),

            const SizedBox(height: 10),

            /// SECTIONS
            buildSection("Today", today),
            buildSection("This Week", week),
            buildSection("All", all),
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

/// ================= PREVIEW SCREEN =================

class InvoicePreviewScreen extends StatelessWidget {
  final Map<String, dynamic> invoice;

  const InvoicePreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Invoice Preview")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Invoice No: ${invoice['invoiceNo']}"),
            Text("Customer: ${invoice['receiverName']}"),
            Text("Date: ${invoice['invoiceDate']}"),

            const SizedBox(height: 20),

            Text(
              "Total: ₹ ${invoice['netTotal']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const Spacer(),

            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("Download PDF"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: () {}, child: const Text("Print")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
