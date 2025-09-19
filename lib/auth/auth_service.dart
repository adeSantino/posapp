import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword(
    String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email, 
      password: password
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword(
    String email, String password, String name) async {

    debugPrint('Attempting to sign up user: $email');
    // First, sign up with Supabase Auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    debugPrint('Sign up response: ${authResponse.user != null ? 'success' : 'failed'}');
    // If successful, also create profile in users table
    if (authResponse.user != null) {
      debugPrint('Creating user profile in users table');
      final profileResult = await _userService.createUserProfile(
        email: email,
        name: name,
        password: password,
      );
      if (profileResult == null) {
        debugPrint('Failed to create user profile in database');
      } else {
        debugPrint('User profile created successfully');
      }
    }

    return authResponse;
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Get current user email
  String? getCurrentUserEmail() {
    final user = getCurrentUser();
    return user?.email;
  }

  // Get current user name
  String? getCurrentUserName() {
    final user = getCurrentUser();
    return user?.userMetadata?['name'] ?? user?.email;
  }

  // Get user profile from users table
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final email = getCurrentUserEmail();
    if (email != null) {
      return await _userService.getUserProfile(email);
    }
    return null;
  }
}