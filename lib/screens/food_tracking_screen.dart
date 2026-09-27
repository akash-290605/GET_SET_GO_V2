import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/food_service.dart';
import '../services/gemini_service.dart';
import '../services/theme_service.dart';
import '../models/food_models.dart';
import '../widgets/titan_ai_sheet.dart';

class FoodTrackingScreen extends StatefulWidget {
  const FoodTrackingScreen({super.key});

  @override
  State<FoodTrackingScreen> createState() => _FoodTrackingScreenState();
}

class _FoodTrackingScreenState extends State<FoodTrackingScreen> {
  final ImagePicker _picker = ImagePicker();

  void _scanFoodPhoto(MealType mealType) async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final foodItem = await GeminiService.instance.analyzeFoodPhoto(bytes, photo.name, mealType);
        await FoodService.instance.addFood(foodItem);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logged ${foodItem.name} (${foodItem.calories.toStringAsFixed(0)} kcal)!'),
              backgroundColor: ThemeService.primaryEmerald,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Photo pick error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foodService = FoodService.instance;

    return AnimatedBuilder(
      animation: foodService,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Food & Vision AI'),
            actions: [
              IconButton(
                icon: const Icon(Icons.water_drop_outlined, color: ThemeService.primaryCyan),
                tooltip: 'Log 250ml Water',
                onPressed: () => foodService.addWaterMl(250),
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: ThemeService.primaryCyan),
                tooltip: 'Dietary AI Coach',
                onPressed: () => TitanAiSheet.show(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Macro Rings & Target Dashboard
              _buildMacroDashboard(isDark, foodService),
              const SizedBox(height: 18),

              // Hydration Tracker Bar
              _buildHydrationBar(isDark, foodService),
              const SizedBox(height: 20),

              // Meal Slots
              _buildMealSection(MealType.breakfast, 'Breakfast', Icons.wb_sunny_outlined, isDark, foodService),
              const SizedBox(height: 14),
              _buildMealSection(MealType.lunch, 'Lunch', Icons.lunch_dining_outlined, isDark, foodService),
              const SizedBox(height: 14),
              _buildMealSection(MealType.dinner, 'Dinner', Icons.dinner_dining_outlined, isDark, foodService),
              const SizedBox(height: 14),
              _buildMealSection(MealType.snack, 'Snacks & Supplements', Icons.coffee_outlined, isDark, foodService),
              const SizedBox(height: 30),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.camera_alt, color: Colors.black),
            label: const Text('Scan Food Photo', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: ThemeService.primaryCyan,
            onPressed: () => _scanFoodPhoto(MealType.lunch),
          ),
        );
      },
    );
  }

  // 1. Macro Dashboard Card
  Widget _buildMacroDashboard(bool isDark, FoodService food) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0),
        ),
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
                  const Text('CALORIES REMAINING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  Text(
                    '${(food.macroTargets.calorieTarget - food.totalCalories).clamp(0, 9999).toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: ThemeService.primaryCyan),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('DAILY TARGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    '${food.macroTargets.calorieTarget.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calorie Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: food.calorieProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
              color: ThemeService.primaryCyan,
            ),
          ),
          const SizedBox(height: 18),

          // Protein, Carbs, Fats Split
          Row(
            children: [
              _macroMetric('Protein', '${food.totalProtein.toStringAsFixed(0)}g', '${food.macroTargets.proteinTargetGrams.toStringAsFixed(0)}g', food.proteinProgress, ThemeService.primaryEmerald, isDark),
              const SizedBox(width: 8),
              _macroMetric('Carbs', '${food.totalCarbs.toStringAsFixed(0)}g', '${food.macroTargets.carbsTargetGrams.toStringAsFixed(0)}g', food.carbsProgress, Colors.orangeAccent, isDark),
              const SizedBox(width: 8),
              _macroMetric('Fats', '${food.totalFat.toStringAsFixed(0)}g', '${food.macroTargets.fatTargetGrams.toStringAsFixed(0)}g', food.fatProgress, ThemeService.accentRose, isDark),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Hydration Bar
  Widget _buildHydrationBar(bool isDark, FoodService food) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: Color(0xFF38BDF8), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hydration Target', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      '${(food.todayWaterMl / 1000).toStringAsFixed(1)}L / ${(food.macroTargets.waterMlTarget / 1000).toStringAsFixed(1)}L',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: food.waterProgress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
                    color: const Color(0xFF38BDF8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF38BDF8), size: 28),
            onPressed: () => food.addWaterMl(250),
          ),
        ],
      ),
    );
  }

  // 3. Meal Slot Section with Food Items and Portion Multipliers
  Widget _buildMealSection(MealType type, String title, IconData icon, bool isDark, FoodService foodService) {
    final foods = foodService.getFoodsByMeal(type);
    final slotCalories = foods.fold(0.0, (s, f) => s + f.calories);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: ThemeService.primaryCyan),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  '${slotCalories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey),
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, size: 20),
                  tooltip: 'Scan Photo',
                  onPressed: () => _scanFoodPhoto(type),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: 'Add Manually',
                  onPressed: () => _showManualFoodModal(context, type),
                ),
              ],
            ),
          ),

          if (foods.isNotEmpty) const Divider(height: 1),

          ...foods.map((food) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF21262D) : const Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(food.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${food.calories.toStringAsFixed(0)} kcal  •  P: ${food.proteinGrams.toStringAsFixed(0)}g  C: ${food.carbsGrams.toStringAsFixed(0)}g  F: ${food.fatGrams.toStringAsFixed(0)}g',
                          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                        ),
                        if (food.healthAdvice.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('💡 ${food.healthAdvice}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: ThemeService.primaryEmerald)),
                          ),
                      ],
                    ),
                  ),

                  // Portion Stepper
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (food.servingQuantity > 0.5) {
                            foodService.updateFoodPortion(food.id, food.servingQuantity - 0.5);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF21262D) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.remove, size: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${food.servingQuantity}x',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          foodService.updateFoodPortion(food.id, food.servingQuantity + 0.5);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF21262D) : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 14),
                        ),
                      ),
                    ],
                  ),

                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () => foodService.deleteFood(food.id),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showManualFoodModal(BuildContext context, MealType mealType) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final proCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Log Food Item (${mealType.name.toUpperCase()})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Food Name (e.g. Scrambled Eggs)')),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: proCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)'))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: carbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)'))),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  final food = FoodItem(
                    id: 'food_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : 'Food Item',
                    calories: double.tryParse(calCtrl.text) ?? 200.0,
                    proteinGrams: double.tryParse(proCtrl.text) ?? 15.0,
                    carbsGrams: double.tryParse(carbCtrl.text) ?? 20.0,
                    fatGrams: double.tryParse(fatCtrl.text) ?? 5.0,
                    mealType: mealType,
                    loggedAt: DateTime.now(),
                  );
                  FoodService.instance.addFood(food);
                  Navigator.pop(ctx);
                },
                child: const Text('Save Food Item'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _macroMetric(String label, String current, String target, double progress, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1117) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(current, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            Text('of $target', style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: isDark ? const Color(0xFF21262D) : const Color(0xFFE2E8F0),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
