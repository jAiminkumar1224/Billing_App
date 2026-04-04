import 'package:billing_app/database/database_helper.dart';
import 'package:billing_app/models/invoice_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';
import 'data_screen.dart';

class BillScreen extends StatefulWidget {
  final Map<String, dynamic>? customerData;
  final String? invoiceNo;
  final InvoiceModel? invoice;

  const BillScreen({
    super.key,
    this.customerData,
    this.invoiceNo,
    this.invoice,
  });

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class AppSidebar extends StatelessWidget {
  final int selectedIndex;

  const AppSidebar({super.key, required this.selectedIndex});

  Widget buildItem({
    required BuildContext context,
    required IconData icon,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE6F0FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),

          buildItem(
            context: context,
            icon: Icons.receipt_long,
            index: 0,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BillScreen()),
              );
            },
          ),

          buildItem(
            context: context,
            icon: Icons.storage,
            index: 1,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DataScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ------------------
/// Bill Item Model
/// ------------------
class BillItem {
  final nameController = TextEditingController();
  final uomController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final rateController = TextEditingController(text: '0');

  double get amount {
    final qty = int.tryParse(qtyController.text) ?? 0;
    final rate = double.tryParse(rateController.text) ?? 0;
    return qty * rate;
  }

  void clear() {
    nameController.clear();
    uomController.clear();
    qtyController.text = '1';
    rateController.text = '0';
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: newValue.composing,
    );
  }
}

class _BillScreenState extends State<BillScreen> {
  final invoiceNoController = TextEditingController();
  DateTime? invoiceDate;

  final stateController = TextEditingController();
  final stateCodeController = TextEditingController();
  final receiverStateCodeController = TextEditingController();
  final receiverNameController = TextEditingController();
  final receiverAddressController = TextEditingController();
  final receiverGstinController = TextEditingController();
  final receiverStateController = TextEditingController();
  final contactNumberController = TextEditingController();
  final whatsappNumberController = TextEditingController();
  final emailController = TextEditingController();

  late final ScrollController _itemScrollController;

  String lastInvoiceNo = "";
  final FocusNode invoiceFocus = FocusNode();
  bool showLastInvoice = true;

  bool isSaved = false;
  String paymentStatus = "Pending";
  int? savedInvoiceId;

  final poNumberController = TextEditingController();
  DateTime? poDate;

  final discountController = TextEditingController(text: '0');

  final List<BillItem> items = [];

  double get subTotal => items.fold(0, (sum, item) => sum + item.amount);

  double get discountAmount {
    double percent = double.tryParse(discountController.text) ?? 0;

    if (percent < 0) percent = 0;

    return subTotal * percent / 100;
  }

  double get netTotal => subTotal - discountAmount;

  @override
  void initState() {
    super.initState();

    if (widget.customerData != null) {
      final data = widget.customerData!;

      receiverNameController.text = data['receiverName'] ?? '';
      receiverAddressController.text = data['receiverAddress'] ?? '';
      receiverStateController.text = data['receiverState'] ?? '';
      receiverStateCodeController.text = data['receiverStateCode'] ?? '';
      contactNumberController.text = data['contactNumber'] ?? '';
      receiverGstinController.text = data['receiverGstin'] ?? '';
      emailController.text = data['email'] ?? '';
      whatsappNumberController.text = data['whatsappNumber'] ?? '';
      poNumberController.text = data['poNumber'] ?? '';
    }

    _itemScrollController = ScrollController();

    loadLastInvoice();
    if (widget.invoice != null) {
      invoiceNoController.text = widget.invoice!.invoiceNo;
      invoiceDate = DateTime.parse(widget.invoice!.invoiceDate);

      stateController.text = widget.invoice!.state;
      stateCodeController.text = widget.invoice!.stateCode;

      receiverNameController.text = widget.invoice!.receiverName;
      receiverAddressController.text = widget.invoice!.receiverAddress;
      receiverGstinController.text = widget.invoice!.receiverGstin;
      receiverStateController.text = widget.invoice!.receiverState;
      receiverStateCodeController.text = widget.invoice!.receiverStateCode;
      contactNumberController.text = widget.invoice!.contactNumber;
      whatsappNumberController.text = widget.invoice!.whatsappNumber;
      emailController.text = widget.invoice!.email;

      poNumberController.text = widget.invoice!.poNumber;
      poDate = DateTime.parse(widget.invoice!.poDate);

      paymentStatus = widget.invoice!.paymentStatus;

      loadItems();
    }
    addListeners();

    invoiceNoController.addListener(() {
      if (invoiceNoController.text.isEmpty) {
        setState(() {
          showLastInvoice = true;
        });
      } else {
        setState(() {
          showLastInvoice = false;
        });
      }
    });

    invoiceNoController.addListener(() {
      String normalized = normalizeInvoiceNo(invoiceNoController.text);

      if (invoiceNoController.text != normalized) {
        invoiceNoController.value = TextEditingValue(
          text: normalized,
          selection: TextSelection.collapsed(offset: normalized.length),
        );
      }
    });
  }

