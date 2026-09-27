class BodyPhotoEntry {
  final int? id;
  final String date;
  final String time;
  final String? photoBase64;
  final String? photoPath;
  final double? weightKg;
  final String? note;

  const BodyPhotoEntry({
    this.id,
    required this.date,
    required this.time,
    this.photoBase64,
    this.photoPath,
    this.weightKg,
    this.note,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date,
      'time': time,
      'photoBase64': photoBase64,
      'photoPath': photoPath,
      'weightKg': weightKg,
      'note': note,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory BodyPhotoEntry.fromMap(Map<String, dynamic> map) {
    return BodyPhotoEntry(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      time: map['time'] as String? ?? '',
      photoBase64: map['photoBase64'] as String?,
      photoPath: map['photoPath'] as String?,
      weightKg: (map['weightKg'] as num?)?.toDouble(),
      note: map['note'] as String?,
    );
  }

  BodyPhotoEntry copyWith({
    int? id,
    String? date,
    String? time,
    String? photoBase64,
    String? photoPath,
    double? weightKg,
    String? note,
  }) {
    return BodyPhotoEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      photoBase64: photoBase64 ?? this.photoBase64,
      photoPath: photoPath ?? this.photoPath,
      weightKg: weightKg ?? this.weightKg,
      note: note ?? this.note,
    );
  }
}
