class NotificationMessage {
  final String? id;
  final String title;
  final String message;
  final String? url; // URL opcional para la píldora
  final String senderUid;
  final String senderName;
  final DateTime createdAt;
  final List<String> targetRoles; // ['estudiante', 'docente', etc.]
  final List<String> targetCourses; // cursos específicos, vacío = todos
  final bool isRead;
  final String? recipientUid; // null si es para todos

  NotificationMessage({
    this.id,
    required this.title,
    required this.message,
    this.url,
    required this.senderUid,
    required this.senderName,
    required this.createdAt,
    required this.targetRoles,
    required this.targetCourses,
    this.isRead = false,
    this.recipientUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'url': url,
      'senderUid': senderUid,
      'senderName': senderName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'targetRoles': targetRoles,
      'targetCourses': targetCourses,
      'isRead': isRead ? 1 : 0,
      'recipientUid': recipientUid,
    };
  }

  factory NotificationMessage.fromMap(Map<String, dynamic> map) {
    return NotificationMessage(
      id: map['id'] as String?,
      title: map['title'] as String,
      message: map['message'] as String,
      url: map['url'] as String?,
      senderUid: map['senderUid'] as String,
      senderName: map['senderName'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      targetRoles: List<String>.from(map['targetRoles'] ?? []),
      targetCourses: List<String>.from(map['targetCourses'] ?? []),
      isRead: (map['isRead'] as int?) == 1,
      recipientUid: map['recipientUid'] as String?,
    );
  }

  NotificationMessage copyWith({
    String? id,
    String? title,
    String? message,
    String? url,
    String? senderUid,
    String? senderName,
    DateTime? createdAt,
    List<String>? targetRoles,
    List<String>? targetCourses,
    bool? isRead,
    String? recipientUid,
  }) {
    return NotificationMessage(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      url: url ?? this.url,
      senderUid: senderUid ?? this.senderUid,
      senderName: senderName ?? this.senderName,
      createdAt: createdAt ?? this.createdAt,
      targetRoles: targetRoles ?? this.targetRoles,
      targetCourses: targetCourses ?? this.targetCourses,
      isRead: isRead ?? this.isRead,
      recipientUid: recipientUid ?? this.recipientUid,
    );
  }

  @override
  String toString() {
    return 'NotificationMessage(id: $id, title: $title, senderName: $senderName, createdAt: $createdAt, isRead: $isRead)';
  }
}
