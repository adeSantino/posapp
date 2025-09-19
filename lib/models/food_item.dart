class FoodItem {
  final int? id;
  final String foodName;
  final int price;
  final bool availableFood;
  final String category;
  final DateTime? createdAt;
  final dynamic icon; // Add icon field

  FoodItem({
    this.id,
    required this.foodName,
    required this.price,
    required this.availableFood,
    required this.category,
    this.createdAt,
    this.icon,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      foodName: json['food_name'] ?? '',
      price: json['price'] ?? 0,
      availableFood: json['available_food'] ?? true,
      category: json['category'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food_name': foodName,
      'price': price,
      'available_food': availableFood,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  FoodItem copyWith({
    int? id,
    String? foodName,
    int? price,
    bool? availableFood,
    String? category,
    DateTime? createdAt,
    dynamic icon,
  }) {
    return FoodItem(
      id: id ?? this.id,
      foodName: foodName ?? this.foodName,
      price: price ?? this.price,
      availableFood: availableFood ?? this.availableFood,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
    );
  }

  // Helper method to get icon based on category
  String getIconForCategory() {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return 'coffee';
      case 'pasta':
        return 'restaurant';
      case 'soups':
        return 'soup_kitchen';
      case 'sushi':
        return 'set_meal';
      case 'main course':
        return 'restaurant_menu';
      case 'desserts':
        return 'cake';
      case 'drinks':
        return 'local_drink';
      case 'alcohol':
        return 'wine_bar';
      default:
        return 'restaurant';
    }
  }
}