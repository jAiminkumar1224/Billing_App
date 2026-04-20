import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

class PdfService {
  Future<void> printBill({
    required String invoiceNo,
    required DateTime invoiceDate,
    required String state,
    required String stateCode,
    required String receiverStateCode,
    required String receiverState,
    required String receiverName,
    required String receiverAddress,
    required String receiverGstin,
    required String poNumber,
    required DateTime poDate,
    required List items,
    required double subTotal,
    required double discountAmount,
    required double netTotal,
    required String discountPercentText,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.SizedBox(height: PdfPageFormat.cm * 4.5),
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 0,
          marginRight: 0,
          marginTop: 0,
          marginBottom: PdfPageFormat.cm * 1,
        ),

        ///  footer always bottom (bank + sign)
        footer: (context) => pw.Padding(
          padding: pw.EdgeInsets.only(
            left: PdfPageFormat.cm * 1,
            right: PdfPageFormat.cm * 1,
          ),
          child: bankAndSignatureSection(),
        ),

        build: (context) => [
          /// ================= HEADER =================
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: PdfPageFormat.cm * 1),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'BILL OF SUPPLY',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),

                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(35),
                    1: pw.FlexColumnWidth(35),
                    2: pw.FlexColumnWidth(20),
                    3: pw.FlexColumnWidth(10),
                  },
                  children: [
                    fixedInfoRow(
                      'Invoice No : $invoiceNo',
                      'GSTIN : 24***********Z6',
                      'Original',
                    ),
                    fixedInfoRow(
                      'Date : ${formatDate(invoiceDate)}',
                      'PAN : FR******9J',
                      'Duplicate',
                    ),
                    fixedInfoRow(
                      'State : $state',
                      'State Code : $stateCode',
                      'Triplicate',
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),

                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        receiverBox(
                          receiverName,
                          receiverAddress,
                          receiverGstin,
                          receiverState,
                          receiverStateCode,
                        ),
                        poBox(poNumber, poDate),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
              ],
            ),
          ),

          /// ================= ITEMS TABLE =================
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: PdfPageFormat.cm * 1),
            child: pw.Table(
              border: pw.TableBorder(
                left: pw.BorderSide(),
                right: pw.BorderSide(),
                top: pw.BorderSide(),
                bottom: pw.BorderSide(),
                verticalInside: pw.BorderSide(),
                horizontalInside: pw.BorderSide.none,
              ),
              columnWidths: {
                0: pw.FlexColumnWidth(0.6),
                1: pw.FlexColumnWidth(5.7),
                2: pw.FlexColumnWidth(0.8),
                3: pw.FlexColumnWidth(0.8),
                4: pw.FlexColumnWidth(0.8),
                5: pw.FlexColumnWidth(1.5),
              },
              children: [
                /// header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 1)),
                  ),
                  children: [
                    headerCell('No'),
                    headerCell('Description of Goods'),
                    headerCell('UOM'),
                    headerCell('Qty'),
                    headerCell('Rate'),
                    headerCell('Amount'),
                  ],
                ),

                /// items
                ...items.asMap().entries.map((e) {
                  final i = e.key + 1;
                  final item = e.value;
                  return pw.TableRow(
                    children: [
                      normalCell(i.toString()),
                      normalCell(
                        item.nameController.text,
                        alignment: pw.Alignment.centerLeft,
                      ),
                      normalCell(item.uomController.text),
                      normalCell(item.qtyController.text),
                      normalCell(item.rateController.text),
                      normalCell(
                        item.amount.toStringAsFixed(2),
                        alignment: pw.Alignment.centerRight,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          /// ================= TOTALS (SMART FLOW) =================
          pw.SizedBox(height: 8),

          /// IMPORTANT: split na thay
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: PdfPageFormat.cm * 1),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                /// summary
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    children: [
                      totalRow('Sub Total', subTotal),
                      if (discountAmount > 0)
                        totalRow(
                          'Discount ($discountPercentText%)',
                          -discountAmount,
                        ),
                      pw.Divider(),
                      totalRow('Net Total', netTotal, bold: true),
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),

                /// amount in words
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Invoice Amount In Words:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Align(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          numberToWords(netTotal),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> downloadBill({
    required String invoiceNo,
    required DateTime invoiceDate,
    required String state,
    required String stateCode,
    required String receiverStateCode,
    required String receiverState,
    required String receiverName,
    required String receiverAddress,
    required String receiverGstin,
    required String poNumber,
    required DateTime poDate,
    required List items,
    required double subTotal,
    required double discountAmount,
    required double netTotal,
    required String discountPercentText,
  }) async {
    final pdf = pw.Document();

    // SAME CODE (copy from printBill)
    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.SizedBox(height: PdfPageFormat.cm * 4.5),
        pageFormat: PdfPageFormat.a4.copyWith(
          marginLeft: 0,
          marginRight: 0,
          marginTop: 0,
          marginBottom: PdfPageFormat.cm * 1,
        ),
        footer: (context) => pw.Padding(
          padding: pw.EdgeInsets.only(
            left: PdfPageFormat.cm * 1,
            right: PdfPageFormat.cm * 1,
          ),
          child: bankAndSignatureSection(),
        ),
        build: (context) => [
          //  IMPORTANT:
          /// Ahiya tu printBill mathi pura content copy paste karje
          ///           /// ================= HEADER =================
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: PdfPageFormat.cm * 1),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'BILL OF SUPPLY',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),

                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(35),
                    1: pw.FlexColumnWidth(35),
                    2: pw.FlexColumnWidth(20),
                    3: pw.FlexColumnWidth(10),
                  },
                  children: [
                    fixedInfoRow(
                      'Invoice No : $invoiceNo',
                      'GSTIN : 24***********Z6',
                      'Original',
                    ),
                    fixedInfoRow(
                      'Date : ${formatDate(invoiceDate)}',
                      'PAN : FR******9J',
                      'Duplicate',
                    ),
                    fixedInfoRow(
                      'State : $state',
                      'State Code : $stateCode',
                      'Triplicate',
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),

                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(3),
                    1: pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      children: [
                        receiverBox(
                          receiverName,
                          receiverAddress,
                          receiverGstin,
                          receiverState,
                          receiverStateCode,
                        ),
                        poBox(poNumber, poDate),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
              ],
            ),
          ),

          /// ================= ITEMS TABLE =================
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: PdfPageFormat.cm * 1),
            child: pw.Table(
              border: pw.TableBorder(
                left: pw.BorderSide(),
                right: pw.BorderSide(),
                top: pw.BorderSide(),
                bottom: pw.BorderSide(),
                verticalInside: pw.BorderSide(),
                horizontalInside: pw.BorderSide.none,
              ),
              columnWidths: {
                0: pw.FlexColumnWidth(0.6),
                1: pw.FlexColumnWidth(5.5),
                2: pw.FlexColumnWidth(1.0),
                3: pw.FlexColumnWidth(0.8),
                4: pw.FlexColumnWidth(1.4),
                5: pw.FlexColumnWidth(1.5),
              },
              children: [
                /// header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 1)),
                  ),
                  children: [
                    headerCell('No'),
                    headerCell('Description of Goods'),
                    headerCell('UOM'),
                    headerCell('Qty'),
                    headerCell('Rate'),
                    headerCell('Amount'),
                  ],
                ),

                /// items
                ...items.asMap().entries.map((e) {
                  final i = e.key + 1;
                  final item = e.value;
                  return pw.TableRow(
                    children: [
                      normalCell(i.toString()),
                      normalCell(
                        item['itemName'],
                        alignment: pw.Alignment.centerLeft,
                      ),
                      normalCell(item['uom'] ?? ""),
                      normalCell(item['qty'].toString()),
                      normalCell(item['rate'].toString()),
                      normalCell(
                        double.parse(
                          item['amount'].toString(),
                        ).toStringAsFixed(2),
                        alignment: pw.Alignment.centerRight,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          /// ================= TOTALS (SMART FLOW) =================
          pw.SizedBox(height: 8),

          /// IMPORTANT: split na thay
          pw.Padding(
            padding: pw.EdgeInsets.symmetric(horizontal: PdfPageFormat.cm * 1),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                /// summary
                pw.Container(
                  width: 250,
                  child: pw.Column(
                    children: [
                      totalRow('Sub Total', subTotal),
                      if (discountAmount > 0)
                        totalRow(
                          'Discount ($discountPercentText%)',
                          -discountAmount,
                        ),
                      pw.Divider(),
                      totalRow('Net Total', netTotal, bold: true),
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),

                /// amount in words
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Invoice Amount In Words:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Align(
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          numberToWords(netTotal),
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    String fileName = 'Invoice_${invoiceNo}_${sanitizeFileName(receiverName)}';

    if (!fileName.toLowerCase().endsWith('.pdf')) {
      fileName = '$fileName.pdf';
    }

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Invoice PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (outputFile == null) return;

    String finalPath = outputFile;

    if (!finalPath.toLowerCase().endsWith('.pdf')) {
      finalPath = '$finalPath.pdf';
    }

    final file = File(finalPath);
    await file.writeAsBytes(bytes);

    await OpenFilex.open(finalPath);
  }
}

/// ================= BANK + SEAL + GST =================
pw.Widget bankAndSignatureSection() {
  const double boxHeight = 120;
  const double dividerY = 45;

  return pw.Column(
    children: [
      pw.Table(
        border: pw.TableBorder.all(),
        columnWidths: {
          0: const pw.FlexColumnWidth(2.6), // LEFT
          1: const pw.FlexColumnWidth(1.4), //    SEAL (NARROW)
          2: const pw.FlexColumnWidth(2.6), // RIGHT
        },
        children: [
          pw.TableRow(
            children: [
              /// ---------------- LEFT : BANK ----------------
              pw.Container(
                height: boxHeight,
                padding: const pw.EdgeInsets.all(6),
                child: pw.Stack(
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Center(
                          child: pw.Text(
                            ': Bank Details : HDFC Bank Ltd :',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 5),

                        pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 85,
                              child: pw.Text(
                                'A/C',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.SizedBox(width: 10, child: pw.Text(':')),
                            pw.Text(
                              '50**********71',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),

                        pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 85,
                              child: pw.Text(
                                'Bank Branch IFSC',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.SizedBox(width: 10, child: pw.Text(':')),
                            pw.Text(
                              'HDFC*****28',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 5),
                      ],
                    ),

                    ///    SAME DIVIDER LEVEL
                    pw.Positioned(
                      top: dividerY,
                      left: 0,
                      right: 0,
                      child: pw.Container(height: 0.8, color: PdfColors.black),
                    ),

                    ///    T&C MOVED UP (ABOVE BOTTOM)
                    pw.Positioned(
                      top: dividerY + 8,
                      left: 0,
                      right: 0,
                      child: pw.Center(
                        child: pw.Text(
                          ': Terms and Conditions :',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// ---------------- MIDDLE : SEAL ----------------
              pw.Container(
                height: boxHeight,
                padding: const pw.EdgeInsets.only(bottom: 10), //    bottom gap
                alignment: pw.Alignment.bottomCenter,
                child: pw.Text(
                  '(Common Seal)',
                  style: pw.TextStyle(fontSize: 10), //    font increased
                ),
              ),

              /// ---------------- RIGHT : GST ----------------
              pw.Container(
                height: boxHeight,
                padding: const pw.EdgeInsets.all(6),
                child: pw.Stack(
                  children: [
                    /// TITLE
                    pw.Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: pw.Center(
                        child: pw.Text(
                          'GST Composition Scheme',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    /// DIVIDER
                    pw.Positioned(
                      top: dividerY,
                      left: 0,
                      right: 0,
                      child: pw.Container(height: 0.8, color: PdfColors.black),
                    ),

                    /// CONTENT
                    pw.Positioned(
                      top: dividerY + 5,
                      left: 0,
                      right: 0,
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Certified that the particulars given are true.',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 10),
                          ),

                          pw.SizedBox(height: 2),

                          pw.Text(
                            'For, AKSH ENTERPRISES',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(height: 22),

                          pw.Text(
                            'Authorised Signatory',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      /// FOOTER
      pw.Padding(
        padding: pw.EdgeInsets.only(bottom: PdfPageFormat.cm * 2),
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              left: pw.BorderSide(),
              right: pw.BorderSide(),
              bottom: pw.BorderSide(),
            ),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Subject to State Jurisdiction',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.Text('[E&OE]', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    ],
  );
}

/// HELPERS
pw.TableRow fixedInfoRow(String col1, String col2, String col3) {
  return pw.TableRow(
    children: [
      fixedCell(col1),
      fixedCell(col2),
      fixedCell(col3),
      fixedCell(''), // empty last column
    ],
  );
}

pw.Widget fixedCell(String text) {
  return pw.Container(
    height: 20, //    FIXED ROW HEIGHT (key point)
    padding: const pw.EdgeInsets.symmetric(horizontal: 6),
    alignment: pw.Alignment.centerLeft,
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 11),
      maxLines: 1,
      overflow: pw.TextOverflow.clip,
    ),
  );
}

pw.Widget receiverBox(String n, String a, String g, String s, String sc) =>
    pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Receiver Name : $n'),
          pw.SizedBox(height: 3),
          pw.Text('Address : $a'),
          pw.SizedBox(height: 3),
          pw.Text('GSTIN : $g'),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Expanded(child: pw.Text('State : $s')),
              pw.Expanded(child: pw.Text('State Code : $sc')),
            ],
          ),
        ],
      ),
    );

pw.Widget poBox(String p, DateTime d) => pw.Padding(
  padding: const pw.EdgeInsets.all(6),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [pw.Text('PO No : $p'), pw.Text('PO Date : ${formatDate(d)}')],
  ),
);

/// HEADER CELL (BOLD)
pw.Widget headerCell(String text) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
  alignment: pw.Alignment.center,
  child: pw.Text(
    text,
    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
  ),
);

/// NORMAL CELL (NOT BOLD)
pw.Widget normalCell(
  String text, {
  pw.Alignment alignment = pw.Alignment.center,
}) => pw.Container(
  padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 1),
  alignment: alignment,
  child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
);

pw.Widget totalRow(String l, double v, {bool bold = false}) => pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    pw.Text(
      l,
      style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
    ),
    pw.Text(
      v.toStringAsFixed(2),
      style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
    ),
  ],
);

String sanitizeFileName(String name) {
  return name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
      .replaceAll(' ', '_')
      .trim();
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String numberToWords(double amount) {
  int rupees = amount.floor();
  int paise = ((amount - rupees) * 100).round();

  String words = '';

  if (rupees > 0) {
    words = 'Rupees ${_convertToWords(rupees)}';
  }

  if (paise > 0) {
    words += rupees > 0
        ? ' and ${_convertToWords(paise)} Paise'
        : '${_convertToWords(paise)} Paise';
  }

  if (words.isEmpty) {
    words = 'Rupees Zero';
  }

  return '$words Only';
}

String _convertToWords(int number) {
  final units = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  final tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  if (number < 20) {
    return units[number];
  } else if (number < 100) {
    return tens[number ~/ 10] +
        (number % 10 != 0 ? ' ${units[number % 10]}' : '');
  } else if (number < 1000) {
    return '${units[number ~/ 100]} Hundred${number % 100 != 0 ? ' ${_convertToWords(number % 100)}' : ''}';
  } else if (number < 100000) {
    return '${_convertToWords(number ~/ 1000)} Thousand${number % 1000 != 0 ? ' ${_convertToWords(number % 1000)}' : ''}';
  } else if (number < 10000000) {
    return '${_convertToWords(number ~/ 100000)} Lakh${number % 100000 != 0 ? ' ${_convertToWords(number % 100000)}' : ''}';
  } else {
    return '${_convertToWords(number ~/ 10000000)} Crore${number % 10000000 != 0 ? ' ${_convertToWords(number % 10000000)}' : ''}';
  }
}
