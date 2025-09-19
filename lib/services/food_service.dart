import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_item.dart';

class FoodService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get all foods
  Future<List<FoodItem>> getAllFoods() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final response = await _supabase
          .from('foods')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FoodItem.fromJson(json))
          .toList();
    } catch (e) {
      if (e.toString().contains('row-level security')) {
        throw Exception('Permission denied. Please check your database policies or contact administrator.');
      }
      throw Exception('Failed to fetch foods: $e');
    }
  }

  // Get foods by category
  Future<List<FoodItem>> getFoodsByCategory(String category) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final response = await _supabase
          .from('foods')
          .select()
          .eq('category', category)
          .eq('available_food', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FoodItem.fromJson(json))
          .toList();
    } catch (e) {
      if (e.toString().contains('row-level security')) {
        throw Exception('Permission denied. Please check your database policies or contact administrator.');
      }
      throw Exception('Failed to fetch foods by category: $e');
    }
  }

  // Get available foods only
  Future<List<FoodItem>> getAvailableFoods() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final response = await _supabase
          .from('foods')
          .select()
          .eq('available_food', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FoodItem.fromJson(json))
          .toList();
    } catch (e) {
      if (e.toString().contains('row-level security')) {
        throw Exception('Permission denied. Please check your database policies or contact administrator.');
      }
      throw Exception('Failed to fetch available foods: $e');
    }
  }

  // Add new food
  Future<FoodItem> addFood(FoodItem food) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final response = await _supabase
          .from('foods')
          .insert({
            'food_name': food.foodName,
            'price': food.price,
            'available_food': food.availableFood,
            'category': food.category,
          })
          .select()
          .single();

      return FoodItem.fromJson(response);
    } catch (e) {
      if (e.toString().contains('row-level security') || e.toString().contains('42501')) {
        throw Exception('Permission denied. Please check your database Row Level Security policies. You may need to create policies to allow insert operations on the foods table.');
      }
      if (e.toString().contains('duplicate key')) {
        throw Exception('A food item with this name already exists.');
      }
      throw Exception('Failed to add food: $e');
    }
  }

  // Update food
  Future<FoodItem> updateFood(FoodItem food) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final response = await _supabase
          .from('foods')
          .update({
            'food_name': food.foodName,
            'price': food.price,
            'available_food': food.availableFood,
            'category': food.category,
          })
          .eq('id', food.id!)
          .select()
          .single();

      return FoodItem.fromJson(response);
    } catch (e) {
      if (e.toString().contains('row-level security') || e.toString().contains('42501')) {
        throw Exception('Permission denied. Please check your database Row Level Security policies.');
      }
      throw Exception('Failed to update food: $e');
    }
  }

  // Delete food
  Future<void> deleteFood(int id) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      await _supabase
          .from('foods')
          .delete()
          .eq('id', id);
    } catch (e) {
      if (e.toString().contains('row-level security') || e.toString().contains('42501')) {
        throw Exception('Permission denied. Please check your database Row Level Security policies.');
      }
      throw Exception('Failed to delete food: $e');
    }
  }

  // Toggle food availability
  Future<FoodItem> toggleFoodAvailability(int id, bool available) async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final response = await _supabase
          .from('foods')
          .update({'available_food': available})
          .eq('id', id)
          .select()
          .single();

      return FoodItem.fromJson(response);
    } catch (e) {
      if (e.toString().contains('row-level security') || e.toString().contains('42501')) {
        throw Exception('Permission denied. Please check your database Row Level Security policies.');
      }
      throw Exception('Failed to toggle food availability: $e');
    }
  }

  // Get all categories
  Future<List<String>> getCategories() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final response = await _supabase
          .from('foods')
          .select('category')
          .order('category');

      final categories = (response as List)
          .map((json) => json['category'] as String)
          .toSet()
          .toList();

      return categories;
    } catch (e) {
      if (e.toString().contains('row-level security')) {
        throw Exception('Permission denied. Please check your database policies or contact administrator.');
      }
      throw Exception('Failed to fetch categories: $e');
    }
  }

  // Get food count by category
  Future<Map<String, int>> getFoodCountByCategory() async {
    try {
      if (!isAuthenticated) {
        throw Exception('User not authenticated. Please log in first.');
      }

      final response = await _supabase
          .from('foods')
          .select('category, available_food');

      final Map<String, int> categoryCount = {};
      
      for (var item in response) {
        final category = item['category'] as String;
        final available = item['available_food'] as bool;
        
        if (available) {
          categoryCount[category] = (categoryCount[category] ?? 0) + 1;
        }
      }

      return categoryCount;
    } catch (e) {
      if (e.toString().contains('row-level security')) {
        throw Exception('Permission denied. Please check your database policies or contact administrator.');
      }
      throw Exception('Failed to fetch food count by category: $e');
    }
  }
}