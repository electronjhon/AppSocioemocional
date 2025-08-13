import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    await _auth.signOut();
  }
}


