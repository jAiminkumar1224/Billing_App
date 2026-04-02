class InvoiceModel {
  int? id;
  String invoiceNo;
  String invoiceDate;
  String state;
  String stateCode;
  String receiverName;
  String receiverAddress;
  String receiverGstin;
  String receiverState;
  String receiverStateCode;
  String contactNumber;
  String whatsappNumber;
  String email;
  String poNumber;
  String poDate;
  double subtotal;
  double discount;
  double netTotal;
  String paymentStatus;

  InvoiceModel({
    this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.state,

    required this.stateCode,
    required this.receiverName,
    required this.receiverAddress,
    required this.receiverGstin,
    required this.receiverState,
    required this.receiverStateCode,
    required this.contactNumber,
    required this.whatsappNumber,
    required this.email,
    
    required this.poNumber,
    required this.poDate,
    required this.subtotal,
    required this.discount,
    required this.netTotal,
    required this.paymentStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoiceNo': invoiceNo,
      'invoiceDate': invoiceDate,
      'state': state,
      'stateCode': stateCode,
      'receiverName': receiverName,
      'receiverAddress': receiverAddress,
      'receiverGstin': receiverGstin,
      'receiverState': receiverState,
      'receiverStateCode': receiverStateCode,
      'contactNumber': contactNumber,
      'whatsappNumber': whatsappNumber,
      'email': email,
      'poNumber': poNumber,
      'poDate': poDate,
      'subtotal': subtotal,
      'discount': discount,
      'netTotal': netTotal,
      'paymentStatus': paymentStatus,
    };
  }
}
