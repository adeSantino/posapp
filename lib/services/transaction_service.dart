import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Record cash payment
  Future<void> recordCashPayment({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String cashierName,
  }) async {
    try {
      await _supabase.from('cash_transactions').insert({
        'items': items,
        'total_amount': totalAmount,
        'cashier_name': cashierName,
        'payment_type': 'cash',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to record cash payment: $e');
    }
  }

  // Record RFID payment
  Future<void> recordRFIDPayment({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String cashierName,
    required int rfidUserId,
    required String employeeName,
  }) async {
    try {
      await _supabase.from('rfid_transactions').insert({
        'items': items,
        'total_amount': totalAmount,
        'cashier_name': cashierName,
        'rfid_user_id': rfidUserId,
        'employee_name': employeeName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to record RFID payment: $e');
    }
  }
}