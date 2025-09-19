import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/pdf_service.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final _orderService = OrderService();
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getAllOrders();
      setState(() {
        _orders = orders;
        _filteredOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load orders: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _filterOrders() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        // Date filter
        if (_startDate != null || _endDate != null) {
          final orderDate = DateTime.parse(order['created_at']);
          if (_startDate != null && orderDate.isBefore(_startDate!)) {
            return false;
          }
          if (_endDate != null && orderDate.isAfter(_endDate!.add(Duration(days: 1)))) {
            return false;
          }
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          return order['employee_name'].toString().toLowerCase().contains(searchLower) ||
                 order['department'].toString().toLowerCase().contains(searchLower) ||
                 order['food_order'].toString().toLowerCase().contains(searchLower) ||
                 order['payment'].toString().toLowerCase().contains(searchLower);
        }

        return true;
      }).toList();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filterOrders();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _searchQuery = '';
    });
    _filterOrders();
  }

  double get _totalSales => _filteredOrders.fold(0.0, (sum, order) => sum + (order['price'] as int).toDouble());
  double get _cashSales => _filteredOrders.where((order) => order['payment'] == 'Cash').fold(0.0, (sum, order) => sum + (order['price'] as int).toDouble());
  double get _cardSales => _filteredOrders.where((order) => order['payment'] == 'Card').fold(0.0, (sum, order) => sum + (order['price'] as int).toDouble());
  int get _totalOrders => _filteredOrders.length;
  int get _cashOrders => _filteredOrders.where((order) => order['payment'] == 'Cash').length;
  int get _cardOrders => _filteredOrders.where((order) => order['payment'] == 'Card').length;

  List<Map<String, dynamic>> get _cardOrdersList => _filteredOrders.where((order) => order['payment'] == 'Card').toList();

      Future<void> _downloadCardSalesReport() async {
        if (_cardOrdersList.isEmpty) {
          _showErrorSnackBar('No card orders found to download');
          return;
        }

        try {
          final filePath = await PDFService.savePDFToDevice(
            cardOrders: _cardOrdersList,
            reportTitle: 'Card Sales Report',
            startDate: _startDate ?? DateTime.now().subtract(Duration(days: 30)),
            endDate: _endDate ?? DateTime.now(),
          );
          _showSuccessSnackBar('Card sales report downloaded to: $filePath');
        } catch (e) {
          _showErrorSnackBar('Failed to download report: $e');
        }
      }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text('Sales Report', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.download, color: Colors.white),
                onPressed: _downloadCardSalesReport,
                tooltip: 'Download Card Sales Report',
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadOrders,
              ),
            ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // First Row - Total Orders and Total Sales
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Orders',
                        _totalOrders.toString(),
                        Icons.receipt,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Total Sales',
                        '₱${_totalSales.toInt()}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Second Row - Cash and Card Breakdown
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'Cash Orders',
                        '${_cashOrders} (₱${_cashSales.toInt()})',
                        Icons.money,
                        Colors.green,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        'Card Orders',
                        '${_cardOrders} (₱${_cardSales.toInt()})',
                        Icons.credit_card,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filters
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Color(0xFF2C2C2C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _filterOrders();
                  },
                ),
                
                SizedBox(height: 12),
                
                // Date Range and Clear Filters
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: Icon(Icons.date_range, color: Colors.white),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'Select Date Range',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: Icon(Icons.clear, color: Colors.white),
                      label: Text('Clear', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Orders Tables
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : _filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No orders found',
                              style: TextStyle(color: Colors.grey, fontSize: 18),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Orders will appear here after they are placed',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            // Tab Bar with Print Button
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2C2C2C),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TabBar(
                                        indicator: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        labelColor: Colors.white,
                                        unselectedLabelColor: Colors.grey,
                                        tabs: [
                                          Tab(
                                            icon: Icon(Icons.money, size: 20),
                                            text: 'Cash Orders (${_cashOrders})',
                                          ),
                                          Tab(
                                            icon: Icon(Icons.credit_card, size: 20),
                                            text: 'Card Orders (${_cardOrders})',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: _downloadCardSalesReport,
                                        icon: Icon(Icons.download, color: Colors.white, size: 16),
                                        label: Text('Download Card Report', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            // Tab Views
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Cash Orders Table
                                  _buildOrdersTable('Cash'),
                                  // Card Orders Table
                                  _buildOrdersTable('Card'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable(String paymentType) {
    final orders = _filteredOrders.where((order) => order['payment'] == paymentType).toList();
    
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              paymentType == 'Cash' ? Icons.money_off : Icons.credit_card_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No $paymentType orders found',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Orders with $paymentType payment will appear here',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Color(0xFF2C2C2C)),
          dataRowColor: MaterialStateProperty.all(Color(0xFF1A1A1A)),
          columns: [
          DataColumn(
            label: Text(
              'Order ID',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Date & Time',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Employee',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Department',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Food Order',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Price',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        rows: orders.map((order) {
          final orderDate = DateTime.parse(order['created_at']);
          return DataRow(
            cells: [
              DataCell(
                Text(
                  '#${order['id']}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DataCell(
                Text(
                  '${orderDate.day}/${orderDate.month}/${orderDate.year}\n${orderDate.hour.toString().padLeft(2, '0')}:${orderDate.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  order['employee_name'] ?? 'N/A',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DataCell(
                Text(
                  order['department'] ?? 'N/A',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DataCell(
                Container(
                  width: 200,
                  child: Text(
                    order['food_order'] ?? 'N/A',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '₱${order['price']}',
                  style: TextStyle(
                    color: paymentType == 'Cash' ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
