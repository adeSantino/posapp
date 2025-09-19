import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crypto/crypto.dart' as crypto;

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get user profile from users table
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  // Create user profile in users table
  Future<Map<String, dynamic>?> createUserProfile({
    required String email,
    required String name,
    required String password,
  }) async {
    try {
      // Hash the password using SHA-256
      final hashedPassword = crypto.sha256.convert(utf8.encode(password)).toString();

      final response = await _supabase
          .from('users')
          .insert({
            'email': email,
            'name': name,
            'password': hashedPassword,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>?> updateUserProfile({
    required String email,
    String? name,
    String? password,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (password != null) updateData['password'] = password;
      
      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('email', email)
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return null;
    }
  }

  // Get all users (for admin purposes)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }
}
