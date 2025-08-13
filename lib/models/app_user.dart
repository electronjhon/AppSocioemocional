class AppUser {
  final String uid;
  final String documentId; // documento
  final String email;
  final String role; // 'estudiante' | 'docente'
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
}


