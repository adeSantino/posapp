import 'package:supabase_flutter/supabase_flutter.dart';

class RFIDService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Helper to get current user ID
  String? get _currentUserId => _supabase.auth.currentUser?.id;

  // Generic error handler
  void _handleError(dynamic e, String message) {
    if (e is AuthException) {
      throw Exception('$message: Authentication error - ${e.message}. Please ensure you are logged in.');
    } else if (e is PostgrestException) {
      if (e.code == '42501') { // RLS violation code
        throw Exception('$message: Permission denied (Row Level Security). Please check your Supabase RLS policies for the "rfid" table.');
      }
      throw Exception('$message: Database error - ${e.message}');
    }
    throw Exception('$message: An unexpected error occurred - $e');
  }

  // Register a new RFID card
  Future<Map<String, dynamic>> registerCard({
    required String employeeName,
    required String department,
    required int credit,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot register card.');
    }

    try {
      final cardData = {
        'employee_name': employeeName,
        'department': department,
        'credit': credit,
      };

      final response = await _supabase
          .from('rfid')
          .insert(cardData)
          .select()
          .single();

      return response;
    } catch (e) {
      _handleError(e, 'Failed to register RFID card');
      return {}; // Should not be reached due to throw
    }
  }

  // Get all RFID cards
  Future<List<Map<String, dynamic>>> getAllCards() async {
    try {
      final response = await _supabase
          .from('rfid')
          .select()
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _handleError(e, 'Failed to fetch RFID cards');
      return []; // Should not be reached due to throw
    }
  }

  // Get RFID card by ID
  Future<Map<String, dynamic>?> getCardById(int id) async {
    try {
      final response = await _supabase
          .from('rfid')
          .select()
          .eq('id', id)
          .single();

      return response;
    } catch (e) {
      _handleError(e, 'Failed to fetch RFID card by ID');
      return null; // Should not be reached due to throw
    }
  }

  // Update RFID card credit
  Future<void> updateCardCredit(int id, int newCredit) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot update card credit.');
    }
    try {
      await _supabase
          .from('rfid')
          .update({'credit': newCredit})
          .eq('id', id);
    } catch (e) {
      _handleError(e, 'Failed to update card credit');
    }
  }

  // Add credit to existing card
  Future<void> addCredit(int id, int creditToAdd) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot add credit.');
    }
    try {
      // First get current credit
      final currentCard = await getCardById(id);
      if (currentCard != null) {
        final currentCredit = currentCard['credit'] as int;
        final newCredit = currentCredit + creditToAdd;
        await updateCardCredit(id, newCredit);
      }
    } catch (e) {
      _handleError(e, 'Failed to add credit to card');
    }
  }

  // Deduct credit from card
  Future<void> deductCredit(int id, int creditToDeduct) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot deduct credit.');
    }
    try {
      // First get current credit
      final currentCard = await getCardById(id);
      if (currentCard != null) {
        final currentCredit = currentCard['credit'] as int;
        final newCredit = (currentCredit - creditToDeduct).clamp(0, double.infinity).toInt();
        await updateCardCredit(id, newCredit);
      }
    } catch (e) {
      _handleError(e, 'Failed to deduct credit from card');
    }
  }

  // Update card information
  Future<void> updateCard({
    required int id,
    required String employeeName,
    required String department,
    required int credit,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot update card.');
    }
    try {
      await _supabase
          .from('rfid')
          .update({
            'employee_name': employeeName,
            'department': department,
            'credit': credit,
          })
          .eq('id', id);
    } catch (e) {
      _handleError(e, 'Failed to update card');
    }
  }

  // Delete RFID card
  Future<void> deleteCard(int id) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot delete card.');
    }
    try {
      await _supabase.from('rfid').delete().eq('id', id);
    } catch (e) {
      _handleError(e, 'Failed to delete card');
    }
  }

  // Get cards by department
  Future<List<Map<String, dynamic>>> getCardsByDepartment(String department) async {
    try {
      final response = await _supabase
          .from('rfid')
          .select()
          .eq('department', department)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _handleError(e, 'Failed to fetch cards by department');
      return []; // Should not be reached due to throw
    }
  }

  // Get total credit across all cards
  Future<int> getTotalCredit() async {
    try {
      final response = await _supabase
          .from('rfid')
          .select('credit');

      int total = 0;
      for (var card in response as List) {
        total += card['credit'] as int;
      }
      return total;
    } catch (e) {
      _handleError(e, 'Failed to calculate total credit');
      return 0; // Should not be reached due to throw
    }
  }
}
