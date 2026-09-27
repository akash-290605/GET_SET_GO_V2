import 'dart:convert';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

class FoodItem {
  final String id;
  final String name;
  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double portionGrams;
  final String servingUnit; // 'g', 'bowl', 'slice', 'piece', 'cup'
  final double servingQuantity; // e.g. 1.0, 1.5, 2.0
  final MealType mealType;
  final DateTime loggedAt;
  final String photoPath;
  final String confidenceScore;
  final String healthAdvice;

  FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.portionGrams = 100.0,
    this.servingUnit = 'g',
    this.servingQuantity = 1.0,
    required this.mealType,
    required this.loggedAt,
    this.photoPath = '',
    this.confidenceScore = '95%',
    this.healthAdvice = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'calories': calories,
    'proteinGrams': proteinGrams,
    'carbsGrams': carbsGrams,
    'fatGrams': fatGrams,
    'portionGrams': portionGrams,
    'servingUnit': servingUnit,
    'servingQuantity': servingQuantity,
    'mealType': mealType.name,
    'loggedAt': loggedAt.toIso8601String(),
    'photoPath': photoPath,
    'confidenceScore': confidenceScore,
    'healthAdvice': healthAdvice,
  };

  factory FoodItem.fromMap(Map<String, dynamic> map) => FoodItem(
    id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: map['name']?.toString() ?? 'Food Item',
    calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
    proteinGrams: (map['proteinGrams'] as num?)?.toDouble() ?? 0.0,
    carbsGrams: (map['carbsGrams'] as num?)?.toDouble() ?? 0.0,
    fatGrams: (map['fatGrams'] as num?)?.toDouble() ?? 0.0,
    portionGrams: (map['portionGrams'] as num?)?.toDouble() ?? 100.0,
    servingUnit: map['servingUnit']?.toString() ?? 'g',
    servingQuantity: (map['servingQuantity'] as num?)?.toDouble() ?? 1.0,
    mealType: MealType.values.firstWhere(
      (m) => m.name == map['mealType'],
      orElse: () => MealType.lunch,
    ),
    loggedAt: map['loggedAt'] != null ? DateTime.tryParse(map['loggedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    photoPath: map['photoPath']?.toString() ?? '',
    confidenceScore: map['confidenceScore']?.toString() ?? '95%',
    healthAdvice: map['healthAdvice']?.toString() ?? '',
  );

  String toJson() => json.encode(toMap());

  factory FoodItem.fromJson(String source) => FoodItem.fromMap(json.decode(source));

  FoodItem copyWith({
    String? id,
    String? name,
    double? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    double? portionGrams,
    String? servingUnit,
    double? servingQuantity,
    MealType? mealType,
    DateTime? loggedAt,
    String? photoPath,
    String? confidenceScore,
    String? healthAdvice,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      portionGrams: portionGrams ?? this.portionGrams,
      servingUnit: servingUnit ?? this.servingUnit,
      servingQuantity: servingQuantity ?? this.servingQuantity,
      mealType: mealType ?? this.mealType,
      loggedAt: loggedAt ?? this.loggedAt,
      photoPath: photoPath ?? this.photoPath,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      healthAdvice: healthAdvice ?? this.healthAdvice,
    );
  }
}

class MacroTargets {
  final double calorieTarget;
  final double proteinTargetGrams;
  final double carbsTargetGrams;
  final double fatTargetGrams;
  final double waterMlTarget;

  MacroTargets({
    this.calorieTarget = 2200.0,
    this.proteinTargetGrams = 130.0,
    this.carbsTargetGrams = 250.0,
    this.fatTargetGrams = 65.0,
    this.waterMlTarget = 3000.0,
  });

  Map<String, dynamic> toMap() => {
    'calorieTarget': calorieTarget,
    'proteinTargetGrams': proteinTargetGrams,
    'carbsTargetGrams': carbsTargetGrams,
    'fatTargetGrams': fatTargetGrams,
    'waterMlTarget': waterMlTarget,
  };

  factory MacroTargets.fromMap(Map<String, dynamic> map) => MacroTargets(
    calorieTarget: (map['calorieTarget'] as num?)?.toDouble() ?? 2200.0,
    proteinTargetGrams: (map['proteinTargetGrams'] as num?)?.toDouble() ?? 130.0,
    carbsTargetGrams: (map['carbsTargetGrams'] as num?)?.toDouble() ?? 250.0,
    fatTargetGrams: (map['fatTargetGrams'] as num?)?.toDouble() ?? 65.0,
    waterMlTarget: (map['waterMlTarget'] as num?)?.toDouble() ?? 3000.0,
  );
}