  void addListeners() {
    void refresh() {
      if (mounted) setState(() {});
    }

    invoiceNoController.addListener(refresh);
    receiverNameController.addListener(refresh);
    receiverAddressController.addListener(refresh);
    receiverGstinController.addListener(refresh);
    receiverStateController.addListener(refresh);
    receiverStateCodeController.addListener(refresh);
    contactNumberController.addListener(refresh);
    whatsappNumberController.addListener(refresh);
    emailController.addListener(refresh);
    stateController.addListener(refresh);
    stateCodeController.addListener(refresh);
    poNumberController.addListener(refresh);
    discountController.addListener(refresh);
  }

  String normalizeInvoiceNo(String value) {
    if (value.isEmpty) return value;
    return int.tryParse(value)?.toString() ?? value;
  }

  Future<void> loadItems() async {
    final db = await DatabaseHelper.instance.database;

    final data = await db.query(
      'invoice_items',
      where: 'invoiceId = ?',
      whereArgs: [widget.invoice!.id],
    );

    items.clear();

    for (var item in data) {
      final newItem = BillItem();
      newItem.nameController.text = item['itemName'].toString();
      newItem.uomController.text = item['uom'].toString();
      newItem.qtyController.text = item['qty'].toString();
      newItem.rateController.text = item['rate'].toString();

      items.add(newItem);
    }

    setState(() {});
  }

  Future<void> loadLastInvoice() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery(
      "SELECT invoiceNo FROM invoices ORDER BY id DESC LIMIT 1",
    );

