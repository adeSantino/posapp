import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

class ExcelService {
  // Generate and download card-only sales report Excel
  static Future<void> downloadCardSalesReport({
    required List<Map<String, dynamic>> cardOrders,
    required String reportTitle,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('Excel Service: Starting Excel generation with ${cardOrders.length} orders');
      
      // Save the Excel to device
      final filePath = await saveExcelToDevice(
        cardOrders: cardOrders,
        reportTitle: reportTitle,
        startDate: startDate,
        endDate: endDate,
      );
      
      print('Excel Service: Excel saved to device at: $filePath');
      print('Excel Service: Excel generation completed successfully');
    } catch (e) {
      print('Excel Service Error: $e');
      rethrow;
    }
  }

  // Save Excel to device storage
  static Future<String> saveExcelToDevice({
    required List<Map<String, dynamic>> cardOrders,
    required String reportTitle,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('Excel Service: Building Excel content...');
      
      // Create a new Excel file
      var excel = Excel.createExcel();
      
      // Remove the default sheet
      excel.delete('Sheet1');
      
      // Create a new sheet for the report
      Sheet sheet = excel['Card Sales Report'];
      
      // Calculate totals
      final totalCardOrders = cardOrders.length;
      final totalCardSales = cardOrders.fold(0, (sum, order) => sum + ((order['price'] as int?) ?? 0));
      
      print('Excel Service: Calculated totals - Orders: $totalCardOrders, Sales: $totalCardSales');

      // Add header information
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('FLUTTER POS SYSTEM');
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Card Table Sales Report');
      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Generated: ${DateTime.now().toString().split(' ')[0]}');
      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Time: ${DateTime.now().toString().split(' ')[1].substring(0, 8)}');
      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Report Period: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}');
      
      // Add summary information
      sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('SUMMARY');
      sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Total Card Orders:');
      sheet.cell(CellIndex.indexByString('B8')).value = IntCellValue(totalCardOrders);
      sheet.cell(CellIndex.indexByString('A9')).value = TextCellValue('Total Card Sales:');
      sheet.cell(CellIndex.indexByString('B9')).value = IntCellValue(totalCardSales);
      
      // Add table headers
      sheet.cell(CellIndex.indexByString('A11')).value = TextCellValue('Order ID');
      sheet.cell(CellIndex.indexByString('B11')).value = TextCellValue('Date & Time');
      sheet.cell(CellIndex.indexByString('C11')).value = TextCellValue('Employee');
      sheet.cell(CellIndex.indexByString('D11')).value = TextCellValue('Department');
      sheet.cell(CellIndex.indexByString('E11')).value = TextCellValue('Food Order');
      sheet.cell(CellIndex.indexByString('F11')).value = TextCellValue('Price');
      
      // Add order data
      int rowIndex = 12;
      print('Excel Service: Adding ${cardOrders.length} orders to Excel');
      
      for (int i = 0; i < cardOrders.length; i++) {
        var order = cardOrders[i];
        print('Excel Service: Processing order $i: $order');
        
        DateTime orderDate;
        try {
          orderDate = DateTime.parse(order['created_at'] ?? DateTime.now().toIso8601String());
        } catch (e) {
          orderDate = DateTime.now();
        }
        
        print('Excel Service: Adding row $rowIndex with data:');
        print('  - ID: ${order['id'] ?? 'N/A'}');
        print('  - Date: ${orderDate.day}/${orderDate.month}/${orderDate.year} ${orderDate.hour.toString().padLeft(2, '0')}:${orderDate.minute.toString().padLeft(2, '0')}');
        print('  - Employee: ${order['employee_name']?.toString() ?? 'N/A'}');
        print('  - Department: ${order['department']?.toString() ?? 'N/A'}');
        print('  - Food Order: ${order['food_order']?.toString() ?? 'N/A'}');
        print('  - Price: ${order['price'] ?? 0}');
        
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value = TextCellValue('#${order['id'] ?? 'N/A'}');
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value = TextCellValue('${orderDate.day}/${orderDate.month}/${orderDate.year} ${orderDate.hour.toString().padLeft(2, '0')}:${orderDate.minute.toString().padLeft(2, '0')}');
        sheet.cell(CellIndex.indexByString('C$rowIndex')).value = TextCellValue(order['employee_name']?.toString() ?? 'N/A');
        sheet.cell(CellIndex.indexByString('D$rowIndex')).value = TextCellValue(order['department']?.toString() ?? 'N/A');
        sheet.cell(CellIndex.indexByString('E$rowIndex')).value = TextCellValue(order['food_order']?.toString() ?? 'N/A');
        sheet.cell(CellIndex.indexByString('F$rowIndex')).value = IntCellValue(order['price'] ?? 0);
        
        rowIndex++;
      }
      
      print('Excel Service: Finished adding orders. Total rows added: ${rowIndex - 12}');
      
      // Add footer
      sheet.cell(CellIndex.indexByString('A${rowIndex + 2}')).value = TextCellValue('Report generated by Flutter POS System');
      sheet.cell(CellIndex.indexByString('A${rowIndex + 3}')).value = TextCellValue('Total Records: $totalCardOrders');

      print('Excel Service: Getting directory for saving...');
      // Get the Downloads directory for saving
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final fileName = 'Card_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${directory.path}/$fileName');
      
      print('Excel Service: Saving Excel to file...');
      // Save the Excel file
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
      }
      
      print('Excel Service: Excel saved successfully to: ${file.path}');
      return file.path;
    } catch (e) {
      print('Excel Service: Error in saveExcelToDevice: $e');
      rethrow;
    }
  }
}
