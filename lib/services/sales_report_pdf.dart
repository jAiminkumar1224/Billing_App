import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

Future<File> generateSalesReportPDF(
  List<Map<String, dynamic>> salesList, {
  required DateTime fromDate,
  required DateTime toDate,
  String? customPath,
}) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),

      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            /// TITLE
            pw.Text(
              "AKASH ENTERPRISE SALES REGISTER",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              "Sales Report From: ${formatDate(fromDate)} To: ${formatDate(toDate)}",
              style: const pw.TextStyle(fontSize: 10),
            ),

            pw.SizedBox(height: 10),

            pw.SizedBox(height: 10),

            /// HEADER ROW (NO BOX)
            pw.Row(
              children: [
                header("DATE", 2),
                header("INVOICE", 1),
                header("ITEM NAME", 4),
                header("QTY", 1),
                header("RATE", 1.5),
                header("AMOUNT", 2),
              ],
            ),

            pw.Divider(), // only one line
            /// DATA
            ...salesList.map((sale) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Row(
                  children: [
                    cell(formatDate(sale['invoiceDate']), 2),
                    cell(sale['invoiceNo'], 1),
                    cell(sale['itemName'], 4),
                    cell(sale['qty'], 1),
                    cell(sale['rate'], 1.5),
                    cell(sale['amount'], 2),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    ),
  );

  final dir = await getTemporaryDirectory();
  final file = File("${dir.path}/sales_report.pdf");

  await file.writeAsBytes(await pdf.save());

  return file;
}

/// HEADER
pw.Widget header(String text, double flex) {
  return pw.Expanded(
    flex: flex.toInt(),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
    ),
  );
}

/// CELL
pw.Widget cell(dynamic value, double flex) {
  return pw.Expanded(
    flex: flex.toInt(),
    child: pw.Text(
      value?.toString() ?? '',
      style: const pw.TextStyle(fontSize: 10),
    ),
  );
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
