class PhysiqueMeasurement {
  final int? id;
  final String date;
  final String unit;
  final double? chest;
  final double? waist;
  final double? abdomen;
  final double? hip;
  final double? neck;
  final double? leftArm;
  final double? rightArm;
  final double? leftThigh;
  final double? rightThigh;
  final String? comment;

  const PhysiqueMeasurement({
    this.id,
    required this.date,
    this.unit = 'cm',
    this.chest,
    this.waist,
    this.abdomen,
    this.hip,
    this.neck,
    this.leftArm,
    this.rightArm,
    this.leftThigh,
    this.rightThigh,
    this.comment,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date,
      'unit': unit,
      'chest': chest,
      'waist': waist,
      'abdomen': abdomen,
      'hip': hip,
      'neck': neck,
      'leftArm': leftArm,
      'rightArm': rightArm,
      'leftThigh': leftThigh,
      'rightThigh': rightThigh,
      'comment': comment,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory PhysiqueMeasurement.fromMap(Map<String, dynamic> map) {
    return PhysiqueMeasurement(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      unit: map['unit'] as String? ?? 'cm',
      chest: (map['chest'] as num?)?.toDouble(),
      waist: (map['waist'] as num?)?.toDouble(),
      abdomen: (map['abdomen'] as num?)?.toDouble(),
      hip: (map['hip'] as num?)?.toDouble(),
      neck: (map['neck'] as num?)?.toDouble(),
      leftArm: (map['leftArm'] as num?)?.toDouble(),
      rightArm: (map['rightArm'] as num?)?.toDouble(),
      leftThigh: (map['leftThigh'] as num?)?.toDouble(),
      rightThigh: (map['rightThigh'] as num?)?.toDouble(),
      comment: map['comment'] as String?,
    );
  }

  PhysiqueMeasurement copyWith({
    int? id,
    String? date,
    String? unit,
    double? chest,
    double? waist,
    double? abdomen,
    double? hip,
    double? neck,
    double? leftArm,
    double? rightArm,
    double? leftThigh,
    double? rightThigh,
    String? comment,
  }) {
    return PhysiqueMeasurement(
      id: id ?? this.id,
      date: date ?? this.date,
      unit: unit ?? this.unit,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      abdomen: abdomen ?? this.abdomen,
      hip: hip ?? this.hip,
      neck: neck ?? this.neck,
      leftArm: leftArm ?? this.leftArm,
      rightArm: rightArm ?? this.rightArm,
      leftThigh: leftThigh ?? this.leftThigh,
      rightThigh: rightThigh ?? this.rightThigh,
      comment: comment ?? this.comment,
    );
  }
}
