class EmotionRecord {
  final String? id;
  final String studentUid;
  final String emotion;
  final String? note;
  final DateTime createdAt;
  final String dayKey;
  final bool isSynced;

  EmotionRecord({
    this.id,
    required this.studentUid,
    required this.emotion,
    this.note,
    required this.createdAt,
    required this.dayKey,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentUid': studentUid,
      'emotion': emotion,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dayKey': dayKey,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory EmotionRecord.fromMap(Map<String, dynamic> map) {
    return EmotionRecord(
      id: map['id'] as String?,
      studentUid: map['studentUid'] as String,
      emotion: map['emotion'] as String,
      note: map['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      dayKey: map['dayKey'] as String,
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  EmotionRecord copyWith({
    String? id,
    String? studentUid,
    String? emotion,
    String? note,
    DateTime? createdAt,
    String? dayKey,
    bool? isSynced,
  }) {
    return EmotionRecord(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      emotion: emotion ?? this.emotion,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      dayKey: dayKey ?? this.dayKey,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
