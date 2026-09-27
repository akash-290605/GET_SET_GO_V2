import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FoodItemDetected {
  String id;
  String name;
  double portionGrams;
  String unit;
  double calories;
  double protein;
  double carbohydrates;
  double fat;
  double fiber;
  double sugar;
  double sodiumMg;
  String confidence; // e.g. 'High Confidence', 'Estimated from Photo'
  double base100gCalories;
  double base100gProtein;
  double base100gCarbs;
  double base100gFat;
  double base100gFiber;

  FoodItemDetected({
    String? id,
    required this.name,
    required this.portionGrams,
    this.unit = 'g',
    required this.calories,
    required this.protein,
    double? carbs,
    double? carbohydrates,
    required this.fat,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.sodiumMg = 0.0,
    this.confidence = 'High Confidence',
    double? base100gCalories,
    double? base100gProtein,
    double? base100gCarbs,
    double? base100gFat,
    double? base100gFiber,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        carbohydrates = carbohydrates ?? carbs ?? 0.0,
        base100gCalories = base100gCalories ?? (portionGrams > 0 ? (calories / portionGrams) * 100 : calories),
        base100gProtein = base100gProtein ?? (portionGrams > 0 ? (protein / portionGrams) * 100 : protein),
        base100gCarbs = base100gCarbs ?? (portionGrams > 0 ? ((carbohydrates ?? carbs ?? 0.0) / portionGrams) * 100 : (carbohydrates ?? carbs ?? 0.0)),
        base100gFat = base100gFat ?? (portionGrams > 0 ? (fat / portionGrams) * 100 : fat),
        base100gFiber = base100gFiber ?? (portionGrams > 0 ? (fiber / portionGrams) * 100 : fiber);

  double get carbs => carbohydrates;

  FoodItemDetected withPortionGrams(double newGrams) {
    if (newGrams <= 0) newGrams = 1;
    final ratio = newGrams / 100.0;
    return FoodItemDetected(
      id: id,
      name: name,
      portionGrams: newGrams,
      unit: unit,
      calories: double.parse((base100gCalories * ratio).toStringAsFixed(1)),
      protein: double.parse((base100gProtein * ratio).toStringAsFixed(1)),
      carbohydrates: double.parse((base100gCarbs * ratio).toStringAsFixed(1)),
      fat: double.parse((base100gFat * ratio).toStringAsFixed(1)),
      fiber: double.parse((base100gFiber * ratio).toStringAsFixed(1)),
      sugar: sugar,
      sodiumMg: sodiumMg,
      confidence: confidence,
      base100gCalories: base100gCalories,
      base100gProtein: base100gProtein,
      base100gCarbs: base100gCarbs,
      base100gFat: base100gFat,
      base100gFiber: base100gFiber,
    );
  }

  FoodItemDetected withRenamedType(String newName, double newGrams) {
    final density = StandardNutritionDatabase.getDensityFor(newName);
    final ratio = newGrams / 100.0;
    return FoodItemDetected(
      id: id,
      name: newName,
      portionGrams: newGrams,
      unit: unit,
      calories: double.parse((density['calories']! * ratio).toStringAsFixed(1)),
      protein: double.parse((density['protein']! * ratio).toStringAsFixed(1)),
      carbohydrates: double.parse((density['carbs']! * ratio).toStringAsFixed(1)),
      fat: double.parse((density['fat']! * ratio).toStringAsFixed(1)),
      fiber: double.parse((density['fiber']! * ratio).toStringAsFixed(1)),
      sugar: sugar,
      sodiumMg: sodiumMg,
      confidence: 'High Confidence',
      base100gCalories: density['calories']!,
      base100gProtein: density['protein']!,
      base100gCarbs: density['carbs']!,
      base100gFat: density['fat']!,
      base100gFiber: density['fiber']!,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'portionGrams': portionGrams,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodiumMg': sodiumMg,
      'confidence': confidence,
      'base100gCalories': base100gCalories,
      'base100gProtein': base100gProtein,
      'base100gCarbs': base100gCarbs,
      'base100gFat': base100gFat,
      'base100gFiber': base100gFiber,
    };
  }

  factory FoodItemDetected.fromMap(Map<String, dynamic> map) {
    return FoodItemDetected(
      id: map['id']?.toString(),
      name: map['name'] ?? 'Food',
      portionGrams: (map['portionGrams'] as num?)?.toDouble() ?? 100.0,
      unit: map['unit'] ?? 'g',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (map['carbohydrates'] as num?)?.toDouble() ?? (map['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (map['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (map['sugar'] as num?)?.toDouble() ?? 0.0,
      sodiumMg: (map['sodiumMg'] as num?)?.toDouble() ?? 0.0,
      confidence: map['confidence']?.toString() ?? 'High Confidence',
      base100gCalories: (map['base100gCalories'] as num?)?.toDouble(),
      base100gProtein: (map['base100gProtein'] as num?)?.toDouble(),
      base100gCarbs: (map['base100gCarbs'] as num?)?.toDouble(),
      base100gFat: (map['base100gFat'] as num?)?.toDouble(),
      base100gFiber: (map['base100gFiber'] as num?)?.toDouble(),
    );
  }
}

class MealRecord {
  String id;
  String name;
  String mealSlot; // 'Breakfast', 'Lunch', 'Dinner', 'Snack'
  DateTime loggedAt;
  String? imagePath;
  List<FoodItemDetected> items;
  bool isAiEstimated;
  String notes;

  MealRecord({
    String? id,
    required this.name,
    required this.mealSlot,
    required this.loggedAt,
    this.imagePath,
    required this.items,
    this.isAiEstimated = true,
    this.notes = '',
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  double get totalCalories => items.fold(0.0, (sum, i) => sum + i.calories);
  double get totalProtein => items.fold(0.0, (sum, i) => sum + i.protein);
  double get totalCarbs => items.fold(0.0, (sum, i) => sum + i.carbohydrates);
  double get totalFat => items.fold(0.0, (sum, i) => sum + i.fat);
  double get totalFiber => items.fold(0.0, (sum, i) => sum + i.fiber);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mealSlot': mealSlot,
      'loggedAt': loggedAt.toIso8601String(),
      'imagePath': imagePath,
      'items': jsonEncode(items.map((i) => i.toMap()).toList()),
      'isAiEstimated': isAiEstimated ? 1 : 0,
      'notes': notes,
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'totalFiber': totalFiber,
    };
  }

  factory MealRecord.fromMap(Map<String, dynamic> map) {
    List<FoodItemDetected> itemsList = [];
    if (map['items'] != null) {
      if (map['items'] is String) {
        try {
          final decoded = jsonDecode(map['items']) as List;
          itemsList = decoded.map((i) => FoodItemDetected.fromMap(i)).toList();
        } catch (_) {}
      } else if (map['items'] is List) {
        itemsList = (map['items'] as List).map((i) => FoodItemDetected.fromMap(i)).toList();
      }
    }

    return MealRecord(
      id: map['id']?.toString(),
      name: map['name'] ?? 'Meal',
      mealSlot: map['mealSlot'] ?? 'Lunch',
      loggedAt: map['loggedAt'] != null ? (DateTime.tryParse(map['loggedAt']) ?? DateTime.now()) : DateTime.now(),
      imagePath: map['imagePath'],
      items: itemsList,
      isAiEstimated: map['isAiEstimated'] == 1 || map['isAiEstimated'] == true,
      notes: map['notes'] ?? '',
    );
  }
}

class DailyNutritionTarget {
  double calorieTarget;
  double proteinTarget;
  double carbTarget;
  double fatTarget;
  double fiberTarget;

  DailyNutritionTarget({
    required this.calorieTarget,
    double? proteinTarget,
    double? proteinTargetGrams,
    double? carbTarget,
    double? carbTargetGrams,
    double? fatTarget,
    double? fatTargetGrams,
    double? fiberTarget,
    double? fiberTargetGrams,
  })  : proteinTarget = proteinTarget ?? proteinTargetGrams ?? 140.0,
        carbTarget = carbTarget ?? carbTargetGrams ?? 250.0,
        fatTarget = fatTarget ?? fatTargetGrams ?? 65.0,
        fiberTarget = fiberTarget ?? fiberTargetGrams ?? 30.0;

  double get proteinTargetGrams => proteinTarget;
  double get carbTargetGrams => carbTarget;
  double get fatTargetGrams => fatTarget;
  double get fiberTargetGrams => fiberTarget;

  Map<String, dynamic> toMap() {
    return {
      'calorieTarget': calorieTarget,
      'proteinTarget': proteinTarget,
      'carbTarget': carbTarget,
      'fatTarget': fatTarget,
      'fiberTarget': fiberTarget,
    };
  }

  factory DailyNutritionTarget.fromMap(Map<String, dynamic> map) {
    return DailyNutritionTarget(
      calorieTarget: (map['calorieTarget'] as num?)?.toDouble() ?? 2200.0,
      proteinTarget: (map['proteinTarget'] as num?)?.toDouble() ?? 140.0,
      carbTarget: (map['carbTarget'] as num?)?.toDouble() ?? 250.0,
      fatTarget: (map['fatTarget'] as num?)?.toDouble() ?? 65.0,
      fiberTarget: (map['fiberTarget'] as num?)?.toDouble() ?? 30.0,
    );
  }
}

class StandardFoodEntry {
  final String id;
  String name;
  String category;
  String servingSize;
  double defaultGrams;
  double caloriesPer100g;
  double proteinPer100g;
  double carbsPer100g;
  double fatPer100g;
  double fiberPer100g;
  bool isCustom;

  StandardFoodEntry({
    String? id,
    required this.name,
    required this.category,
    this.servingSize = '100g',
    this.defaultGrams = 100.0,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.fiberPer100g = 0.0,
    this.isCustom = false,
  }) : id = id ?? name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  double get caloriesPerServing => double.parse(((caloriesPer100g * defaultGrams) / 100).toStringAsFixed(1));
  double get proteinPerServing => double.parse(((proteinPer100g * defaultGrams) / 100).toStringAsFixed(1));
  double get carbsPerServing => double.parse(((carbsPer100g * defaultGrams) / 100).toStringAsFixed(1));
  double get fatPerServing => double.parse(((fatPer100g * defaultGrams) / 100).toStringAsFixed(1));
  double get fiberPerServing => double.parse(((fiberPer100g * defaultGrams) / 100).toStringAsFixed(1));

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'servingSize': servingSize,
      'defaultGrams': defaultGrams,
      'caloriesPer100g': caloriesPer100g,
      'proteinPer100g': proteinPer100g,
      'carbsPer100g': carbsPer100g,
      'fatPer100g': fatPer100g,
      'fiberPer100g': fiberPer100g,
      'isCustom': isCustom ? 1 : 0,
    };
  }

  factory StandardFoodEntry.fromMap(Map<String, dynamic> map) {
    return StandardFoodEntry(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      category: map['category'] ?? 'Breakfast',
      servingSize: map['servingSize'] ?? '100g',
      defaultGrams: (map['defaultGrams'] as num?)?.toDouble() ?? 100.0,
      caloriesPer100g: (map['caloriesPer100g'] as num?)?.toDouble() ?? 150.0,
      proteinPer100g: (map['proteinPer100g'] as num?)?.toDouble() ?? 5.0,
      carbsPer100g: (map['carbsPer100g'] as num?)?.toDouble() ?? 25.0,
      fatPer100g: (map['fatPer100g'] as num?)?.toDouble() ?? 3.0,
      fiberPer100g: (map['fiberPer100g'] as num?)?.toDouble() ?? 1.0,
      isCustom: map['isCustom'] == 1 || map['isCustom'] == true,
    );
  }
}

class StandardNutritionDatabase {
  static const String _customFoodsPrefKey = 'gsg_custom_foods_database_v3';
  static final List<StandardFoodEntry> _customFoods = [];
  static bool _isLoaded = false;

  static final List<StandardFoodEntry> _builtInFoods = [
    // --- 1. SOUTH INDIAN BREAKFAST ---
    StandardFoodEntry(name: 'Plain Steamed Idli (2 Pcs)', category: 'Breakfast', servingSize: '2 Pieces (100g)', defaultGrams: 100, caloriesPer100g: 130.0, proteinPer100g: 5.5, carbsPer100g: 26.0, fatPer100g: 0.5, fiberPer100g: 1.5),
    StandardFoodEntry(name: 'Ghee Podi Idli (Mini)', category: 'Breakfast', servingSize: '1 Plate (150g)', defaultGrams: 150, caloriesPer100g: 195.0, proteinPer100g: 6.2, carbsPer100g: 27.0, fatPer100g: 7.5, fiberPer100g: 2.0),
    StandardFoodEntry(name: 'Rava Idli (2 Pcs)', category: 'Breakfast', servingSize: '2 Pieces (120g)', defaultGrams: 120, caloriesPer100g: 165.0, proteinPer100g: 4.8, carbsPer100g: 29.0, fatPer100g: 3.8, fiberPer100g: 1.8),
    StandardFoodEntry(name: 'Thatte Idli (Plate Idli)', category: 'Breakfast', servingSize: '1 Large (120g)', defaultGrams: 120, caloriesPer100g: 135.0, proteinPer100g: 5.0, carbsPer100g: 27.0, fatPer100g: 0.8, fiberPer100g: 1.6),
    StandardFoodEntry(name: 'Crispy Plain Dosa', category: 'Breakfast', servingSize: '1 Dosa (90g)', defaultGrams: 90, caloriesPer100g: 170.0, proteinPer100g: 4.0, carbsPer100g: 30.0, fatPer100g: 4.0, fiberPer100g: 1.2),
    StandardFoodEntry(name: 'Masala Dosa (Potato Stuffed)', category: 'Breakfast', servingSize: '1 Dosa (160g)', defaultGrams: 160, caloriesPer100g: 190.0, proteinPer100g: 4.5, carbsPer100g: 31.0, fatPer100g: 6.0, fiberPer100g: 2.5),
    StandardFoodEntry(name: 'Ghee Roast Dosa', category: 'Breakfast', servingSize: '1 Dosa (120g)', defaultGrams: 120, caloriesPer100g: 240.0, proteinPer100g: 4.2, carbsPer100g: 30.0, fatPer100g: 12.0, fiberPer100g: 1.2),
    StandardFoodEntry(name: 'Onion Rava Dosa', category: 'Breakfast', servingSize: '1 Dosa (130g)', defaultGrams: 130, caloriesPer100g: 210.0, proteinPer100g: 4.5, carbsPer100g: 33.0, fatPer100g: 7.2, fiberPer100g: 2.1),
    StandardFoodEntry(name: 'Pesarattu (Green Gram Dosa)', category: 'Breakfast', servingSize: '1 Dosa (110g)', defaultGrams: 110, caloriesPer100g: 155.0, proteinPer100g: 8.5, carbsPer100g: 24.0, fatPer100g: 3.2, fiberPer100g: 4.0),
    StandardFoodEntry(name: 'Adai (Multi-Lentil Protein Dosa)', category: 'Breakfast', servingSize: '1 Dosa (120g)', defaultGrams: 120, caloriesPer100g: 185.0, proteinPer100g: 9.0, carbsPer100g: 28.0, fatPer100g: 4.5, fiberPer100g: 4.5),
    StandardFoodEntry(name: 'Set Dosa (Sponge Dosa - 2 pcs)', category: 'Breakfast', servingSize: '2 Pieces (140g)', defaultGrams: 140, caloriesPer100g: 150.0, proteinPer100g: 4.2, carbsPer100g: 29.0, fatPer100g: 2.0, fiberPer100g: 1.4),
    StandardFoodEntry(name: 'Medu Vada (Crispy Lentil Fritter)', category: 'Breakfast', servingSize: '1 Piece (50g)', defaultGrams: 50, caloriesPer100g: 275.0, proteinPer100g: 8.0, carbsPer100g: 28.0, fatPer100g: 15.0, fiberPer100g: 3.5),
    StandardFoodEntry(name: 'Ven Pongal (Ghee Moong Dal Rice)', category: 'Breakfast', servingSize: '1 Cup (180g)', defaultGrams: 180, caloriesPer100g: 180.0, proteinPer100g: 5.5, carbsPer100g: 27.0, fatPer100g: 6.2, fiberPer100g: 2.2),
    StandardFoodEntry(name: 'Rava Upma (Semolina Veg Upma)', category: 'Breakfast', servingSize: '1 Cup (160g)', defaultGrams: 160, caloriesPer100g: 145.0, proteinPer100g: 3.8, carbsPer100g: 26.0, fatPer100g: 3.5, fiberPer100g: 2.0),
    StandardFoodEntry(name: 'Semiya Upma (Vermicelli Upma)', category: 'Breakfast', servingSize: '1 Cup (150g)', defaultGrams: 150, caloriesPer100g: 150.0, proteinPer100g: 3.5, carbsPer100g: 27.0, fatPer100g: 3.4, fiberPer100g: 1.5),
    StandardFoodEntry(name: 'Poori with Potato Masala (2 pcs)', category: 'Breakfast', servingSize: '2 Poori + Masala (220g)', defaultGrams: 220, caloriesPer100g: 245.0, proteinPer100g: 4.8, carbsPer100g: 35.0, fatPer100g: 10.5, fiberPer100g: 2.5),
    StandardFoodEntry(name: 'Appam (Kerala Hopper)', category: 'Breakfast', servingSize: '2 Pieces (100g)', defaultGrams: 100, caloriesPer100g: 120.0, proteinPer100g: 2.2, carbsPer100g: 24.0, fatPer100g: 1.8, fiberPer100g: 1.0),
    StandardFoodEntry(name: 'Kerala Puttu (Steamed Rice Cylinder)', category: 'Breakfast', servingSize: '1 Piece (140g)', defaultGrams: 140, caloriesPer100g: 165.0, proteinPer100g: 3.6, carbsPer100g: 33.0, fatPer100g: 2.2, fiberPer100g: 2.0),
    StandardFoodEntry(name: 'Idiyappam (String Hoppers - 3 pcs)', category: 'Breakfast', servingSize: '3 Pieces (120g)', defaultGrams: 120, caloriesPer100g: 125.0, proteinPer100g: 2.4, carbsPer100g: 27.0, fatPer100g: 0.6, fiberPer100g: 1.1),
    StandardFoodEntry(name: 'Kuzhi Paniyaram (Kara / Savory - 5 pcs)', category: 'Breakfast', servingSize: '5 Pieces (120g)', defaultGrams: 120, caloriesPer100g: 185.0, proteinPer100g: 4.8, carbsPer100g: 31.0, fatPer100g: 5.0, fiberPer100g: 2.0),
    StandardFoodEntry(name: 'Ragi Dosa (Finger Millet Dosa)', category: 'Breakfast', servingSize: '1 Dosa (100g)', defaultGrams: 100, caloriesPer100g: 155.0, proteinPer100g: 4.5, carbsPer100g: 29.0, fatPer100g: 2.8, fiberPer100g: 4.5),
    StandardFoodEntry(name: 'Neer Dosa (Mangalore Rice Crepe - 3 pcs)', category: 'Breakfast', servingSize: '3 Pieces (120g)', defaultGrams: 120, caloriesPer100g: 130.0, proteinPer100g: 2.8, carbsPer100g: 27.0, fatPer100g: 1.2, fiberPer100g: 1.0),

    // --- 2. SOUTH INDIAN RICE & MEALS ---
    StandardFoodEntry(name: 'Steamed White Rice (Ponni / Sona Masoori)', category: 'Rice & Meals', servingSize: '1 Cup (150g)', defaultGrams: 150, caloriesPer100g: 130.0, proteinPer100g: 2.7, carbsPer100g: 28.2, fatPer100g: 0.3, fiberPer100g: 0.4),
    StandardFoodEntry(name: 'Kerala Red Matta Rice', category: 'Rice & Meals', servingSize: '1 Cup (150g)', defaultGrams: 150, caloriesPer100g: 122.0, proteinPer100g: 3.2, carbsPer100g: 25.5, fatPer100g: 0.8, fiberPer100g: 2.4),
    StandardFoodEntry(name: 'Curd Rice (Thayir Sadam with Mustard Tempering)', category: 'Rice & Meals', servingSize: '1 Cup (200g)', defaultGrams: 200, caloriesPer100g: 145.0, proteinPer100g: 4.2, carbsPer100g: 22.0, fatPer100g: 4.5, fiberPer100g: 0.8),
    StandardFoodEntry(name: 'Sambar Sadam (Sambar Rice)', category: 'Rice & Meals', servingSize: '1 Bowl (220g)', defaultGrams: 220, caloriesPer100g: 140.0, proteinPer100g: 4.8, carbsPer100g: 25.0, fatPer100g: 2.5, fiberPer100g: 2.5),
    StandardFoodEntry(name: 'Rasam Sadam (Rasam Rice)', category: 'Rice & Meals', servingSize: '1 Bowl (200g)', defaultGrams: 200, caloriesPer100g: 110.0, proteinPer100g: 2.8, carbsPer100g: 23.0, fatPer100g: 1.0, fiberPer100g: 1.2),
    StandardFoodEntry(name: 'Lemon Rice (Elumichai Sadam)', category: 'Rice & Meals', servingSize: '1 Cup (180g)', defaultGrams: 180, caloriesPer100g: 175.0, proteinPer100g: 3.5, carbsPer100g: 29.0, fatPer100g: 5.5, fiberPer100g: 1.5),
    StandardFoodEntry(name: 'Tamarind Rice (Puliyodharai / Kovil Prasadam)', category: 'Rice & Meals', servingSize: '1 Cup (180g)', defaultGrams: 180, caloriesPer100g: 195.0, proteinPer100g: 4.0, carbsPer100g: 31.0, fatPer100g: 7.0, fiberPer100g: 2.0),
    StandardFoodEntry(name: 'Coconut Rice (Thengai Sadam)', category: 'Rice & Meals', servingSize: '1 Cup (180g)', defaultGrams: 180, caloriesPer100g: 215.0, proteinPer100g: 3.8, carbsPer100g: 28.0, fatPer100g: 10.5, fiberPer100g: 3.0),
    StandardFoodEntry(name: 'Tomato Rice (Thakkali Sadam)', category: 'Rice & Meals', servingSize: '1 Cup (180g)', defaultGrams: 180, caloriesPer100g: 165.0, proteinPer100g: 3.2, carbsPer100g: 28.0, fatPer100g: 4.8, fiberPer100g: 1.8),
    StandardFoodEntry(name: 'Bisi Bele Bath (Karnataka Spicy Lentil Rice)', category: 'Rice & Meals', servingSize: '1 Bowl (220g)', defaultGrams: 220, caloriesPer100g: 155.0, proteinPer100g: 5.2, carbsPer100g: 26.0, fatPer100g: 3.8, fiberPer100g: 3.0),
    StandardFoodEntry(name: 'Thalassery Chicken Biryani', category: 'Rice & Meals', servingSize: '1 Plate (350g)', defaultGrams: 350, caloriesPer100g: 175.0, proteinPer100g: 9.5, carbsPer100g: 22.0, fatPer100g: 5.8, fiberPer100g: 1.2),
    StandardFoodEntry(name: 'Hyderabadi Chicken Dum Biryani', category: 'Rice & Meals', servingSize: '1 Plate (350g)', defaultGrams: 350, caloriesPer100g: 185.0, proteinPer100g: 10.5, carbsPer100g: 23.0, fatPer100g: 6.5, fiberPer100g: 1.2),
    StandardFoodEntry(name: 'Dindigul Thalappakatti Mutton Biryani', category: 'Rice & Meals', servingSize: '1 Plate (350g)', defaultGrams: 350, caloriesPer100g: 210.0, proteinPer100g: 11.0, carbsPer100g: 21.0, fatPer100g: 9.5, fiberPer100g: 1.0),
    StandardFoodEntry(name: 'South Indian Veg Meals (Full Thali)', category: 'Rice & Meals', servingSize: '1 Thali (500g)', defaultGrams: 500, caloriesPer100g: 135.0, proteinPer100g: 4.5, carbsPer100g: 24.0, fatPer100g: 2.8, fiberPer100g: 3.5),

    // --- 3. CURRIES, GRAVIES & VEG SIDES ---
    StandardFoodEntry(name: 'Madras Drumstick Sambar', category: 'Curries & Gravies', servingSize: '1 Cup (150g)', defaultGrams: 150, caloriesPer100g: 80.0, proteinPer100g: 4.2, carbsPer100g: 12.0, fatPer100g: 1.8, fiberPer100g: 3.0),
    StandardFoodEntry(name: 'Thakkali Pepper Rasam', category: 'Curries & Gravies', servingSize: '1 Cup (150ml)', defaultGrams: 150, caloriesPer100g: 35.0, proteinPer100g: 1.2, carbsPer100g: 5.5, fatPer100g: 0.8, fiberPer100g: 1.0),
    StandardFoodEntry(name: 'Avial (Mixed Veg in Coconut Yogurt)', category: 'Curries & Gravies', servingSize: '1 Cup (150g)', defaultGrams: 150, caloriesPer100g: 115.0, proteinPer100g: 3.0, carbsPer100g: 11.0, fatPer100g: 6.8, fiberPer100g: 3.5),
    StandardFoodEntry(name: 'Cabbage Carrot Poriyal', category: 'Curries & Gravies', servingSize: '1 Cup (120g)', defaultGrams: 120, caloriesPer100g: 75.0, proteinPer100g: 2.4, carbsPer100g: 8.5, fatPer100g: 3.6, fiberPer100g: 2.8),
    StandardFoodEntry(name: 'Beans Poriyal with Grated Coconut', category: 'Curries & Gravies', servingSize: '1 Cup (120g)', defaultGrams: 120, caloriesPer100g: 80.0, proteinPer100g: 3.0, carbsPer100g: 9.0, fatPer100g: 3.8, fiberPer100g: 3.2),
    StandardFoodEntry(name: 'Urulaikizhangu (Potato) Spicy Roast', category: 'Curries & Gravies', servingSize: '1 Cup (120g)', defaultGrams: 120, caloriesPer100g: 150.0, proteinPer100g: 2.8, carbsPer100g: 22.0, fatPer100g: 6.0, fiberPer100g: 2.2),
    StandardFoodEntry(name: 'Mor Kuzhambu (Buttermilk Gravy)', category: 'Curries & Gravies', servingSize: '1 Cup (150g)', defaultGrams: 150, caloriesPer100g: 75.0, proteinPer100g: 3.5, carbsPer100g: 6.0, fatPer100g: 4.2, fiberPer100g: 1.0),
    StandardFoodEntry(name: 'Ennai Kathirikai (Stuffed Brinjal Curry)', category: 'Curries & Gravies', servingSize: '1 Cup (140g)', defaultGrams: 140, caloriesPer100g: 135.0, proteinPer100g: 2.5, carbsPer100g: 10.0, fatPer100g: 9.8, fiberPer100g: 3.8),
    StandardFoodEntry(name: 'Poondu (Garlic) Kara Kuzhambu', category: 'Curries & Gravies', servingSize: '1 Cup (120g)', defaultGrams: 120, caloriesPer100g: 110.0, proteinPer100g: 2.2, carbsPer100g: 12.0, fatPer100g: 6.0, fiberPer100g: 2.0),
    StandardFoodEntry(name: 'Keerai Kootu (Spinach & Lentil Stew)', category: 'Curries & Gravies', servingSize: '1 Cup (150g)', defaultGrams: 150, caloriesPer100g: 90.0, proteinPer100g: 5.5, carbsPer100g: 11.0, fatPer100g: 3.0, fiberPer100g: 4.0),
    StandardFoodEntry(name: 'Chettinad Chicken Curry', category: 'Curries & Gravies', servingSize: '1 Bowl (200g)', defaultGrams: 200, caloriesPer100g: 165.0, proteinPer100g: 14.5, carbsPer100g: 4.5, fatPer100g: 10.2, fiberPer100g: 1.5),
    StandardFoodEntry(name: 'Chicken Chukka (Spicy Dry Roast)', category: 'Curries & Gravies', servingSize: '1 Plate (150g)', defaultGrams: 150, caloriesPer100g: 210.0, proteinPer100g: 22.0, carbsPer100g: 3.5, fatPer100g: 12.0, fiberPer100g: 1.2),
    StandardFoodEntry(name: 'Mutton Sukka Varuval', category: 'Curries & Gravies', servingSize: '1 Plate (150g)', defaultGrams: 150, caloriesPer100g: 245.0, proteinPer100g: 20.5, carbsPer100g: 3.0, fatPer100g: 17.0, fiberPer100g: 1.0),
    StandardFoodEntry(name: 'Meen Kuzhambu (Traditional Fish Curry)', category: 'Curries & Gravies', servingSize: '1 Bowl (200g)', defaultGrams: 200, caloriesPer100g: 125.0, proteinPer100g: 13.0, carbsPer100g: 4.0, fatPer100g: 6.5, fiberPer100g: 1.0),
    StandardFoodEntry(name: 'Vanjaram Fish Fry (King Fish Tawa Fry)', category: 'Curries & Gravies', servingSize: '1 Slice (120g)', defaultGrams: 120, caloriesPer100g: 195.0, proteinPer100g: 21.0, carbsPer100g: 4.0, fatPer100g: 10.5, fiberPer100g: 0.5),

    // --- 4. SOUTH INDIAN SNACKS & CRISPS ---
    StandardFoodEntry(name: 'Masala Vada (Chana Dal Crunchy Vada)', category: 'Snacks & Crisps', servingSize: '1 Piece (45g)', defaultGrams: 45, caloriesPer100g: 295.0, proteinPer100g: 9.5, carbsPer100g: 32.0, fatPer100g: 15.5, fiberPer100g: 4.5),
    StandardFoodEntry(name: 'Onion Pakoda (Crispy Pakora)', category: 'Snacks & Crisps', servingSize: '1 Plate (100g)', defaultGrams: 100, caloriesPer100g: 330.0, proteinPer100g: 7.0, carbsPer100g: 35.0, fatPer100g: 18.5, fiberPer100g: 3.5),
    StandardFoodEntry(name: 'Ribbon Pakoda (Murukku Strips)', category: 'Snacks & Crisps', servingSize: '1 Handful (50g)', defaultGrams: 50, caloriesPer100g: 510.0, proteinPer100g: 6.5, carbsPer100g: 58.0, fatPer100g: 28.5, fiberPer100g: 3.0),
    StandardFoodEntry(name: 'Kai Murukku (Hand-Twisted Chakli)', category: 'Snacks & Crisps', servingSize: '2 Pieces (50g)', defaultGrams: 50, caloriesPer100g: 490.0, proteinPer100g: 6.0, carbsPer100g: 62.0, fatPer100g: 25.0, fiberPer100g: 2.5),
    StandardFoodEntry(name: 'Madras Mixture', category: 'Snacks & Crisps', servingSize: '1 Cup (60g)', defaultGrams: 60, caloriesPer100g: 520.0, proteinPer100g: 8.5, carbsPer100g: 54.0, fatPer100g: 30.0, fiberPer100g: 4.0),
    StandardFoodEntry(name: 'Banana Chips (Kerala Nendran Chips in Coconut Oil)', category: 'Snacks & Crisps', servingSize: '1 Handful (50g)', defaultGrams: 50, caloriesPer100g: 530.0, proteinPer100g: 2.5, carbsPer100g: 58.0, fatPer100g: 33.0, fiberPer100g: 5.5),
    StandardFoodEntry(name: 'Milagai (Mirchi) Bajji (1 pc)', category: 'Snacks & Crisps', servingSize: '1 Piece (60g)', defaultGrams: 60, caloriesPer100g: 220.0, proteinPer100g: 4.5, carbsPer100g: 24.0, fatPer100g: 12.0, fiberPer100g: 2.0),
    StandardFoodEntry(name: 'Chana / Kondakadalai Sundal', category: 'Snacks & Crisps', servingSize: '1 Cup (120g)', defaultGrams: 120, caloriesPer100g: 155.0, proteinPer100g: 8.5, carbsPer100g: 23.0, fatPer100g: 3.8, fiberPer100g: 6.5),
    StandardFoodEntry(name: 'Chicken 65 (South Indian Crispy Bites)', category: 'Snacks & Crisps', servingSize: '1 Plate (150g)', defaultGrams: 150, caloriesPer100g: 260.0, proteinPer100g: 21.0, carbsPer100g: 8.0, fatPer100g: 16.0, fiberPer100g: 1.0),
    StandardFoodEntry(name: 'Egg Puff (Bakery Style)', category: 'Snacks & Crisps', servingSize: '1 Puff (110g)', defaultGrams: 110, caloriesPer100g: 310.0, proteinPer100g: 8.0, carbsPer100g: 29.0, fatPer100g: 18.5, fiberPer100g: 1.5),

    // --- 5. SOUTH INDIAN SWEETS & DESSERTS ---
    StandardFoodEntry(name: 'Ghee Mysore Pak', category: 'Sweets & Desserts', servingSize: '1 Piece (40g)', defaultGrams: 40, caloriesPer100g: 525.0, proteinPer100g: 5.0, carbsPer100g: 56.0, fatPer100g: 32.0, fiberPer100g: 1.5),
    StandardFoodEntry(name: 'Rava Kesari (Ghee Sooji Halwa)', category: 'Sweets & Desserts', servingSize: '1 Bowl (100g)', defaultGrams: 100, caloriesPer100g: 330.0, proteinPer100g: 4.0, carbsPer100g: 52.0, fatPer100g: 12.0, fiberPer100g: 1.2),
    StandardFoodEntry(name: 'Palada Pradhaman / Payasam', category: 'Sweets & Desserts', servingSize: '1 Cup (150g)', defaultGrams: 150, caloriesPer100g: 210.0, proteinPer100g: 4.5, carbsPer100g: 34.0, fatPer100g: 6.8, fiberPer100g: 0.5),
    StandardFoodEntry(name: 'Sweet Kozhukattai (Modak with Jaggery & Coconut)', category: 'Sweets & Desserts', servingSize: '2 Pieces (80g)', defaultGrams: 80, caloriesPer100g: 220.0, proteinPer100g: 3.2, carbsPer100g: 44.0, fatPer100g: 4.0, fiberPer100g: 2.2),
    StandardFoodEntry(name: 'Tirunelveli Ghee Halwa', category: 'Sweets & Desserts', servingSize: '1 Serving (60g)', defaultGrams: 60, caloriesPer100g: 460.0, proteinPer100g: 3.0, carbsPer100g: 62.0, fatPer100g: 23.0, fiberPer100g: 0.8),
    StandardFoodEntry(name: 'Boondi Laddu', category: 'Sweets & Desserts', servingSize: '1 Piece (45g)', defaultGrams: 45, caloriesPer100g: 450.0, proteinPer100g: 6.0, carbsPer100g: 64.0, fatPer100g: 19.0, fiberPer100g: 2.0),

    // --- 6. BEVERAGES & DRINKS ---
    StandardFoodEntry(name: 'South Indian Filter Coffee (Kaapi with Milk)', category: 'Beverages & Drinks', servingSize: '1 Tumbler (150ml)', defaultGrams: 150, caloriesPer100g: 75.0, proteinPer100g: 2.8, carbsPer100g: 8.5, fatPer100g: 3.2, fiberPer100g: 0.0),
    StandardFoodEntry(name: 'Masala Chai / Ginger Tea', category: 'Beverages & Drinks', servingSize: '1 Cup (150ml)', defaultGrams: 150, caloriesPer100g: 65.0, proteinPer100g: 2.5, carbsPer100g: 7.8, fatPer100g: 2.8, fiberPer100g: 0.0),
    StandardFoodEntry(name: 'Neer Mor (Spiced Buttermilk with Ginger & Curry Leaves)', category: 'Beverages & Drinks', servingSize: '1 Glass (250ml)', defaultGrams: 250, caloriesPer100g: 22.0, proteinPer100g: 1.5, carbsPer100g: 2.2, fatPer100g: 0.8, fiberPer100g: 0.2),
    StandardFoodEntry(name: 'Madurai Jigarthanda', category: 'Beverages & Drinks', servingSize: '1 Glass (250ml)', defaultGrams: 250, caloriesPer100g: 145.0, proteinPer100g: 3.8, carbsPer100g: 22.0, fatPer100g: 5.0, fiberPer100g: 0.5),
    StandardFoodEntry(name: 'Fresh Tender Coconut Water', category: 'Beverages & Drinks', servingSize: '1 Cup (200ml)', defaultGrams: 200, caloriesPer100g: 19.0, proteinPer100g: 0.7, carbsPer100g: 3.7, fatPer100g: 0.2, fiberPer100g: 1.1),
    StandardFoodEntry(name: 'Nannari Sarbath', category: 'Beverages & Drinks', servingSize: '1 Glass (200ml)', defaultGrams: 200, caloriesPer100g: 55.0, proteinPer100g: 0.2, carbsPer100g: 14.0, fatPer100g: 0.0, fiberPer100g: 0.0),

    // --- 7. FITNESS & HIGH PROTEIN ---
    StandardFoodEntry(name: 'Boiled Egg (Whole - 1 Large)', category: 'Fitness & High Protein', servingSize: '1 Egg (50g)', defaultGrams: 50, caloriesPer100g: 155.0, proteinPer100g: 13.0, carbsPer100g: 1.1, fatPer100g: 11.0, fiberPer100g: 0.0),
    StandardFoodEntry(name: 'Boiled Egg Whites (3 Whites)', category: 'Fitness & High Protein', servingSize: '3 Whites (100g)', defaultGrams: 100, caloriesPer100g: 52.0, proteinPer100g: 11.0, carbsPer100g: 0.7, fatPer100g: 0.2, fiberPer100g: 0.0),
    StandardFoodEntry(name: 'Grilled Chicken Breast', category: 'Fitness & High Protein', servingSize: '1 Breast (150g)', defaultGrams: 150, caloriesPer100g: 165.0, proteinPer100g: 31.0, carbsPer100g: 0.0, fatPer100g: 3.6, fiberPer100g: 0.0),
    StandardFoodEntry(name: 'Fresh Raw Paneer (Cottage Cheese)', category: 'Fitness & High Protein', servingSize: '100g', defaultGrams: 100, caloriesPer100g: 265.0, proteinPer100g: 18.5, carbsPer100g: 3.5, fatPer100g: 20.0, fiberPer100g: 0.0),
    StandardFoodEntry(name: 'Moong Sprout Salad (Pacha Payaru)', category: 'Fitness & High Protein', servingSize: '1 Bowl (150g)', defaultGrams: 150, caloriesPer100g: 105.0, proteinPer100g: 7.5, carbsPer100g: 18.0, fatPer100g: 0.6, fiberPer100g: 4.8),
    StandardFoodEntry(name: 'Whey Protein Isolate (1 Scoop)', category: 'Fitness & High Protein', servingSize: '1 Scoop (30g)', defaultGrams: 30, caloriesPer100g: 380.0, proteinPer100g: 80.0, carbsPer100g: 4.0, fatPer100g: 2.5, fiberPer100g: 1.0),
    StandardFoodEntry(name: 'Soya Chunks Curry', category: 'Fitness & High Protein', servingSize: '1 Bowl (180g)', defaultGrams: 180, caloriesPer100g: 140.0, proteinPer100g: 16.0, carbsPer100g: 10.0, fatPer100g: 4.0, fiberPer100g: 5.0),
    StandardFoodEntry(name: 'Peanut Butter on Whole Wheat Toast', category: 'Fitness & High Protein', servingSize: '1 Slice (60g)', defaultGrams: 60, caloriesPer100g: 340.0, proteinPer100g: 14.0, carbsPer100g: 36.0, fatPer100g: 16.0, fiberPer100g: 4.5),
  ];

  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_customFoodsPrefKey);
      if (str != null) {
        final List list = json.decode(str);
        _customFoods.clear();
        for (var item in list) {
          _customFoods.add(StandardFoodEntry.fromMap(item));
        }
      }
      _isLoaded = true;
    } catch (_) {}
  }

  static List<StandardFoodEntry> getAllFoods() {
    return [..._customFoods, ..._builtInFoods];
  }

  static List<String> getCategories() {
    return [
      'All',
      'Breakfast',
      'Rice & Meals',
      'Curries & Gravies',
      'Snacks & Crisps',
      'Sweets & Desserts',
      'Beverages & Drinks',
      'Fitness & High Protein',
      'Custom Foods',
    ];
  }

  static List<StandardFoodEntry> searchFoods(String query, {String? category}) {
    final clean = query.toLowerCase().trim();
    final all = getAllFoods();

    return all.where((item) {
      if (category != null && category != 'All') {
        if (category == 'Custom Foods' && !item.isCustom) return false;
        if (category != 'Custom Foods' && item.category != category) return false;
      }

      if (clean.isEmpty) return true;
      return item.name.toLowerCase().contains(clean) ||
          item.category.toLowerCase().contains(clean) ||
          item.servingSize.toLowerCase().contains(clean);
    }).toList();
  }

  static Future<void> addCustomFood(StandardFoodEntry food) async {
    food.isCustom = true;
    _customFoods.removeWhere((e) => e.name.toLowerCase() == food.name.toLowerCase());
    _customFoods.insert(0, food);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _customFoods.map((e) => e.toMap()).toList();
      await prefs.setString(_customFoodsPrefKey, json.encode(list));
    } catch (_) {}
  }

  static Future<void> deleteCustomFood(String id) async {
    _customFoods.removeWhere((e) => e.id == id);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _customFoods.map((e) => e.toMap()).toList();
      await prefs.setString(_customFoodsPrefKey, json.encode(list));
    } catch (_) {}
  }

  static Map<String, double> getDensityFor(String query) {
    final clean = query.toLowerCase().trim();
    final all = getAllFoods();
    for (var item in all) {
      final itemName = item.name.toLowerCase();
      if (itemName.contains(clean) || clean.contains(itemName)) {
        return {
          'calories': item.caloriesPer100g,
          'protein': item.proteinPer100g,
          'carbs': item.carbsPer100g,
          'fat': item.fatPer100g,
          'fiber': item.fiberPer100g,
        };
      }
    }
    return {'calories': 150.0, 'protein': 8.0, 'carbs': 20.0, 'fat': 5.0, 'fiber': 2.0};
  }
}
