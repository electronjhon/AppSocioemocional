import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import 'login_screen.dart';
import 'teacher/teacher_home_screen.dart';
import 'student/student_home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (!session.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!session.isLoggedIn) {
          return const LoginScreen();
        }
        final role = session.profile!.role;
        if (role == 'docente') return const TeacherHomeScreen();
        return const StudentHomeScreen();
      },
    );
  }
}


