//  Future<void> printBill() async {
//     bool canPrint = await askSaveBeforePrint();
//     if (!canPrint) return;

//     for (int i = 0; i < items.length; i++) {
//       if (items[i].nameController.text.trim().isEmpty ||
//           items[i].qtyController.text.trim().isEmpty ||
//           items[i].rateController.text.trim().isEmpty) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: const Text('Incomplete Item'),
//             content: Text(
//               'Item ${i + 1} is empty.\nPlease fill or delete this item.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         );
//         return;
//       }
//     }
//     if (invoiceNoController.text.isEmpty ||
//         invoiceDate == null ||
//         stateController.text.isEmpty ||
//         stateCodeController.text.isEmpty ||
//         receiverNameController.text.isEmpty ||
//         receiverAddressController.text.isEmpty ||
//         receiverGstinController.text.isEmpty ||
//         receiverStateController.text.isEmpty ||
//         receiverStateCodeController.text.isEmpty ||
//         poNumberController.text.isEmpty ||
//         poDate == null ||
//         items.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all mandatory fields')),
//       );
//       return;
//     }

//     PdfService().printBill(
//       invoiceNo: invoiceNoController.text,
//       invoiceDate: invoiceDate!,
//       state: stateController.text,
//       stateCode: stateCodeController.text,
//       receiverName: receiverNameController.text,
//       receiverAddress: receiverAddressController.text,
//       receiverGstin: receiverGstinController.text,
//       poNumber: poNumberController.text,
//       poDate: poDate!,
//       receiverStateCode: receiverStateCodeController.text,
//       items: items,
//       subTotal: subTotal,
//       discountAmount: discountAmount,
//       discountPercentText: discountController.text,
//       netTotal: netTotal,
//     );

//     await insertInvoice({
//       'invoiceNo': invoiceNoController.text,
//       'invoiceDate': invoiceDate!.toIso8601String(),
//       'receiverName': receiverNameController.text,
//       'receiverAddress': receiverAddressController.text,
//       'subtotal': subTotal,
//       'discount': discountAmount,
//       'netTotal': netTotal,
//       'paymentStatus': "Paid",
//     });
//   }