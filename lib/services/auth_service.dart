import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'local_database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<AppUser?> getProfileByUid(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return AppUser.fromMap(data);
  }

  Future<AppUser> registerWithEmail({
    required String documentId,
    required String email,
    required String password,
    required String role,
    required String course,
    required String avatarAsset,
    required String firstName,
    required String lastName,
  }) async {
    final existing = await _db
        .collection('users')
        .where('documentId', isEqualTo: documentId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('El documento ya está registrado');
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final appUser = AppUser(
      uid: uid,
      documentId: documentId,
      email: email,
      role: role,
      course: course,
      avatarAsset: avatarAsset,
      firstName: firstName,
      lastName: lastName,
    );
    await _db.collection('users').doc(uid).set(appUser.toMap());
    // Index auxiliar para login por documento
    await _db.collection('documents_index').doc(documentId).set({'uid': uid});
    return appUser;
  }

  Future<UserCredential> signInWithDocumentAndPassword({
    required String documentId,
    required String password,
  }) async {
    // Resolver email desde documento
    final indexDoc = await _db.collection('documents_index').doc(documentId).get();
    if (!indexDoc.exists) {
      throw Exception('Documento no encontrado');
    }
    final uid = indexDoc.data()!['uid'] as String;
    final profile = await _db.collection('users').doc(uid).get();
    if (!profile.exists) {
      throw Exception('Perfil no encontrado');
    }
    final email = profile.data()!['email'] as String;
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    try {
      // Cerrar sesión de Firebase Auth
      await _auth.signOut();
      
      // Esperar un momento para que los listeners se procesen
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Limpiar cualquier estado local si es necesario
      // Los listeners de Firebase Auth se encargarán de notificar el cambio de estado
    } catch (e) {
      print('Error durante el cierre de sesión: $e');
      // Re-lanzar la excepción para que la UI pueda manejarla
      rethrow;
    }
  }

  // Métodos para administrador
  Future<AppUser?> getUserByDocumentNumber(String documentNumber) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('documentId', isEqualTo: documentNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        return AppUser.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Error buscando usuario: $e');
      return null;
    }
  }

  Future<List<AppUser>> getAllUsers() async {
    try {
      final querySnapshot = await _db.collection('users').get();
      return querySnapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error obteniendo usuarios: $e');
      return [];
    }
  }

  Future<bool> updateUser(AppUser user) async {
    try {
      await _db.collection('users').doc(user.uid).update(user.toMap());
      return true;
    } catch (e) {
      print('Error actualizando usuario: $e');
      return false;
    }
  }

  Future<bool> updateUserPassword(String uid, String newPassword) async {
    try {
      // Obtener el email del usuario
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return false;

      // Nota: El email se obtiene pero no se usa actualmente
      // ya que la actualización de contraseña requiere Admin SDK
      // final email = userDoc.data()!['email'] as String;
      
      // Actualizar contraseña usando Admin SDK (requiere configuración adicional)
      // Por ahora, solo actualizamos en Firestore y el usuario deberá cambiar su contraseña
      await _db.collection('users').doc(uid).update({
        'passwordResetRequired': true,
        'tempPassword': newPassword, // Solo para referencia, no se almacena de forma segura
      });
      
      return true;
    } catch (e) {
      print('Error actualizando contraseña: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String uid) async {
    try {
      // Eliminar de Firestore
      await _db.collection('users').doc(uid).delete();
      
      // Eliminar datos de emociones del estudiante (ya no existe esta colección separada)
      // Las emociones se eliminan directamente de la subcolección del usuario
      
      return true;
    } catch (e) {
      print('Error eliminando usuario: $e');
      return false;
    }
  }

  Future<bool> deleteUserEmotions(String uid) async {
    try {
      // Eliminar colección de emociones del estudiante
      final emotionsRef = _db.collection('users').doc(uid).collection('emotions');
      final emotions = await emotionsRef.get();
      
      final batch = _db.batch();
      for (final doc in emotions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      // Limpiar también las emociones locales del usuario
      try {
        await _localDb.clearAllEmotions(); // Esto limpia todas las emociones locales
        print('Emociones locales del usuario $uid eliminadas');
      } catch (e) {
        print('Error eliminando emociones locales del usuario $uid: $e');
      }
      
      return true;
    } catch (e) {
      print('Error eliminando emociones: $e');
      return false;
    }
  }

  Future<bool> deleteAllEmotions() async {
    try {
      // Obtener todos los usuarios estudiantes
      final usersSnapshot = await _db.collection('users').where('role', isEqualTo: 'estudiante').get();
      
      int totalDeleted = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          // Eliminar todas las emociones del estudiante
          final emotionsSnapshot = await userDoc.reference.collection('emotions').get();
          
          if (emotionsSnapshot.docs.isNotEmpty) {
            final batch = _db.batch();
            
            for (final emotionDoc in emotionsSnapshot.docs) {
              batch.delete(emotionDoc.reference);
            }
            
            await batch.commit();
            totalDeleted += emotionsSnapshot.docs.length;
            print('Eliminadas ${emotionsSnapshot.docs.length} emociones del estudiante ${userDoc.id}');
          }
        } catch (e) {
          print('Error eliminando emociones del estudiante ${userDoc.id}: $e');
          // Continuar con el siguiente estudiante
        }
      }
      
      // Limpiar también la base de datos local
      try {
        await _localDb.clearAllEmotions();
        print('Base de datos local limpiada');
      } catch (e) {
        print('Error limpiando base de datos local: $e');
      }
      
      print('Total de emociones eliminadas: $totalDeleted');
      return true;
    } catch (e) {
      print('Error eliminando todas las emociones: $e');
      return false;
    }
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    required String course,
    required String documentId,
    required String avatarAsset,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return false;

      // Crear documento en Firestore
      final appUser = AppUser(
        uid: user.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        role: role,
        course: course,
        documentId: documentId,
        avatarAsset: avatarAsset,
      );

      await _db.collection('users').doc(user.uid).set(appUser.toMap());
      
      // Index auxiliar para login por documento
      await _db.collection('documents_index').doc(documentId).set({'uid': user.uid});
      
      return true;
    } catch (e) {
      print('Error creando usuario: $e');
      return false;
    }
  }

  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final userData = doc.data()!;
        return userData['role'] == 'administrador';
      }
      return false;
    } catch (e) {
      print('Error verificando rol de administrador: $e');
      return false;
    }
  }

  Future<void> createAdminUser() async {
    try {
      final adminQuery = await _db
          .collection('users')
          .where('documentId', isEqualTo: 'AdminJhon')
          .get();

      if (adminQuery.docs.isNotEmpty) {
        print('El usuario administrador ya existe');
        return;
      }

      final adminUser = AppUser(
        uid: 'admin_uid',
        email: 'admin@appsocioemocional.com',
        firstName: 'Admin',
        lastName: 'Jhon',
        role: 'administrador',
        course: 'Administración',
        documentId: 'AdminJhon',
        avatarAsset: 'assets/avatars/avatar1.svg',
      );

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: adminUser.email,
        password: 'Angel135*',
      );

      final updatedAdminUser = adminUser.copyWith(uid: userCredential.user!.uid);
      await _db.collection('users').doc(updatedAdminUser.uid).set(updatedAdminUser.toMap());
      await _db.collection('documents_index').doc('AdminJhon').set({'uid': updatedAdminUser.uid});

      print('Usuario administrador creado exitosamente');
    } catch (e) {
      print('Error creando usuario administrador: $e');
    }
  }
}


