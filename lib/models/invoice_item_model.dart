class InvoiceItemModel {
  int? id;
  int invoiceId;
  String itemName;
  String uom;
  int qty;
  double rate;
  double amount;

  InvoiceItemModel({
    this.id,
    required this.invoiceId,
    required this.itemName,
    required this.uom,
    required this.qty,
    required this.rate,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'itemName': itemName,
      'uom': uom,
      'qty': qty,
      'rate': rate,
      'amount': amount,
    };
  }
}