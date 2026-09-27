import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_models.dart';

class FoodService extends ChangeNotifier {
  static final FoodService _instance = FoodService._internal();
  static FoodService get instance => _instance;
  FoodService._internal();

  List<FoodItem> _todayFoods = [];
  double _todayWaterMl = 2250.0;
  MacroTargets _macroTargets = MacroTargets();

  List<FoodItem> get todayFoods => _todayFoods;
  double get todayWaterMl => _todayWaterMl;
  MacroTargets get macroTargets => _macroTargets;

  double get totalCalories => _todayFoods.fold(0.0, (s, f) => s + f.calories);
  double get totalProtein => _todayFoods.fold(0.0, (s, f) => s + f.proteinGrams);
  double get totalCarbs => _todayFoods.fold(0.0, (s, f) => s + f.carbsGrams);
  double get totalFat => _todayFoods.fold(0.0, (s, f) => s + f.fatGrams);

  double get calorieProgress => _macroTargets.calorieTarget > 0 ? (totalCalories / _macroTargets.calorieTarget).clamp(0.0, 1.5) : 0.0;
  double get proteinProgress => _macroTargets.proteinTargetGrams > 0 ? (totalProtein / _macroTargets.proteinTargetGrams).clamp(0.0, 1.5) : 0.0;
  double get carbsProgress => _macroTargets.carbsTargetGrams > 0 ? (totalCarbs / _macroTargets.carbsTargetGrams).clamp(0.0, 1.5) : 0.0;
  double get fatProgress => _macroTargets.fatTargetGrams > 0 ? (totalFat / _macroTargets.fatTargetGrams).clamp(0.0, 1.5) : 0.0;
  double get waterProgress => _macroTargets.waterMlTarget > 0 ? (_todayWaterMl / _macroTargets.waterMlTarget).clamp(0.0, 1.5) : 0.0;

  List<FoodItem> getFoodsByMeal(MealType type) =>
      _todayFoods.where((f) => f.mealType == type).toList();

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('food_logged_today');
      if (savedJson != null) {
        final List<dynamic> decoded = json.decode(savedJson);
        _todayFoods = decoded.map((e) => FoodItem.fromMap(Map<String, dynamic>.from(e))).toList();
      } else {
        _todayFoods = _getDefaultLoggedFoods();
        await _saveFoods();
      }

      _todayWaterMl = prefs.getDouble('food_water_ml_today') ?? 2250.0;

      final targetJson = prefs.getString('food_macro_targets');
      if (targetJson != null) {
        _macroTargets = MacroTargets.fromMap(Map<String, dynamic>.from(json.decode(targetJson)));
      }
    } catch (e) {
      debugPrint('FoodService init error: $e');
      _todayFoods = _getDefaultLoggedFoods();
    }
    notifyListeners();
  }

  Future<void> addFood(FoodItem food) async {
    _todayFoods.insert(0, food);
    notifyListeners();
    await _saveFoods();
  }

  Future<void> updateFood(FoodItem updated) async {
    final idx = _todayFoods.indexWhere((f) => f.id == updated.id);
    if (idx != -1) {
      _todayFoods[idx] = updated;
      notifyListeners();
      await _saveFoods();
    }
  }

  Future<void> updateFoodPortion(String id, double newServingQuantity) async {
    final idx = _todayFoods.indexWhere((f) => f.id == id);
    if (idx != -1) {
      final old = _todayFoods[idx];
      final ratio = newServingQuantity / (old.servingQuantity > 0 ? old.servingQuantity : 1.0);
      _todayFoods[idx] = old.copyWith(
        servingQuantity: newServingQuantity,
        calories: old.calories * ratio,
        proteinGrams: old.proteinGrams * ratio,
        carbsGrams: old.carbsGrams * ratio,
        fatGrams: old.fatGrams * ratio,
        portionGrams: old.portionGrams * ratio,
      );
      notifyListeners();
      await _saveFoods();
    }
  }

  Future<void> deleteFood(String id) async {
    _todayFoods.removeWhere((f) => f.id == id);
    notifyListeners();
    await _saveFoods();
  }

  Future<void> addWaterMl(double ml) async {
    _todayWaterMl = (_todayWaterMl + ml).clamp(0.0, 10000.0);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('food_water_ml_today', _todayWaterMl);
  }

  Future<void> updateTargets(MacroTargets targets) async {
    _macroTargets = targets;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('food_macro_targets', json.encode(targets.toMap()));
  }

  Future<void> _saveFoods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_todayFoods.map((f) => f.toMap()).toList());
      await prefs.setString('food_logged_today', encoded);
    } catch (e) {
      debugPrint('Error saving foods: $e');
    }
  }

  List<FoodItem> _getDefaultLoggedFoods() {
    final now = DateTime.now();
    return [
      FoodItem(
        id: 'food_1',
        name: 'Rolled Oats with Whey & Berries',
        calories: 420.0,
        proteinGrams: 32.0,
        carbsGrams: 54.0,
        fatGrams: 8.0,
        portionGrams: 200.0,
        servingUnit: 'bowl',
        servingQuantity: 1.0,
        mealType: MealType.breakfast,
        loggedAt: DateTime(now.year, now.month, now.day, 8, 30),
        confidenceScore: '98%',
        healthAdvice: 'High complex carbs and fast-absorbing protein ideal for morning recovery.',
      ),
      FoodItem(
        id: 'food_2',
        name: 'Grilled Chicken Breast with Brown Rice',
        calories: 560.0,
        proteinGrams: 48.0,
        carbsGrams: 62.0,
        fatGrams: 10.0,
        portionGrams: 300.0,
        servingUnit: 'plate',
        servingQuantity: 1.0,
        mealType: MealType.lunch,
        loggedAt: DateTime(now.year, now.month, now.day, 13, 15),
        confidenceScore: '96%',
        healthAdvice: 'Lean protein heavy meal providing steady amino acid delivery.',
      ),
      FoodItem(
        id: 'food_3',
        name: 'Greek Yogurt with Almonds',
        calories: 210.0,
        proteinGrams: 18.0,
        carbsGrams: 14.0,
        fatGrams: 9.0,
        portionGrams: 150.0,
        servingUnit: 'cup',
        servingQuantity: 1.0,
        mealType: MealType.snack,
        loggedAt: DateTime(now.year, now.month, now.day, 17, 0),
        confidenceScore: '94%',
        healthAdvice: 'Rich in probiotics and slow-digesting casein.',
      ),
    ];
  }
}
