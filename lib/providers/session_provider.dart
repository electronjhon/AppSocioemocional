import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class SessionProvider extends ChangeNotifier {
  final AuthService _authService;
  AppUser? _currentUserProfile;
  User? _firebaseUser;
  bool _initialized = false;
  StreamSubscription<User?>? _authSubscription;
  bool _isSigningOut = false;

  SessionProvider(this._authService) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _authSubscription = _authService.authStateChanges().listen((user) async {
      // Si estamos en proceso de cierre de sesión, no procesar cambios
      if (_isSigningOut) return;
      
      _firebaseUser = user;
      if (user != null) {
        try {
          _currentUserProfile = await _authService.getProfileByUid(user.uid);
        } catch (e) {
          print('Error obteniendo perfil de usuario: $e');
          _currentUserProfile = null;
        }
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

  // Método para limpiar el estado manualmente
  void clearSession() {
    _currentUserProfile = null;
    _firebaseUser = null;
    notifyListeners();
  }

  // Método para limpiar el estado sin activar listeners (para cierre de sesión)
  void clearSessionSilently() {
    _currentUserProfile = null;
    _firebaseUser = null;
    // No llamar notifyListeners() para evitar interferencias
  }

  // Método para preparar el cierre de sesión
  void prepareForSignOut() {
    _isSigningOut = true;
    _currentUserProfile = null;
    _firebaseUser = null;
  }

  // Método para restaurar el listener después del cierre de sesión
  void restoreAfterSignOut() {
    _isSigningOut = false;
    _initialized = false;
    _initializeAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}


