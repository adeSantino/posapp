import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Helper to get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // Generic error handler
  void _handleError(dynamic e, String message) {
    if (e is AuthException) {
      throw Exception('$message: Authentication error - ${e.message}. Please ensure you are logged in.');
    } else if (e is PostgrestException) {
      if (e.code == '42501') { // RLS violation code
        throw Exception('$message: Permission denied (Row Level Security). Please check your Supabase RLS policies for the "orders" table.');
      }
      throw Exception('$message: Database error - ${e.message}');
    }
    throw Exception('$message: An unexpected error occurred - $e');
  }

  // Create a new order
  Future<Map<String, dynamic>> createOrder({
    required String employeeName,
    required String department,
    required List<CartItem> cartItems,
    required String paymentMethod,
    required int totalPrice,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot create order.');
    }

    try {
      // Format food order as a readable string
      final foodOrderString = cartItems.map((item) => 
        '${item.quantity}x ${item.foodItem.foodName} (₱${item.foodItem.price} each)'
      ).join(', ');

      final orderData = {
        'employee_name': employeeName,
        'department': department,
        'food_order': foodOrderString,
        'price': totalPrice,
        'payment': paymentMethod,
      };

      final response = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      return response;
    } catch (e) {
      _handleError(e, 'Failed to create order');
      return {}; // Should not be reached due to throw
    }
  }

  // Get all orders
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _handleError(e, 'Failed to fetch orders');
      return []; // Should not be reached due to throw
    }
  }

  // Get orders by date range
  Future<List<Map<String, dynamic>>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _handleError(e, 'Failed to fetch orders by date range');
      return []; // Should not be reached due to throw
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>?> getOrderById(int id) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      _handleError(e, 'Failed to fetch order by ID');
      return null; // Should not be reached due to throw
    }
  }

  // Delete order
  Future<void> deleteOrder(int id) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot delete order.');
    }
    try {
      await _supabase.from('orders').delete().eq('id', id);
    } catch (e) {
      _handleError(e, 'Failed to delete order');
    }
  }
}
