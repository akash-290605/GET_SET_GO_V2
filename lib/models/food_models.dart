import 'dart:convert';

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

class StandardNutritionDatabase {
  static final Map<String, Map<String, double>> _densities = {
    'boiled egg': {'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0, 'fiber': 0.0},
    'egg': {'calories': 155.0, 'protein': 13.0, 'carbs': 1.1, 'fat': 11.0, 'fiber': 0.0},
    'paneer': {'calories': 265.0, 'protein': 18.0, 'carbs': 3.5, 'fat': 20.0, 'fiber': 0.0},
    'chicken breast': {'calories': 165.0, 'protein': 31.0, 'carbs': 0.0, 'fat': 3.6, 'fiber': 0.0},
    'white rice': {'calories': 130.0, 'protein': 2.7, 'carbs': 28.0, 'fat': 0.3, 'fiber': 0.4},
    'roti': {'calories': 264.0, 'protein': 9.0, 'carbs': 52.0, 'fat': 3.0, 'fiber': 7.0},
    'chapati': {'calories': 264.0, 'protein': 9.0, 'carbs': 52.0, 'fat': 3.0, 'fiber': 7.0},
    'dal': {'calories': 116.0, 'protein': 9.0, 'carbs': 20.0, 'fat': 0.4, 'fiber': 8.0},
    'greek yogurt': {'calories': 59.0, 'protein': 10.0, 'carbs': 3.6, 'fat': 0.4, 'fiber': 0.0},
    'oatmeal': {'calories': 68.0, 'protein': 2.4, 'carbs': 12.0, 'fat': 1.4, 'fiber': 1.7},
    'banana': {'calories': 89.0, 'protein': 1.1, 'carbs': 23.0, 'fat': 0.3, 'fiber': 2.6},
    'apple': {'calories': 52.0, 'protein': 0.3, 'carbs': 14.0, 'fat': 0.2, 'fiber': 2.4},
    'peanut butter': {'calories': 588.0, 'protein': 25.0, 'carbs': 20.0, 'fat': 50.0, 'fiber': 6.0},
    'whey protein': {'calories': 380.0, 'protein': 80.0, 'carbs': 6.0, 'fat': 4.0, 'fiber': 1.0},
  };

  static Map<String, double> getDensityFor(String query) {
    final clean = query.toLowerCase().trim();
    for (var entry in _densities.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        return entry.value;
      }
    }
    return {'calories': 150.0, 'protein': 8.0, 'carbs': 20.0, 'fat': 5.0, 'fiber': 2.0};
  }
}
