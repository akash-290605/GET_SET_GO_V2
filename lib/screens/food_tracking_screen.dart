import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../db_helper.dart';
import '../models/food_models.dart';
import '../services/gemini_service.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';

class FoodTrackingScreen extends StatefulWidget {
  const FoodTrackingScreen({super.key});

  @override
  State<FoodTrackingScreen> createState() => _FoodTrackingScreenState();
}

class _FoodTrackingScreenState extends State<FoodTrackingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  
  bool _isAnalyzing = false;
  String _analysisStatus = '';
  List<FoodItemDetected> _detectedItems = [];
  String _selectedMealSlot = 'Lunch';
  String? _selectedImagePath;

  List<MealRecord> _mealRecords = [];
  bool _isLoadingHistory = true;
  String _historyFilter = 'Today'; // 'Today', 'This Week', 'This Month', 'All'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMealHistory();
    ProfileService.instance.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    ProfileService.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadMealHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final records = await DBHelper.instance.getMeals();
      if (mounted) {
        setState(() {
          _mealRecords = records;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  List<MealRecord> get _filteredMeals {
    final now = DateTime.now();
    return _mealRecords.where((meal) {
      if (_historyFilter == 'Today') {
        return meal.loggedAt.year == now.year &&
            meal.loggedAt.month == now.month &&
            meal.loggedAt.day == now.day;
      } else if (_historyFilter == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return meal.loggedAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            meal.loggedAt.isBefore(endOfWeek);
      } else if (_historyFilter == 'This Month') {
        return meal.loggedAt.year == now.year && meal.loggedAt.month == now.month;
      }
      return true;
    }).toList();
  }

  // Calculate today's totals
  Map<String, double> get _todayTotals {
    final now = DateTime.now();
    final todayMeals = _mealRecords.where((m) =>
        m.loggedAt.year == now.year &&
        m.loggedAt.month == now.month &&
        m.loggedAt.day == now.day);

    double cal = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;

    for (var m in todayMeals) {
      cal += m.totalCalories;
      protein += m.totalProtein;
      carbs += m.totalCarbs;
      fat += m.totalFat;
      fiber += m.totalFiber;
    }

    return {
      'calories': cal,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
    };
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _selectedImagePath = file.path;
        _isAnalyzing = true;
        _analysisStatus = 'Scanning plate & identifying ingredients...';
      });

      final result = await GeminiService.instance.analyzeFoodPhoto(
        imageBytes: bytes,
        mimeType: 'image/jpeg',
      );

      final items = (result['items'] as List?)?.cast<FoodItemDetected>() ?? [];

      if (mounted) {
        setState(() {
          _detectedItems = items;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing photo: $e'),
            backgroundColor: AppColors.accentRose,
          ),
        );
      }
    }
  }

  void _addCustomItem() {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameController = TextEditingController();
        final gramsController = TextEditingController(text: '100');
        final calController = TextEditingController(text: '150');
        final proController = TextEditingController(text: '10');
        final carbController = TextEditingController(text: '15');
        final fatController = TextEditingController(text: '5');
        final fiberController = TextEditingController(text: '2');

        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Quick Custom Food Entry', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Food Name (e.g. Boiled Egg, Paneer)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: gramsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Portion (Grams)', border: OutlineInputBorder(), suffixText: 'g'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: calController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Calories (kcal)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: proController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: carbController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: fatController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Fat (g)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final grams = double.tryParse(gramsController.text) ?? 100.0;
                final cal = double.tryParse(calController.text) ?? 0.0;
                final pro = double.tryParse(proController.text) ?? 0.0;
                final carb = double.tryParse(carbController.text) ?? 0.0;
                final fat = double.tryParse(fatController.text) ?? 0.0;
                final fiber = double.tryParse(fiberController.text) ?? 0.0;

                setState(() {
                  _detectedItems.add(
                    FoodItemDetected(
                      name: name,
                      portionGrams: grams,
                      calories: cal,
                      protein: pro,
                      carbs: carb,
                      fat: fat,
                      fiber: fiber,
                      base100gCalories: (cal / (grams > 0 ? grams : 100)) * 100,
                      base100gProtein: (pro / (grams > 0 ? grams : 100)) * 100,
                      base100gCarbs: (carb / (grams > 0 ? grams : 100)) * 100,
                      base100gFat: (fat / (grams > 0 ? grams : 100)) * 100,
                      base100gFiber: (fiber / (grams > 0 ? grams : 100)) * 100,
                      confidence: 'High Confidence',
                    ),
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add Item', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSouthIndianCatalogueModal() async {
    await StandardNutritionDatabase.init();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        String selectedCategory = 'All';
        final searchCtrl = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            final foods = StandardNutritionDatabase.searchFoods(searchQuery, category: selectedCategory);
            final categories = StandardNutritionDatabase.getCategories();

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle Bar
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.restaurant_menu_rounded, color: AppColors.accentGreen, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'South Indian Food & Snacks',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Dish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _showAddNewDishToDatabaseDialog(onDishAdded: () {
                            setModalState(() {});
                          }),
                        ),
                      ],
                    ),
                  ),

                  // Search Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search Dosa, Idli, Biryani, Vada, Coffee, etc...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  searchCtrl.clear();
                                  setModalState(() => searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                      onChanged: (val) => setModalState(() => searchQuery = val),
                    ),
                  ),

                  // Category Filter Chips
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, idx) {
                        final cat = categories[idx];
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: AppColors.accentGreen.withValues(alpha: 0.25),
                          onSelected: (_) => setModalState(() => selectedCategory = cat),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 12),

                  // Food Items List
                  Expanded(
                    child: foods.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.no_food_rounded, size: 48, color: AppColors.textMuted),
                              const SizedBox(height: 10),
                              Text('No dishes found for "$searchQuery"', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add This Custom Dish to Database'),
                                onPressed: () => _showAddNewDishToDatabaseDialog(
                                  prefilledName: searchQuery,
                                  onDishAdded: () => setModalState(() {}),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: foods.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final item = foods[idx];
                            return _buildCatalogueFoodTile(item, setModalState);
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogueFoodTile(StandardFoodEntry food, StateSetter setModalState) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: food.isCustom ? AppColors.accentPurple.withValues(alpha: 0.4) : theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            food.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        if (food.isCustom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentPurple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Custom', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accentPurple)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${food.category} • Serving: ${food.servingSize}', style: TextStyle(fontSize: 11.5, color: theme.hintColor)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (food.isCustom)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
                      tooltip: 'Delete custom food',
                      onPressed: () async {
                        await StandardNutritionDatabase.deleteCustomFood(food.id);
                        setModalState(() {});
                      },
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showPortionSelectAndAddDialog(food),
                    child: const Text('Add +', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Macro Row
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _buildMacroBadge('⚡ ${(food.caloriesPerServing).toStringAsFixed(0)} kcal', AppColors.accentAmber),
              _buildMacroBadge('🥩 ${(food.proteinPerServing).toStringAsFixed(1)}g Pro', AppColors.primary),
              _buildMacroBadge('🍞 ${(food.carbsPerServing).toStringAsFixed(1)}g Carb', AppColors.accentBlue),
              _buildMacroBadge('🥑 ${(food.fatPerServing).toStringAsFixed(1)}g Fat', AppColors.accentRose),
              if (food.fiberPerServing > 0)
                _buildMacroBadge('🌿 ${(food.fiberPerServing).toStringAsFixed(1)}g Fib', AppColors.accentGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  void _showPortionSelectAndAddDialog(StandardFoodEntry food) {
    double portionGrams = food.defaultGrams;
    final gramsCtrl = TextEditingController(text: portionGrams.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setPortionState) {
            final ratio = portionGrams / 100.0;
            final cal = (food.caloriesPer100g * ratio).toStringAsFixed(0);
            final pro = (food.proteinPer100g * ratio).toStringAsFixed(1);
            final carb = (food.carbsPer100g * ratio).toStringAsFixed(1);
            final fat = (food.fatPer100g * ratio).toStringAsFixed(1);
            final fib = (food.fiberPer100g * ratio).toStringAsFixed(1);

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text('Add "${food.name}"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Adjust portion to accurately match your meal:', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: gramsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Portion (Grams / ml)',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final v = double.tryParse(val);
                      if (v != null && v > 0) {
                        setPortionState(() => portionGrams = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quick Gram Presets
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [50, 100, 150, 200, 250, 300].map((g) {
                      final selected = portionGrams == g.toDouble();
                      return ChoiceChip(
                        label: Text('${g}g'),
                        selected: selected,
                        selectedColor: AppColors.accentGreen.withValues(alpha: 0.25),
                        onSelected: (_) {
                          setPortionState(() {
                            portionGrams = g.toDouble();
                            gramsCtrl.text = g.toString();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const Divider(height: 20),

                  // Calculated Macro Box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildPortionMetric('Calories', '$cal kcal', AppColors.accentAmber),
                        _buildPortionMetric('Protein', '${pro}g', AppColors.primary),
                        _buildPortionMetric('Carbs', '${carb}g', AppColors.accentBlue),
                        _buildPortionMetric('Fat', '${fat}g', AppColors.accentRose),
                        if (food.fiberPer100g > 0)
                          _buildPortionMetric('Fiber', '${fib}g', AppColors.accentGreen),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
                  onPressed: () {
                    final finalGrams = double.tryParse(gramsCtrl.text) ?? portionGrams;
                    final finalRatio = finalGrams / 100.0;

                    final detected = FoodItemDetected(
                      name: food.name,
                      portionGrams: finalGrams,
                      calories: double.parse((food.caloriesPer100g * finalRatio).toStringAsFixed(1)),
                      protein: double.parse((food.proteinPer100g * finalRatio).toStringAsFixed(1)),
                      carbs: double.parse((food.carbsPer100g * finalRatio).toStringAsFixed(1)),
                      fat: double.parse((food.fatPer100g * finalRatio).toStringAsFixed(1)),
                      fiber: double.parse((food.fiberPer100g * finalRatio).toStringAsFixed(1)),
                      base100gCalories: food.caloriesPer100g,
                      base100gProtein: food.proteinPer100g,
                      base100gCarbs: food.carbsPer100g,
                      base100gFat: food.fatPer100g,
                      base100gFiber: food.fiberPer100g,
                      confidence: 'High Confidence',
                    );

                    setState(() {
                      _detectedItems.add(detected);
                    });

                    Navigator.pop(ctx); // Close portion dialog
                    Navigator.pop(context); // Close bottom sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${food.name} (${finalGrams.toStringAsFixed(0)}g) to plate!'),
                        backgroundColor: AppColors.accentGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Add to Plate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPortionMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  void _showAddNewDishToDatabaseDialog({String? prefilledName, VoidCallback? onDishAdded}) {
    final nameCtrl = TextEditingController(text: prefilledName ?? '');
    String category = 'Breakfast';
    final servingCtrl = TextEditingController(text: '1 Plate (150g)');
    final gramsCtrl = TextEditingController(text: '150');
    final calCtrl = TextEditingController(text: '180');
    final proCtrl = TextEditingController(text: '6');
    final carbCtrl = TextEditingController(text: '28');
    final fatCtrl = TextEditingController(text: '5');
    final fiberCtrl = TextEditingController(text: '2');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: const Row(
                children: [
                  Icon(Icons.restaurant_rounded, color: AppColors.accentGreen),
                  SizedBox(width: 8),
                  Text('Add New Dish to Database', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Dish / Snack Name *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: StandardNutritionDatabase.getCategories()
                          .where((c) => c != 'All' && c != 'Custom Foods')
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: servingCtrl,
                            decoration: const InputDecoration(labelText: 'Serving Desc', hintText: 'e.g. 2 Pcs', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: gramsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Default Grams', suffixText: 'g', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: calCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Calories / 100g', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: proCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Protein (g)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: carbCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Carbs (g)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: fatCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Fat (g)', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fiberCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Fiber (g)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final defGrams = double.tryParse(gramsCtrl.text) ?? 100.0;
                    final cal100 = double.tryParse(calCtrl.text) ?? 150.0;
                    final pro100 = double.tryParse(proCtrl.text) ?? 5.0;
                    final carb100 = double.tryParse(carbCtrl.text) ?? 25.0;
                    final fat100 = double.tryParse(fatCtrl.text) ?? 3.0;
                    final fib100 = double.tryParse(fiberCtrl.text) ?? 1.0;

                    final newFood = StandardFoodEntry(
                      name: name,
                      category: category,
                      servingSize: servingCtrl.text.trim().isNotEmpty ? servingCtrl.text.trim() : '${defGrams.toStringAsFixed(0)}g',
                      defaultGrams: defGrams,
                      caloriesPer100g: cal100,
                      proteinPer100g: pro100,
                      carbsPer100g: carb100,
                      fatPer100g: fat100,
                      fiberPer100g: fib100,
                      isCustom: true,
                    );

                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);

                    await StandardNutritionDatabase.addCustomFood(newFood);
                    if (onDishAdded != null) onDishAdded();

                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Saved "$name" permanently into South Indian Food Database!'),
                        backgroundColor: AppColors.accentGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save to Database'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editItem(int index) {
    final item = _detectedItems[index];
    final nameController = TextEditingController(text: item.name);
    final gramsController = TextEditingController(text: item.portionGrams.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Edit Food Portion & Name', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Food Name / Type', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gramsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Portion (Grams)', border: OutlineInputBorder(), suffixText: 'g'),
              ),
              const SizedBox(height: 12),
              Text(
                'Note: Nutrition values automatically recalculate according to standard food densities.',
                style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                final newGrams = double.tryParse(gramsController.text) ?? item.portionGrams;
                if (newName.isNotEmpty) {
                  setState(() {
                    if (newName.toLowerCase() != item.name.toLowerCase()) {
                      _detectedItems[index] = _detectedItems[index].withRenamedType(newName, newGrams);
                    } else {
                      _detectedItems[index] = _detectedItems[index].withPortionGrams(newGrams);
                    }
                  });
                }
                Navigator.pop(ctx);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveMealRecord() async {
    if (_detectedItems.isEmpty) return;

    final meal = MealRecord(
      name: '$_selectedMealSlot (${_detectedItems.map((e) => e.name).join(', ')})',
      mealSlot: _selectedMealSlot,
      loggedAt: DateTime.now(),
      imagePath: _selectedImagePath,
      items: List.from(_detectedItems),
      isAiEstimated: true,
      notes: 'Photo scanned & AI estimated nutrition',
    );

    await DBHelper.instance.insertMeal(meal);
    await _loadMealHistory();

    if (mounted) {
      setState(() {
        _detectedItems.clear();
        _selectedImagePath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved $_selectedMealSlot (${meal.totalCalories.toStringAsFixed(0)} kcal) to your daily log!'),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _tabController.animateTo(1);
    }
  }

  Future<void> _deleteMealRecord(String id) async {
    await DBHelper.instance.deleteMeal(id);
    await _loadMealHistory();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal record deleted'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = ProfileService.instance.nutritionTarget;
    final totals = _todayTotals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition & Food AI', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt_rounded), text: 'AI Scanner & Log'),
            Tab(icon: Icon(Icons.restaurant_menu_rounded), text: 'Meal History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerTab(target, totals),
          _buildHistoryTab(target),
        ],
      ),
    );
  }

  Widget _buildScannerTab(DailyNutritionTarget target, Map<String, double> totals) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Daily Macro Progress Card
          _buildDailyMacroCard(target, totals),
          const SizedBox(height: 20),

          // Action Cards: Camera Scan & Manual Entry
          Text('Log Food with AI Vision', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  title: 'Scan Plate',
                  subtitle: 'Camera / Photo',
                  icon: Icons.camera_alt_rounded,
                  color: AppColors.primary,
                  onTap: () => _pickAndAnalyzeImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  title: 'Upload Image',
                  subtitle: 'From Gallery',
                  icon: Icons.photo_library_rounded,
                  color: AppColors.secondary,
                  onTap: () => _pickAndAnalyzeImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text(
                    'South Indian Catalogue (100+ Items)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _showSouthIndianCatalogueModal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text(
                    'Quick Custom',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: _addCustomItem,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scanning / AI Loading State
          if (_isAnalyzing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(_analysisStatus, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text('Recognizing multi-item foods, grams, & macro distributions...', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Detected Foods List & Adjustment Card
          if (_detectedItems.isNotEmpty) ...[
            _buildDetectionResultsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyMacroCard(DailyNutritionTarget target, Map<String, double> totals) {
    final theme = Theme.of(context);
    final calCurrent = totals['calories'] ?? 0;
    final calTarget = target.calorieTarget;
    final calPercent = (calTarget > 0 ? (calCurrent / calTarget) : 0.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TODAY’S NUTRITION INTAKE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.hintColor, letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${calCurrent.toStringAsFixed(0)} ', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                      Text('/ ${calTarget.toStringAsFixed(0)} kcal', style: TextStyle(fontSize: 14, color: theme.hintColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (calCurrent <= calTarget ? AppColors.accentGreen : AppColors.accentRose).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  calCurrent <= calTarget ? '${(calTarget - calCurrent).toStringAsFixed(0)} kcal left' : '${(calCurrent - calTarget).toStringAsFixed(0)} kcal over',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: calCurrent <= calTarget ? AppColors.accentGreen : AppColors.accentRose,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: calPercent,
              minHeight: 8,
              backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(calPercent >= 1.0 ? AppColors.accentRose : AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          // Macro breakdown rows
          Row(
            children: [
              Expanded(child: _buildMacroMiniBar('Protein', totals['protein'] ?? 0, target.proteinTargetGrams, AppColors.accentGreen, 'g')),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroMiniBar('Carbs', totals['carbs'] ?? 0, target.carbTargetGrams, AppColors.accentAmber, 'g')),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroMiniBar('Fat', totals['fat'] ?? 0, target.fatTargetGrams, AppColors.accentRose, 'g')),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroMiniBar('Fiber', totals['fiber'] ?? 0, target.fiberTargetGrams, AppColors.secondary, 'g')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroMiniBar(String label, double current, double target, Color color, String unit) {
    final pct = (target > 0 ? (current / target) : 0.0).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text('${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}$unit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: theme.hintColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionResultsCard() {
    final theme = Theme.of(context);
    double totalCal = 0;
    double totalPro = 0;
    double totalCarb = 0;
    double totalFat = 0;

    for (var item in _detectedItems) {
      totalCal += item.calories;
      totalPro += item.protein;
      totalCarb += item.carbs;
      totalFat += item.fat;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.accentAmber, size: 20),
                  const SizedBox(width: 8),
                  Text('Detected Foods (${_detectedItems.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Add another item',
                onPressed: _addCustomItem,
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.accentAmber),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'ESTIMATED NUTRITION (~kcal) • Optical estimate. Adjust portion grams below for exact precision.',
                    style: TextStyle(fontSize: 10.5, color: AppColors.accentAmber, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Meal slot selector
          Row(
            children: [
              const Text('Meal Slot: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Wrap(
                spacing: 6,
                children: ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((slot) {
                  final isSelected = _selectedMealSlot == slot;
                  return ChoiceChip(
                    label: Text(slot, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    onSelected: (val) {
                      if (val) setState(() => _selectedMealSlot = slot);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          const Divider(height: 24),

          // Items list with +/- Grams adjuster
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _detectedItems.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = _detectedItems[index];
              return _buildDetectedItemRow(item, index);
            },
          ),

          const Divider(height: 24),
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                '${totalCal.toStringAsFixed(0)} kcal | ${totalPro.toStringAsFixed(1)}g P | ${totalCarb.toStringAsFixed(1)}g C | ${totalFat.toStringAsFixed(1)}g F',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGlow, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Save & Log Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              label: Text('Log $_selectedMealSlot (${totalCal.toStringAsFixed(0)} kcal)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
              onPressed: _saveMealRecord,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedItemRow(FoodItemDetected item, int index) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Rename or edit',
                    onPressed: () => _editItem(index),
                  ),
                ],
              ),
              Text(
                '${item.calories.toStringAsFixed(0)} kcal • ${item.protein.toStringAsFixed(1)}g Protein • ${item.carbs.toStringAsFixed(1)}g Carbs • ${item.fat.toStringAsFixed(1)}g Fat',
                style: TextStyle(fontSize: 11.5, color: theme.hintColor),
              ),
            ],
          ),
        ),
        // Grams increment / decrement controls
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                final newGrams = (item.portionGrams - 10).clamp(10.0, 2000.0);
                setState(() {
                  _detectedItems[index] = item.withPortionGrams(newGrams);
                });
              },
            ),
            InkWell(
              onTap: () => _editItem(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${item.portionGrams.toStringAsFixed(0)}g', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                final newGrams = (item.portionGrams + 10).clamp(10.0, 2000.0);
                setState(() {
                  _detectedItems[index] = item.withPortionGrams(newGrams);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.accentRose),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                setState(() {
                  _detectedItems.removeAt(index);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryTab(DailyNutritionTarget target) {
    final theme = Theme.of(context);
    final meals = _filteredMeals;

    return Column(
      children: [
        // Filter Chips Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: theme.cardColor,
          child: Row(
            children: [
              const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Today', 'This Week', 'This Month', 'All'].map((filter) {
                      final isSelected = _historyFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(filter, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          onSelected: (val) {
                            if (val) setState(() => _historyFilter = filter);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Meal list
        Expanded(
          child: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : meals.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_rounded, size: 56, color: theme.hintColor.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text('No meals logged for $_historyFilter', style: TextStyle(color: theme.hintColor, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Scan or Log a Meal'),
                            onPressed: () => _tabController.animateTo(0),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index];
                        return _buildMealHistoryCard(meal);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMealHistoryCard(MealRecord meal) {
    final theme = Theme.of(context);
    final dateStr = '${meal.loggedAt.day}/${meal.loggedAt.month} ${meal.loggedAt.hour.toString().padLeft(2, '0')}:${meal.loggedAt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            meal.mealSlot == 'Breakfast'
                ? Icons.free_breakfast_rounded
                : meal.mealSlot == 'Lunch'
                    ? Icons.lunch_dining_rounded
                    : meal.mealSlot == 'Dinner'
                        ? Icons.dinner_dining_rounded
                        : Icons.fastfood_rounded,
            color: AppColors.primary,
          ),
        ),
        title: Row(
          children: [
            Text(meal.mealSlot, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${meal.totalCalories.toStringAsFixed(0)} kcal', style: const TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
        subtitle: Text('$dateStr • ${meal.items.length} items', style: TextStyle(fontSize: 12, color: theme.hintColor)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.accentRose),
          onPressed: () => _deleteMealRecord(meal.id),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat('Protein', '${meal.totalProtein.toStringAsFixed(1)}g', AppColors.accentGreen),
                    _buildMiniStat('Carbs', '${meal.totalCarbs.toStringAsFixed(1)}g', AppColors.accentAmber),
                    _buildMiniStat('Fat', '${meal.totalFat.toStringAsFixed(1)}g', AppColors.accentRose),
                    _buildMiniStat('Fiber', '${meal.totalFiber.toStringAsFixed(1)}g', AppColors.secondary),
                  ],
                ),
                const Divider(height: 16),
                ...meal.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.name} (${item.portionGrams.toStringAsFixed(0)}g)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('${item.calories.toStringAsFixed(0)} kcal', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
