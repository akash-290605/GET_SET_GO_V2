class WeeklyWeightEntry {
  final int? id;
  final String date;
  final String weekKey;
  final double weightKg;
  final String? comment;

  const WeeklyWeightEntry({
    this.id,
    required this.date,
    required this.weekKey,
    required this.weightKg,
    this.comment,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date,
      'weekKey': weekKey,
      'weightKg': weightKg,
      'comment': comment,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory WeeklyWeightEntry.fromMap(Map<String, dynamic> map) {
    return WeeklyWeightEntry(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      weekKey: map['weekKey'] as String? ?? '',
      weightKg: (map['weightKg'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'] as String?,
    );
  }

  WeeklyWeightEntry copyWith({
    int? id,
    String? date,
    String? weekKey,
    double? weightKg,
    String? comment,
  }) {
    return WeeklyWeightEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      weekKey: weekKey ?? this.weekKey,
      weightKg: weightKg ?? this.weightKg,
      comment: comment ?? this.comment,
    );
  }
}
