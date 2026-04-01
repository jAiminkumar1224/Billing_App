import '../database/database_helper.dart';
import '../services/pdf_service.dart';
import '../screens/bill_screen.dart';

Future<void> printInvoiceFromDb(Map<String, dynamic> inv) async {
  final db = await DatabaseHelper.instance.database;

  final itemsData = await db.query(
    'invoice_items',
    where: 'invoiceId = ?',
    whereArgs: [inv['id']],
  );

  List<BillItem> items = itemsData.map((item) {
    final billItem = BillItem();
    billItem.nameController.text = item['itemName']?.toString() ?? '';
    billItem.qtyController.text = item['qty'].toString();
    billItem.rateController.text = item['rate'].toString();
    billItem.uomController.text = item['uom']?.toString() ?? "";
    return billItem;
  }).toList();

  PdfService().printBill(
    invoiceNo: inv['invoiceNo'].toString(),
    invoiceDate: DateTime.parse(inv['invoiceDate']),
    state: inv['state']?.toString() ?? "",
    stateCode: inv['stateCode']?.toString() ?? "",
    receiverName: inv['receiverName'] ?? "",
    receiverAddress: inv['receiverAddress'] ?? "",
    receiverGstin: inv['receiverGstin']?.toString() ?? "",
    poNumber: inv['poNumber']?.toString() ?? "",
    poDate: inv['poDate'] != null
        ? DateTime.parse(inv['poDate'])
        : DateTime.now(),
    receiverState: inv['receiverState']?.toString() ?? "",
    receiverStateCode: inv['receiverStateCode']?.toString() ?? "",
    items: items,
    subTotal: inv['subtotal'] ?? 0,
    discountAmount: inv['discount'] ?? 0,
    discountPercentText: "0",
    netTotal: inv['netTotal'] ?? 0,
  );
}
