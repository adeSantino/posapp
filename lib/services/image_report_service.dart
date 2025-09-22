import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class ImageReportService {
  // Generate and save card sales report as image
  static Future<void> downloadCardSalesReport({
    required List<Map<String, dynamic>> cardOrders,
    required String reportTitle,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('Image Report Service: Starting image generation with ${cardOrders.length} orders');
      
      // Save the image to device
      final filePath = await saveImageToDevice(
        cardOrders: cardOrders,
        reportTitle: reportTitle,
        startDate: startDate,
        endDate: endDate,
      );
      
      print('Image Report Service: Image saved to device at: $filePath');
      print('Image Report Service: Image generation completed successfully');
    } catch (e) {
      print('Image Report Service Error: $e');
      rethrow;
    }
  }

  // Save image to device storage
  static Future<String> saveImageToDevice({
    required List<Map<String, dynamic>> cardOrders,
    required String reportTitle,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('Image Report Service: Building image content...');
      
      // Calculate totals
      final totalCardOrders = cardOrders.length;
      final totalCardSales = cardOrders.fold(0, (sum, order) => sum + ((order['price'] as int?) ?? 0));
      
      print('Image Report Service: Calculated totals - Orders: $totalCardOrders, Sales: $totalCardSales');

      // Get the Downloads directory for saving
      final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final fileName = 'Card_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      
      print('Image Report Service: Saving image to file...');
      
      // Create the image data
      final imageData = await _generateReportImage(
        cardOrders: cardOrders,
        reportTitle: reportTitle,
        startDate: startDate,
        endDate: endDate,
        totalCardOrders: totalCardOrders,
        totalCardSales: totalCardSales,
      );
      
      // Save the image
      await file.writeAsBytes(imageData);
      
      print('Image Report Service: Image saved successfully to: ${file.path}');
      return file.path;
    } catch (e) {
      print('Image Report Service: Error in saveImageToDevice: $e');
      rethrow;
    }
  }

  // Generate the report image
  static Future<Uint8List> _generateReportImage({
    required List<Map<String, dynamic>> cardOrders,
    required String reportTitle,
    required DateTime startDate,
    required DateTime endDate,
    required int totalCardOrders,
    required int totalCardSales,
  }) async {
    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    // Set up the image size (A4-like proportions)
    const double width = 800;
    const double height = 1200;
    
    // Fill background with white
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), backgroundPaint);
    
    // Set up text styles
    const titleStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    
    const headerStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );
    
    const normalStyle = TextStyle(
      fontSize: 14,
      color: Colors.black,
    );
    
    const smallStyle = TextStyle(
      fontSize: 12,
      color: Colors.black,
    );
    
    double yPosition = 50;
    
    // Draw title
    final titleText = TextPainter(
      text: TextSpan(text: 'FLUTTER POS SYSTEM', style: titleStyle),
      textDirection: TextDirection.ltr,
    );
    titleText.layout();
    titleText.paint(canvas, Offset((width - titleText.width) / 2, yPosition));
    yPosition += 40;
    
    // Draw subtitle
    final subtitleText = TextPainter(
      text: TextSpan(text: 'Card Table Sales Report', style: headerStyle),
      textDirection: TextDirection.ltr,
    );
    subtitleText.layout();
    subtitleText.paint(canvas, Offset((width - subtitleText.width) / 2, yPosition));
    yPosition += 60;
    
    // Draw generation info
    final dateText = TextPainter(
      text: TextSpan(text: 'Generated: ${DateTime.now().toString().split(' ')[0]}', style: normalStyle),
      textDirection: TextDirection.ltr,
    );
    dateText.layout();
    dateText.paint(canvas, Offset(50, yPosition));
    yPosition += 30;
    
    final timeText = TextPainter(
      text: TextSpan(text: 'Time: ${DateTime.now().toString().split(' ')[1].substring(0, 8)}', style: normalStyle),
      textDirection: TextDirection.ltr,
    );
    timeText.layout();
    timeText.paint(canvas, Offset(50, yPosition));
    yPosition += 30;
    
    // Draw report period
    final periodText = TextPainter(
      text: TextSpan(text: 'Report Period: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}', style: normalStyle),
      textDirection: TextDirection.ltr,
    );
    periodText.layout();
    periodText.paint(canvas, Offset(50, yPosition));
    yPosition += 50;
    
    // Draw summary
    final summaryText = TextPainter(
      text: TextSpan(text: 'SUMMARY', style: headerStyle),
      textDirection: TextDirection.ltr,
    );
    summaryText.layout();
    summaryText.paint(canvas, Offset(50, yPosition));
    yPosition += 40;
    
    final totalOrdersText = TextPainter(
      text: TextSpan(text: 'Total Card Orders: $totalCardOrders', style: normalStyle),
      textDirection: TextDirection.ltr,
    );
    totalOrdersText.layout();
    totalOrdersText.paint(canvas, Offset(50, yPosition));
    yPosition += 30;
    
    final totalSalesText = TextPainter(
      text: TextSpan(text: 'Total Card Sales: ₱$totalCardSales', style: normalStyle),
      textDirection: TextDirection.ltr,
    );
    totalSalesText.layout();
    totalSalesText.paint(canvas, Offset(50, yPosition));
    yPosition += 50;
    
    // Draw table headers
    final headers = ['Order ID', 'Date & Time', 'Employee', 'Department', 'Food Order', 'Price'];
    final columnWidths = [80, 120, 100, 100, 200, 80];
    double xPosition = 50;
    
    // Draw header background
    final headerPaint = Paint()..color = Colors.grey[300]!;
    canvas.drawRect(Rect.fromLTWH(45, yPosition - 5, width - 90, 30), headerPaint);
    
    for (int i = 0; i < headers.length; i++) {
      final headerText = TextPainter(
        text: TextSpan(text: headers[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
        textDirection: TextDirection.ltr,
      );
      headerText.layout();
      headerText.paint(canvas, Offset(xPosition, yPosition));
      xPosition += columnWidths[i];
    }
    yPosition += 40;
    
    // Draw order data
    print('Image Report Service: Adding ${cardOrders.length} orders to image');
    
    for (int i = 0; i < cardOrders.length && yPosition < height - 100; i++) {
      var order = cardOrders[i];
      print('Image Report Service: Processing order $i: $order');
      
      DateTime orderDate;
      try {
        orderDate = DateTime.parse(order['created_at'] ?? DateTime.now().toIso8601String());
      } catch (e) {
        orderDate = DateTime.now();
      }
      
      xPosition = 50;
      
      // Draw row background (alternating colors)
      if (i % 2 == 0) {
        final rowPaint = Paint()..color = Colors.grey[100]!;
        canvas.drawRect(Rect.fromLTWH(45, yPosition - 5, width - 90, 25), rowPaint);
      }
      
      // Order ID
      final idText = TextPainter(
        text: TextSpan(text: '#${order['id'] ?? 'N/A'}', style: smallStyle),
        textDirection: TextDirection.ltr,
      );
      idText.layout();
      idText.paint(canvas, Offset(xPosition, yPosition));
      xPosition += columnWidths[0];
      
      // Date & Time
      final dateTimeText = TextPainter(
        text: TextSpan(text: '${orderDate.day}/${orderDate.month}/${orderDate.year}\n${orderDate.hour.toString().padLeft(2, '0')}:${orderDate.minute.toString().padLeft(2, '0')}', style: smallStyle),
        textDirection: TextDirection.ltr,
      );
      dateTimeText.layout();
      dateTimeText.paint(canvas, Offset(xPosition, yPosition));
      xPosition += columnWidths[1];
      
      // Employee
      final employeeText = TextPainter(
        text: TextSpan(text: order['employee_name']?.toString() ?? 'N/A', style: smallStyle),
        textDirection: TextDirection.ltr,
      );
      employeeText.layout();
      employeeText.paint(canvas, Offset(xPosition, yPosition));
      xPosition += columnWidths[2];
      
      // Department
      final departmentText = TextPainter(
        text: TextSpan(text: order['department']?.toString() ?? 'N/A', style: smallStyle),
        textDirection: TextDirection.ltr,
      );
      departmentText.layout();
      departmentText.paint(canvas, Offset(xPosition, yPosition));
      xPosition += columnWidths[3];
      
      // Food Order
      final foodOrderText = TextPainter(
        text: TextSpan(text: order['food_order']?.toString() ?? 'N/A', style: smallStyle),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      );
      foodOrderText.layout(maxWidth: columnWidths[4].toDouble());
      foodOrderText.paint(canvas, Offset(xPosition, yPosition));
      xPosition += columnWidths[4];
      
      // Price
      final priceText = TextPainter(
        text: TextSpan(text: '₱${order['price'] ?? 0}', style: smallStyle),
        textDirection: TextDirection.ltr,
      );
      priceText.layout();
      priceText.paint(canvas, Offset(xPosition, yPosition));
      
      yPosition += 30;
    }
    
    // Draw footer
    yPosition += 20;
    final footerText = TextPainter(
      text: TextSpan(text: 'Report generated by Flutter POS System', style: smallStyle),
      textDirection: TextDirection.ltr,
    );
    footerText.layout();
    footerText.paint(canvas, Offset(50, yPosition));
    
    yPosition += 20;
    final totalRecordsText = TextPainter(
      text: TextSpan(text: 'Total Records: $totalCardOrders', style: smallStyle),
      textDirection: TextDirection.ltr,
    );
    totalRecordsText.layout();
    totalRecordsText.paint(canvas, Offset(50, yPosition));
    
    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    print('Image Report Service: Image generated successfully');
    return byteData!.buffer.asUint8List();
  }
}
