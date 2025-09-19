import 'package:supabase_flutter/supabase_flutter.dart';

class RFIDService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all RFID users
  Future<List<Map<String, dynamic>>> getRFIDUsers() async {
    try {
      final response = await _supabase
          .from('rfid_users')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch RFID users: $e');
    }
  }

  // Add new RFID user
  Future<Map<String, dynamic>> addRFIDUser(Map<String, dynamic> user) async {
    try {
      final response = await _supabase
          .from('rfid_users')
          .insert(user)
          .select()
          .single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to add RFID user: $e');
    }
  }

  // Update RFID user credit
  Future<void> updateCredit(int id, int newCredit) async {
    try {
      await _supabase
          .from('rfid_users')
          .update({'Credit': newCredit})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to update credit: $e');
    }
  }
}