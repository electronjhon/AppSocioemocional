class AppUser {
  final String uid;
  final String documentId; // documento
  final String email;
  final String role; // 'estudiante' | 'docente' | 'administrador'
  final String course; // curso
  final String avatarAsset; // ruta local del asset
  final String firstName;
  final String lastName;

  AppUser({
    required this.uid,
    required this.documentId,
    required this.email,
    required this.role,
    required this.course,
    required this.avatarAsset,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'documentId': documentId,
      'email': email,
      'role': role,
      'course': course,
      'avatarAsset': avatarAsset,
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': DateTime.now().toUtc(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      documentId: map['documentId'] as String,
      email: map['email'] as String,
      role: map['role'] as String,
      course: map['course'] as String,
      avatarAsset: map['avatarAsset'] as String,
      firstName: (map['firstName'] as String?) ?? '',
      lastName: (map['lastName'] as String?) ?? '',
    );
  }

  AppUser copyWith({
    String? uid,
    String? documentId,
    String? email,
    String? role,
    String? course,
    String? avatarAsset,
    String? firstName,
    String? lastName,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      documentId: documentId ?? this.documentId,
      email: email ?? this.email,
      role: role ?? this.role,
      course: course ?? this.course,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, documentId: $documentId, email: $email, role: $role, course: $course, firstName: $firstName, lastName: $lastName)';
  }
}


