import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/session_provider.dart';
import '../widgets/school_logo.dart';

import 'login_screen.dart';
import 'student/student_home_screen.dart';
import 'teacher/teacher_home_screen.dart';
import 'admin/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2)); // Splash delay

    if (!mounted) return;

    // Esperar a que el SessionProvider esté inicializado
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Usar SessionProvider para obtener el estado de autenticación
    final sessionProvider = context.read<SessionProvider>();
    
    // Esperar a que el SessionProvider se inicialice completamente
    int attempts = 0;
    while (!sessionProvider.isInitialized && attempts < 50) { // Máximo 5 segundos
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
      if (!mounted) return;
    }

    if (!mounted) return;

    // Verificar si el usuario está autenticado
    if (!sessionProvider.isLoggedIn) {
      print('Usuario no autenticado, navegando a LoginScreen');
      _navigateToLogin();
      return;
    }

    // Obtener el perfil del usuario desde el SessionProvider
    final appUser = sessionProvider.profile;
    if (appUser == null) {
      print('Perfil de usuario no encontrado, navegando a LoginScreen');
      _navigateToLogin();
      return;
    }

    if (!mounted) return;

    print('Usuario autenticado: ${appUser.role}, navegando a pantalla correspondiente');

    // Navegar según el rol del usuario
    switch (appUser.role.toLowerCase()) {
      case 'estudiante':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StudentHomeScreen(),
          ),
        );
        break;
      case 'docente':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TeacherHomeScreen(),
          ),
        );
        break;
      case 'administrador':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AdminHomeScreen(user: appUser),
          ),
        );
        break;
      default:
        _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00BCD4),
              Color(0xFF8BC34A),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SchoolLogo(size: 120.0),
              const SizedBox(height: 24),
              const Text(
                'App Socioemocional',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Institución Educativa Departamental\nPbro. Carlos Garavito A.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestionando emociones, construyendo bienestar',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


