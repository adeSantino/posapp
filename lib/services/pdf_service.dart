import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class PDFService {
  // Generate and download card-only sales report PDF
  static Future<void> downloadCardSalesReport({
    required List<Map<String, dynamic>> cardOrders,
    required String reportTitle,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('PDF Service: Starting PDF generation with ${cardOrders.length} orders');
      
      // Save the PDF to device
      final filePath = await savePDFToDevice(
        cardOrders: cardOrders,
        reportTitle: reportTitle,
        startDate: startDate,
        endDate: endDate,
      );
      
      print('PDF Service: PDF saved to device at: $filePath');
      
      // Print the PDF using the printing package
      final pdf = pw.Document();
      _buildPDFContent(pdf, cardOrders, reportTitle, startDate, endDate);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Card_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      
      print('PDF Service: PDF generation completed successfully');
    } catch (e) {
      print('PDF Service Error: $e');
      rethrow;
    }
  }

  // Save PDF to device storage
  static Future<String> savePDFToDevice({
    required List<Map<String, dynamic>> cardOrders,
    required String reportTitle,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('PDF Service: Building PDF content...');
      final pdf = pw.Document();
      _buildPDFContent(pdf, cardOrders, reportTitle, startDate, endDate);

      print('PDF Service: Getting directory for saving...');
      // Get the Downloads directory for saving
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final fileName = 'Card_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      
      print('PDF Service: Saving PDF to file...');
      // Save the PDF
      await file.writeAsBytes(await pdf.save());
      
      print('PDF Service: PDF saved successfully to: ${file.path}');
      return file.path;
    } catch (e) {
      print('PDF Service: Error in savePDFToDevice: $e');
      rethrow;
    }
  }

  // Helper method to build PDF content
  static void _buildPDFContent(
    pw.Document pdf,
    List<Map<String, dynamic>> cardOrders,
    String reportTitle,
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      print('PDF Service: Building PDF content with ${cardOrders.length} orders');
      
      // Calculate totals
      final totalCardOrders = cardOrders.length;
      final totalCardSales = cardOrders.fold(0, (sum, order) => sum + ((order['price'] as int?) ?? 0));
      
      print('PDF Service: Calculated totals - Orders: $totalCardOrders, Sales: $totalCardSales');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FLUTTER POS SYSTEM',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Card Table Sales Report (Last 15 Days)',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Generated: ${DateTime.now().toString().split(' ')[0]}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Time: ${DateTime.now().toString().split(' ')[1].substring(0, 8)}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Report Period
            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                children: [
                  pw.Text(
                    '📅 ',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(
                    'Last 15 Days: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Summary Cards
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.blue),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Total Card Orders',
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '$totalCardOrders',
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Total Card Sales',
                          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          '₱$totalCardSales',
                          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Orders Table Header
            pw.Text(
              'Card Table Orders (Last 15 Days)',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            // Orders Table
            if (cardOrders.isEmpty)
              pw.Container(
                padding: pw.EdgeInsets.all(20),
                child: pw.Center(
                  child: pw.Text(
                    'No card table orders found in the last 15 days',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: pw.FlexColumnWidth(1.0), // Order ID
                  1: pw.FlexColumnWidth(1.2), // Date & Time
                  2: pw.FlexColumnWidth(1.5), // Employee
                  3: pw.FlexColumnWidth(1.2), // Department
                  4: pw.FlexColumnWidth(4.0), // Food Order (wider)
                  5: pw.FlexColumnWidth(1.0), // Price
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Order ID',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Date & Time',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Employee',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Department',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Food Order',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Price',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  // Table Rows
                  ...cardOrders.map((order) {
                    DateTime orderDate;
                    try {
                      orderDate = DateTime.parse(order['created_at'] ?? DateTime.now().toIso8601String());
                    } catch (e) {
                      orderDate = DateTime.now();
                    }
                    
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '#${order['id'] ?? 'N/A'}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${orderDate.day}/${orderDate.month}/${orderDate.year}\n${orderDate.hour.toString().padLeft(2, '0')}:${orderDate.minute.toString().padLeft(2, '0')}',
                            style: pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            order['employee_name']?.toString() ?? 'N/A',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            order['department']?.toString() ?? 'N/A',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            order['food_order']?.toString() ?? 'N/A',
                            style: pw.TextStyle(fontSize: 8),
                            maxLines: 3,
                          ),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '₱${order['price'] ?? 0}',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),

            pw.SizedBox(height: 30),

            // Footer
            pw.Container(
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Report generated by Flutter POS System',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
    
    print('PDF Service: PDF content built successfully');
    } catch (e) {
      print('PDF Service: Error in _buildPDFContent: $e');
      rethrow;
    }
  }
}
