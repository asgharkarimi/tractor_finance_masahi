import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/farmer.dart';

class PdfService {
  static Future<void> generateReport({
    required List<Farmer> farmers,
    required double pricePerHectare,
  }) async {
    final pdf = pw.Document();

    double totalIncome = 0;
    double totalReceived = 0;
    double totalRemaining = 0;

    for (var farmer in farmers) {
      final debt = farmer.getTotalDebt(pricePerHectare);
      final paid = farmer.getTotalPaid();
      totalIncome += debt;
      totalReceived += paid;
      totalRemaining += (debt - paid);
    }

    final numberFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('yyyy/MM/dd');

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              'Tractor Income Report',
              style: const pw.TextStyle(fontSize: 24),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Date: ${dateFormat.format(DateTime.now())}'),
            pw.Divider(),
            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Summary', style: const pw.TextStyle(fontSize: 18)),
                  pw.SizedBox(height: 10),
                  pw.Text(
                      'Total Income: ${numberFormat.format(totalIncome.toInt())} Toman'),
                  pw.Text(
                      'Received: ${numberFormat.format(totalReceived.toInt())} Toman'),
                  pw.Text(
                      'Remaining: ${numberFormat.format(totalRemaining.toInt())} Toman'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Farmers list
            pw.Text('Farmers List', style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 10),
          ];

          // Add farmers
          for (var farmer in farmers) {
            final debt = farmer.getTotalDebt(pricePerHectare);
            final paid = farmer.getTotalPaid();
            final remaining = debt - paid;

            widgets.add(
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: ${farmer.name}'),
                    pw.Text(
                        'Total Area: ${farmer.getTotalHectaresFormatted()} hectare'),
                    pw.Text(
                        'Total Debt: ${numberFormat.format(debt.toInt())} Toman'),
                    pw.Text('Paid: ${numberFormat.format(paid.toInt())} Toman'),
                    pw.Text(
                        'Remaining: ${numberFormat.format(remaining.toInt())} Toman'),
                  ],
                ),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    // Share the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'report-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf',
    );
  }
}
