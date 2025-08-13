import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class SessionProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _currentUserProfile;
  User? _firebaseUser;
  bool _initialized = false;

  SessionProvider(this._authService) {
    _authService.authStateChanges().listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        _currentUserProfile = await _authService.getProfileByUid(user.uid);
      } else {
        _currentUserProfile = null;
      }
      _initialized = true;
      notifyListeners();
    });
  }

  bool get isInitialized => _initialized;
  AppUser? get profile => _currentUserProfile;
  User? get firebaseUser => _firebaseUser;
  bool get isLoggedIn => _firebaseUser != null && _currentUserProfile != null;
}