    if (result.isNotEmpty) {
      setState(() {
        lastInvoiceNo = result.first['invoiceNo'].toString();
        showLastInvoice = true;
      });
    }
  }

  Future<int> insertInvoice(Map<String, dynamic> row) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert('invoices', row);
  }

  Future<bool> isInvoiceExists(String invoiceNo) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'invoices',
      where: 'invoiceNo = ?',
      whereArgs: [normalizeInvoiceNo(invoiceNo)],
    );

    return result.isNotEmpty;
  }

  Future<void> saveBillToDatabase() async {
    void showError(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }

    //    Invoice No
    if (invoiceNoController.text.trim().isEmpty) {
      showError("Invoice Number is required");
      return;
    }

    //    Invoice Date
    if (invoiceDate == null) {
      showError("Invoice Date is required");
      return;
    }

    //    State
    if (stateController.text.trim().isEmpty) {
      showError("State is required");
      return;
    }

    //    State Code
    if (stateCodeController.text.trim().isEmpty) {
      showError("State Code is required");
      return;
    }

    //    Receiver Name
    if (receiverNameController.text.trim().isEmpty) {
      showError("Receiver Name is required");
      return;
    }

    //    Receiver Address
    if (receiverAddressController.text.trim().isEmpty) {
      showError("Receiver Address is required");
      return;
    }

    //    GSTIN
    String gstin = receiverGstinController.text.trim().toUpperCase();

    if (gstin.isEmpty) {
      showError("GSTIN is required");
      return;
    }

    // GSTIN FORMAT VALIDATION
    if (!RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
    ).hasMatch(gstin)) {
      showError("Enter valid GSTIN");
      return;
    }

    //    Receiver State
    if (receiverStateController.text.trim().isEmpty) {
      showError("Receiver State is required");
      return;
    }
    //    Receiver State Code
    if (receiverStateCodeController.text.trim().isEmpty) {
      showError("Receiver State Code is required");
      return;
    }

    String contact = contactNumberController.text.trim();

    if (contact.isEmpty) {
      showError("Contact Number is required");
      return;
    }

    // Indian Mobile Validation (10 digit, starts with 6-9)
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(contact)) {
      showError("Enter valid Contact Number");
      return;
    }

    //    Email
    if (emailController.text.trim().isEmpty) {
      showError("Email is required");
      return;
    }

    //    Email Format
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      showError("Enter valid Email");
      return;
    }

    //    PO Number
    if (poNumberController.text.trim().isEmpty) {
      showError("PO Number is required");
      return;
    }

    //    PO Date
    if (poDate == null) {
      showError("PO Date is required");
      return;
    }

    if (invoiceNoController.text.trim().isEmpty ||
        invoiceDate == null ||
        stateController.text.trim().isEmpty ||
        stateCodeController.text.trim().isEmpty ||
        receiverNameController.text.trim().isEmpty ||
        receiverAddressController.text.trim().isEmpty ||
        receiverGstinController.text.trim().isEmpty ||
        receiverStateController.text.trim().isEmpty ||
        receiverStateCodeController.text.trim().isEmpty ||
        contactNumberController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        poNumberController.text.trim().isEmpty ||
        poDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all mandatory fields (*)"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (items.isEmpty) {
      showError("Add at least one item");
      return;
    }

    bool hasValidItem = false;

    for (var item in items) {
      String name = item.nameController.text.trim();
      String uom = item.uomController.text.trim();
      int qty = int.tryParse(item.qtyController.text) ?? 0;
      double rate = double.tryParse(item.rateController.text) ?? 0;

      if (name.isNotEmpty && uom.isNotEmpty && qty > 0 && rate > 0) {
        hasValidItem = true;
        break;
      }
    }

    if (!hasValidItem) {
      showError("Enter at least one valid item with all details");
      return;
    }

    if (invoiceNoController.text.isEmpty || invoiceDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill required fields")));
      return;
    }

    if (contactNumberController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Contact Number and Email are required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid Email"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;

    String normalizedInvoice = normalizeInvoiceNo(invoiceNoController.text);
    bool exists = await isInvoiceExists(normalizedInvoice);

    if (widget.invoice == null && exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invoice Number already exists"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ///  INSERT INVOICE
    final invoice = InvoiceModel(
      invoiceNo: normalizeInvoiceNo(invoiceNoController.text),
      invoiceDate: invoiceDate!.toIso8601String(),

      state: stateController.text,
      stateCode: stateCodeController.text,

      receiverName: receiverNameController.text,
      receiverAddress: receiverAddressController.text,
      receiverGstin: receiverGstinController.text,
      receiverState: receiverStateController.text,
      receiverStateCode: receiverStateCodeController.text,
      contactNumber: contactNumberController.text,
      whatsappNumber: whatsappNumberController.text,
      email: emailController.text,

      poNumber: poNumberController.text,
      poDate: poDate?.toIso8601String() ?? "",

      subtotal: subTotal,
      discount: discountAmount,
      netTotal: netTotal,
      paymentStatus: paymentStatus,
    );

    if (widget.invoice == null) {
      if (widget.invoice == null) {
        savedInvoiceId = await db.insert('invoices', invoice.toMap());
      } else {
        //  UPDATE
        savedInvoiceId = widget.invoice!.id;

        await db.update(
          'invoices',
          invoice.toMap(),
          where: 'id = ?',
          whereArgs: [savedInvoiceId],
        );

        await db.delete(
          'invoice_items',
          where: 'invoiceId = ?',
          whereArgs: [savedInvoiceId],
        );
      }
    } else {
      savedInvoiceId = widget.invoice!.id;

      await db.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [savedInvoiceId],
      );

      await db.delete(
        'invoice_items',
        where: 'invoiceId = ?',
        whereArgs: [savedInvoiceId],
      );
    }

    ///  INSERT ITEMS
    for (var item in items) {
      await db.insert('invoice_items', {
        'invoiceId': savedInvoiceId,
        'itemName': item.nameController.text,
        'uom': item.uomController.text,
        'qty': int.tryParse(item.qtyController.text) ?? 0,
        'rate': double.tryParse(item.rateController.text) ?? 0,
        'amount': item.amount,
      });
    }

    isSaved = true;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Bill Saved Successfully")));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.invoice != null && mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  Future<bool> askSaveBeforePrint() async {
    if (isSaved) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Save Bill"),
        content: const Text("You must save bill before printing"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await saveBillToDatabase();
              Navigator.pop(context, true);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> pickDate(bool isInvoice) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        isInvoice ? invoiceDate = picked : poDate = picked;
      });
    }
  }

  void addItem() {
    setState(() {
      items.add(BillItem());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_itemScrollController.hasClients) {
        _itemScrollController.animateTo(
          _itemScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void removeItem(int index) => setState(() => items.removeAt(index));

  Future<void> resetAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Reset Invoice',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'This will clear all entered invoice details. This action cannot be undone.',
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (confirm != true) return;

    setState(() {
      invoiceNoController.clear();
      invoiceDate = null;
      stateController.clear();
      stateCodeController.clear();

      receiverNameController.clear();
      receiverAddressController.clear();
      receiverGstinController.clear();
      receiverStateController.clear();
      receiverStateCodeController.clear();

      contactNumberController.clear();
      whatsappNumberController.clear();
      emailController.clear();

      poNumberController.clear();
      poDate = null;

      discountController.text = '0';

      for (final item in items) {
        item.clear();
      }
      items.clear();
    });
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'This will clear all entered invoice details. This action cannot be undone.',
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (confirm == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text('Billing Screen'),

        actions: [
          TextButton(
            onPressed: saveBillToDatabase,
            child: const Text('SAVE', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),

      body: Row(
        children: [
          const AppSidebar(selectedIndex: 0),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildHeaderInputs(),
                  buildItemHeader(),

                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 340),
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _itemScrollController,
                                  child: buildItemList(),
                                ),
                              ),
                              buildAddItemButton(),
                            ],
                          ),
                        ),

                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [buildSummary()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      ///  FOOTER BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            /// RESET BUTTON
            SizedBox(
              width: 140,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: resetAll,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A), // Deep Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// LOGOUT BUTTON
            SizedBox(
              width: 140,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: logout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626), // Soft Red
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeaderInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: invoiceNoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,

                    label: const Text.rich(
                      TextSpan(
                        text: 'Invoice No',
                        children: [
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),

                    suffixText: showLastInvoice && lastInvoiceNo.isNotEmpty
                        ? "Last Saved Bill No : $lastInvoiceNo"
                        : null,

                    suffixStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: dateRow(
                'Invoice Date*',
                invoiceDate,
                () => pickDate(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: rowInput(
                'State*',
                stateController,
                allowOnlyLetters: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: rowInput(
                'State Code*',
                stateCodeController,
                isNumericOnly: true,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  rowInput('Receiver Name*', receiverNameController),
                  rowInput('Receiver Address*', receiverAddressController),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextField(
                      controller: receiverGstinController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9]'),
                        ),
                        UpperCaseTextFormatter(),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        label: Text.rich(
                          TextSpan(
                            text: 'GSTIN/UIN',
                            children: [
                              TextSpan(
                                text: '*',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: rowInput(
                          'Receiver State*',
                          receiverStateController,
                          allowOnlyLetters: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: rowInput(
                          'Receiver State Code*',
                          receiverStateCodeController,
                          isNumericOnly: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: rowInput(
                'Contact Number *',
                contactNumberController,
                isNumericOnly: true,
                maxLength: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: rowInput('Email *', emailController)),
            const SizedBox(width: 12),
            Expanded(
              child: rowInput(
                'WhatsApp Number',
                whatsappNumberController,
                isNumericOnly: true,
                maxLength: 10,
              ),
            ),
          ],
        ),

        Row(
          children: [
            Expanded(
              child: rowInput(
                'PO Number*',
                poNumberController,
                alphaNumericOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: dateRow('PO Date*', poDate, () => pickDate(false))),
          ],
        ),
      ],
    );
  }

  Widget rowInput(
    String label,
    TextEditingController controller, {
    bool isNumericOnly = false,
    bool allowOnlyLetters = false,
    bool alphaNumericOnly = false,
    bool checkInvoice = false,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        buildCounter:
            (
              context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) => null,
        keyboardType: isNumericOnly ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumericOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : allowOnlyLetters
            ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))]
            : alphaNumericOnly
            ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))]
            : null,

        onChanged: (value) async {
          if (checkInvoice && value.length > 1) {
            bool exists = await isInvoiceExists(value);

            if (exists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("⚠ Invoice Number already exists"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },

        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          label: RichText(
            text: TextSpan(
              text: label.replaceAll('*', ''),
              style: const TextStyle(color: Colors.black),
              children: label.contains('*')
                  ? const [
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: Colors.red),
                      ),
                    ]
                  : [],
            ),
          ),
        ),
      ),
    );
  }

  Widget dateRow(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,

            label: RichText(
              text: TextSpan(
                text: label.replaceAll('*', ''),
                style: const TextStyle(color: Colors.black),
                children: label.contains('*')
                    ? const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Colors.red),
                        ),
                      ]
                    : [],
              ),
            ),
          ),
          child: Text(
            date == null
                ? 'Select Date'
                : '${date.day}/${date.month}/${date.year}',
          ),
        ),
      ),
    );
  }

  Widget buildItemHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2, right: 340),
      child: Row(
        children: const [
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                'Sr. No.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(width: 6),

          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'Item',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(width: 6),

          Expanded(
            child: Center(
              child: Text('UOM', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 6),

          Expanded(
            child: Center(
              child: Text('Qty', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(width: 6),

          Expanded(
            child: Center(
              child: Text(
                'Rate',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(width: 6),

          Expanded(
            child: Center(
              child: Text(
                'Amount',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          SizedBox(
            width: 48,
            child: Center(
              child: Text(
                'Delete\nItem',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItemList() {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: '${index + 1}'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Color(0xFFF0F0F0),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                flex: 2,
                child: TextField(
                  controller: item.nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: TextField(
                  controller: item.uomController,
                  textAlign: TextAlign.left,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: TextField(
                  controller: item.qtyController,
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onTap: () {
                    if (item.qtyController.text == "1") {
                      item.qtyController.clear();
                    }
                  },
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: TextField(
                  controller: item.rateController,
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  onTap: () {
                    if (item.rateController.text == "0") {
                      item.rateController.clear();
                    }
                  },
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(
                    text: item.amount.toStringAsFixed(2),
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                  ),
                ),
              ),

              IconButton(
                onPressed: () => removeItem(index),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget buildAddItemButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: addItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget buildSummary() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 15, bottom: 10),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          child: Container(
            width: 320,
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER DETAILS =================
                const Text(
                  "Invoice Summary",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                ValueListenableBuilder(
                  valueListenable: invoiceNoController,
                  builder: (context, value, _) {
                    return summaryText("Invoice No", value.text);
                  },
                ),

                summaryText(
                  "Invoice Date",
                  invoiceDate == null
                      ? "-"
                      : "${invoiceDate!.day}/${invoiceDate!.month}/${invoiceDate!.year}",
                ),

                ValueListenableBuilder(
                  valueListenable: receiverNameController,
                  builder: (context, value, _) {
                    return summaryText("Receiver", value.text);
                  },
                ),

                ValueListenableBuilder(
                  valueListenable: receiverGstinController,
                  builder: (context, value, _) {
                    return summaryText("GSTIN", value.text);
                  },
                ),

                ValueListenableBuilder(
                  valueListenable: contactNumberController,
                  builder: (context, value, _) {
                    return summaryText("Contact", value.text);
                  },
                ),

                ValueListenableBuilder(
                  valueListenable: emailController,
                  builder: (context, value, _) {
                    return summaryText("Email", value.text);
                  },
                ),
                summaryText("Total Items", items.length.toString()),

                const Divider(height: 10),

                // ================= AMOUNT =================
                summaryRow('Sub Total', subTotal),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Expanded(child: Text('Discount (%)')),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: discountController,
                        textAlign: TextAlign.right, // IMPORTANT
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*$'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                        ),
                        onChanged: (value) {
                          double discount = double.tryParse(value) ?? 0;

                          if (discount < 0) {
                            discountController.text = "0";
                            discountController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(
                                    offset: discountController.text.length,
                                  ),
                                );

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Discount cannot be negative"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }

                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                summaryRow('Discount Amount', discountAmount),

                const Divider(height: 10),

                summaryRow('Net Total', netTotal, isBold: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget summaryText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? "-" : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryRow(String label, double value, {bool isBold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: isBold ? const TextStyle(fontWeight: FontWeight.bold) : null,
        ),
      ],
    );
  }
}
