import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/food_service.dart';
import '../data/categories_data.dart';

class FoodManagementPage extends StatefulWidget {
  const FoodManagementPage({super.key});

  @override
  State<FoodManagementPage> createState() => _FoodManagementPageState();
}

class _FoodManagementPageState extends State<FoodManagementPage> {
  final FoodService _foodService = FoodService();
  List<FoodItem> _foods = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadFoods();
    _loadCategories();
  }

  Future<void> _loadFoods() async {
    setState(() => _isLoading = true);
    try {
      final foods = await _foodService.getAllFoods();
      setState(() {
        _foods = foods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load foods: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      // Use categories from the sidebar data
      final sidebarCategories = CategoriesData.categories.map((cat) => cat['name'] as String).toList();
      final dbCategories = await _foodService.getCategories();
      
      // Combine sidebar categories with database categories and remove duplicates
      final allCategories = {...sidebarCategories, ...dbCategories}.toList();
      allCategories.sort();
      
      setState(() {
        _categories = ['All', ...allCategories];
      });
    } catch (e) {
      // If database fails, use only sidebar categories
      final sidebarCategories = CategoriesData.categories.map((cat) => cat['name'] as String).toList();
      setState(() {
        _categories = ['All', ...sidebarCategories];
      });
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

  Future<void> _deleteFood(FoodItem food) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2C2C2C),
        title: Text('Delete Food', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${food.foodName}"?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _foodService.deleteFood(food.id!);
        _showSuccessSnackBar('Food deleted successfully');
        _loadFoods();
      } catch (e) {
        _showErrorSnackBar('Failed to delete food: $e');
      }
    }
  }

  Future<void> _toggleAvailability(FoodItem food) async {
    try {
      await _foodService.toggleFoodAvailability(food.id!, !food.availableFood);
      _showSuccessSnackBar('Food availability updated');
      _loadFoods();
    } catch (e) {
      _showErrorSnackBar('Failed to update availability: $e');
    }
  }

  void _showAddEditFoodDialog({FoodItem? food}) {
    showDialog(
      context: context,
      builder: (context) => AddEditFoodDialog(
        food: food,
        categories: _categories.where((c) => c != 'All').toList(),
        onSaved: () {
          _loadFoods();
          _loadCategories();
        },
      ),
    );
  }

  List<FoodItem> get _filteredFoods {
    if (_selectedCategory == 'All' || _selectedCategory.isEmpty) {
      return _foods;
    }
    return _foods.where((food) => 
      food.category.toLowerCase() == _selectedCategory.toLowerCase()
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text('Food Management', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadFoods,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Filter by Category:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        style: TextStyle(color: Colors.white),
                        dropdownColor: Color(0xFF2C2C2C),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Food List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : _filteredFoods.isEmpty
                    ? Center(
                        child: Text(
                          'No foods found',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _filteredFoods.length,
                        itemBuilder: (context, index) {
                          final food = _filteredFoods[index];
                          return Card(
                            color: Color(0xFF2C2C2C),
                            margin: EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: food.availableFood 
                                    ? Colors.green 
                                    : Colors.red,
                                child: Icon(
                                  food.availableFood 
                                      ? Icons.check 
                                      : Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                food.foodName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Category: ${food.category}',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'Price: ₱${food.price}',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'Status: ${food.availableFood ? "Available" : "Unavailable"}',
                                    style: TextStyle(
                                      color: food.availableFood 
                                          ? Colors.green 
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      food.availableFood 
                                          ? Icons.visibility_off 
                                          : Icons.visibility,
                                      color: food.availableFood 
                                          ? Colors.orange 
                                          : Colors.green,
                                    ),
                                    onPressed: () => _toggleAvailability(food),
                                    tooltip: food.availableFood 
                                        ? 'Mark as Unavailable' 
                                        : 'Mark as Available',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _showAddEditFoodDialog(food: food),
                                    tooltip: 'Edit Food',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteFood(food),
                                    tooltip: 'Delete Food',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditFoodDialog(),
        backgroundColor: Colors.green,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class AddEditFoodDialog extends StatefulWidget {
  final FoodItem? food;
  final List<String> categories;
  final VoidCallback onSaved;

  const AddEditFoodDialog({
    super.key,
    this.food,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<AddEditFoodDialog> createState() => _AddEditFoodDialogState();
}

class _AddEditFoodDialogState extends State<AddEditFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _foodService = FoodService();
  
  String _selectedCategory = '';
  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.food != null) {
      _nameController.text = widget.food!.foodName;
      _priceController.text = widget.food!.price.toString();
      _selectedCategory = widget.food!.category;
      _isAvailable = widget.food!.availableFood;
    } else if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveFood() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final food = FoodItem(
        id: widget.food?.id,
        foodName: _nameController.text.trim(),
        price: int.parse(_priceController.text),
        availableFood: _isAvailable,
        category: _selectedCategory,
      );

      if (widget.food == null) {
        await _foodService.addFood(food);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Food added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _foodService.updateFood(food);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Food updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop();
      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save food: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF2C2C2C),
      title: Text(
        widget.food == null ? 'Add New Food' : 'Edit Food',
        style: TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Food Name',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Color(0xFF1A1A1A),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter food name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (₱)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Color(0xFF1A1A1A),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory.isEmpty ? null : _selectedCategory,
                    isExpanded: true,
                    style: TextStyle(color: Colors.white),
                    dropdownColor: Color(0xFF2C2C2C),
                    icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                    hint: Text(
                      'Select Category',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    items: widget.categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Available:',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(width: 16),
                  Switch(
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() {
                        _isAvailable = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveFood,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(widget.food == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
