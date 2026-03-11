import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class CustomerDetails extends StatefulWidget {
  const CustomerDetails({super.key});

  @override
  State<CustomerDetails> createState() => _CustomerDetailsState();
}

class _CustomerDetailsState extends State<CustomerDetails> {

  List<Map<String, dynamic>> customers = [];

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  Future<void> loadCustomers() async {

    final db = await DatabaseHelper.instance.database;

    final data = await db.rawQuery('''
      SELECT receiverName, COUNT(*) as totalInvoices, SUM(netTotal) as totalSpent
      FROM invoices
      GROUP BY receiverName
      ORDER BY totalSpent DESC
    ''');

    setState(() {
      customers = data;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Details"),
      ),
      body: ListView.builder(
        itemCount: customers.length,
        itemBuilder: (context, index) {

          final cust = customers[index];

          return ListTile(
            title: Text(cust['receiverName']),
            subtitle: Text("Invoices: ${cust['totalInvoices']}"),
            trailing: Text("₹ ${cust['totalSpent']}"),
          );
        },
      ),
    );
  }
}