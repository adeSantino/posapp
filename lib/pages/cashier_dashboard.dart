import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';
import '../services/food_service.dart';
import '../data/categories_data.dart';
import '../widgets/order_confirmation_modal.dart';
import 'food_management_page.dart';
import 'sales_report_page.dart';
import 'card_registration_page.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  final _authService = AuthService();
  final _foodService = FoodService();
  List<CartItem> _cartItems = [];
  List<FoodItem> _foods = [];
  List<FoodItem> _allFoods = []; // Store all foods for filtering
  Map<String, int> _categoryCounts = {};
  bool _isLoading = true;
  String _selectedPaymentMethod = "Cash";
  String _currentTable = "Table 5";
  String _currentCustomer = "Leslie K.";
  String _selectedCategory = "All"; // Track selected category
  
  // Get categories from separate data file
  List<Map<String, dynamic>> get _categories => CategoriesData.categories;

  // Calculate totals from actual cart items
  double get _subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get _total => _subtotal; // No tax applied

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _loadCategoryCounts();
  }

  Future<void> _loadFoods() async {
    try {
      final foods = await _foodService.getAvailableFoods();
      setState(() {
        _allFoods = foods; // Store all foods
        _foods = foods; // Initially show all foods
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load foods: $e');
    }
  }

  Future<void> _loadCategoryCounts() async {
    try {
      final counts = await _foodService.getFoodCountByCategory();
      setState(() {
        _categoryCounts = counts;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load category counts: $e');
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

  void _navigateToFoodManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FoodManagementPage()),
    ).then((_) {
      // Refresh data when returning from food management
      _loadFoods();
      _loadCategoryCounts();
    });
  }

  void _navigateToSalesReport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SalesReportPage()),
    );
  }

  void _navigateToCardRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CardRegistrationPage()),
    );
  }

  // Add food item to cart
  void _addToCart(FoodItem food) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.foodItem.id == food.id,
      );
      
      if (existingItemIndex != -1) {
        // If item already exists, increase quantity
        _cartItems[existingItemIndex] = CartItem(
          foodItem: food,
          quantity: _cartItems[existingItemIndex].quantity + 1,
        );
      } else {
        // If item doesn't exist, add new item
        _cartItems.add(CartItem(foodItem: food, quantity: 1));
      }
    });
    
    _showSuccessSnackBar('${food.foodName} added to cart');
  }

  // Remove food item from cart
  void _removeFromCart(FoodItem food) {
    setState(() {
      final existingItemIndex = _cartItems.indexWhere(
        (item) => item.foodItem.id == food.id,
      );
      
      if (existingItemIndex != -1) {
        if (_cartItems[existingItemIndex].quantity > 1) {
          // Decrease quantity
          _cartItems[existingItemIndex] = CartItem(
            foodItem: food,
            quantity: _cartItems[existingItemIndex].quantity - 1,
          );
        } else {
          // Remove item completely
          _cartItems.removeAt(existingItemIndex);
        }
      }
    });
  }

  // Get quantity of item in cart
  int _getCartQuantity(FoodItem food) {
    final existingItem = _cartItems.firstWhere(
      (item) => item.foodItem.id == food.id,
      orElse: () => CartItem(foodItem: food, quantity: 0),
    );
    return existingItem.quantity;
  }

  // Clear entire cart
  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
    _showSuccessSnackBar('Cart cleared');
  }

  // Place order
  void _placeOrder() {
    if (_cartItems.isEmpty) {
      _showErrorSnackBar('Cart is empty. Add items before placing order.');
      return;
    }

    // Show order confirmation modal
    showDialog(
      context: context,
      builder: (context) => OrderConfirmationModal(
        cartItems: _cartItems,
        paymentMethod: _selectedPaymentMethod,
        total: _total,
        onOrderConfirmed: () {
          _clearCart();
        },
      ),
    );
  }

  // Filter foods by category
  void _filterByCategory(String categoryName) {
    setState(() {
      _selectedCategory = categoryName;
      if (categoryName == "All") {
        _foods = _allFoods;
      } else {
        _foods = _allFoods.where((food) => 
          food.category.toLowerCase() == categoryName.toLowerCase()
        ).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      body: Column(
        children: [
          // Header
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                children: [
                Text(
                  "Ins POS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 40),
                  Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search",
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20),
                Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                 Text(
                      _currentTable,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                                 Text(
                      _currentCustomer,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                                   ),
                                 ),
                                ],
                              ),
                SizedBox(width: 10),
                Icon(Icons.edit, color: Colors.red, size: 20),
                SizedBox(width: 20),
                // Sales Report Button
                ElevatedButton.icon(
                  onPressed: _navigateToSalesReport,
                  icon: Icon(Icons.analytics, color: Colors.white),
                  label: Text("Sales Report", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Card Registration Button
                ElevatedButton.icon(
                  onPressed: _navigateToCardRegistration,
                  icon: Icon(Icons.credit_card, color: Colors.white),
                  label: Text("Card Registration", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                SizedBox(width: 12),
                // Food Management Button
                ElevatedButton.icon(
                  onPressed: _navigateToFoodManagement,
                  icon: Icon(Icons.restaurant_menu, color: Colors.white),
                  label: Text("Food Management", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    ),
                  ),
                ],
            ),
          ),
          
          // Main Content Row
          Expanded(
            child: Row(
              children: [
                // Left Sidebar - Categories
                Container(
                  width: 200,
                  color: Color(0xFF2C2C2C),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text(
                              "Categories",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                            Spacer(),
                            if (_selectedCategory != "All")
                              GestureDetector(
                                onTap: () => _filterByCategory("All"),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Clear",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _categories.length + 1, // +1 for "All" option
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // "All" category option
                              final totalItems = _allFoods.length;
                              final isSelected = _selectedCategory == "All";
                              return Container(
                                margin: EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.orange : Color(0xFF4A4A4A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.all_inclusive, color: Colors.white, size: 24),
                                  title: Text(
                                    "All",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "$totalItems items",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  onTap: () {
                                    _filterByCategory("All");
                                  },
                                ),
                              );
                            }
                            
                            final category = _categories[index - 1];
                            final itemCount = _categoryCounts[category["name"]] ?? 0;
                            final isSelected = _selectedCategory == category["name"];
                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.orange : category["color"],
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                              ),
                              child: ListTile(
                                leading: Icon(category["icon"], color: Colors.white, size: 24),
                                title: Text(
                                  category["name"],
                                  style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  "$itemCount items",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () {
                                  _filterByCategory(category["name"]);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Content Area - Menu Items
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: _isLoading
                        ? Center(child: CircularProgressIndicator(color: Colors.white))
                        : _foods.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.restaurant, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      "No food items available",
                                      style: TextStyle(color: Colors.grey, fontSize: 18),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Add food items in Food Management",
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _navigateToFoodManagement,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text("Manage Food Items"),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  childAspectRatio: 1.2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: _foods.length,
                          itemBuilder: (context, index) {
                                  final food = _foods[index];
                                  final cartQuantity = _getCartQuantity(food);
                                  return GestureDetector(
                                    onTap: () => _addToCart(food),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xFF2C2C2C),
                                        borderRadius: BorderRadius.circular(12),
                                        border: cartQuantity > 0 
                                            ? Border.all(color: Colors.green, width: 2)
                                            : null,
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(8),
                                            child: Text(
                                              "Click to Add",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  food.foodName,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  "₱${food.price}",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: food.availableFood ? Colors.green : Colors.red,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    food.availableFood ? "Available" : "Unavailable",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _removeFromCart(food),
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[700],
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.remove, color: Colors.white, size: 16),
                                                  ),
                                                ),
                                                Text(
                                                  "$cartQuantity",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => _addToCart(food),
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[700],
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.add, color: Colors.white, size: 16),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                ),
                
                // Right Sidebar - Order Summary
                  Container(
                  width: 350,
                  color: Color(0xFF2C2C2C),
                    child: Column(
                      children: [
                      // Cart Header
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          border: Border(bottom: BorderSide(color: Colors.grey[600]!)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Cart (${_cartItems.length} items)",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_cartItems.isNotEmpty)
                              GestureDetector(
                                onTap: _clearCart,
                                child: Icon(
                                  Icons.clear_all,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      // Cart Items
                      Expanded(
                        child: _cartItems.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      "Cart is empty",
                                      style: TextStyle(color: Colors.grey, fontSize: 18),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Click on food items to add them",
                                      style: TextStyle(color: Colors.grey, fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: _cartItems.length,
                                itemBuilder: (context, index) {
                                  final cartItem = _cartItems[index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1A1A1A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[600]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                cartItem.foodItem.foodName,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                "₱${cartItem.foodItem.price} each",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _removeFromCart(cartItem.foodItem),
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.remove, color: Colors.white, size: 16),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "${cartItem.quantity}",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _addToCart(cartItem.foodItem),
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(Icons.add, color: Colors.white, size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      
                      // Summary
                      Container(
                        padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "₱${_total.toInt()}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                            SizedBox(height: 20),
                            
                            // Payment Methods
                            Text(
                              "Payment Method",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildPaymentMethod("Cash", Icons.attach_money, _selectedPaymentMethod == "Cash"),
                                _buildPaymentMethod("Card", Icons.credit_card, _selectedPaymentMethod == "Card"),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // Place Order Button
                        SizedBox(
                          width: double.infinity,
                              height: 50,
                          child: ElevatedButton(
                                onPressed: _cartItems.isEmpty ? null : _placeOrder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _cartItems.isEmpty ? Colors.grey : Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _cartItems.isEmpty ? "Cart is Empty" : "Place Order",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
      ),
    );
  }


  Widget _buildPaymentMethod(String method, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : Colors.grey[700],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(
            method,
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }

}