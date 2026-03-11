import 'package:flutter/material.dart';
import '../../database/database_helper.dart';

class AllInvoices extends StatefulWidget {
  const AllInvoices({super.key});

  @override
  State<AllInvoices> createState() => _AllInvoicesState();
}

class _AllInvoicesState extends State<AllInvoices> {

  List<Map<String, dynamic>> invoiceList = [];

  @override
  void initState() {
    super.initState();
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.query(
      'invoices',
      orderBy: 'invoiceDate DESC',
    );

    setState(() {
      invoiceList = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Invoices"),
      ),
      body: ListView.builder(
        itemCount: invoiceList.length,
        itemBuilder: (context, index) {

          final inv = invoiceList[index];

          return ListTile(
            title: Text(inv['receiverName'] ?? ""),
            subtitle: Text(
                "Invoice: ${inv['invoiceNo']}  |  ${inv['invoiceDate']}"),
            trailing: Text("₹ ${inv['netTotal']}"),
          );
        },
      ),
    );
  }
}