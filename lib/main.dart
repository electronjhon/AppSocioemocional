import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/session_provider.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Inicializar servicio de conectividad
  await ConnectivityService().initialize();
  
  runApp(const AppSocioemocional());
}

class AppSocioemocional extends StatelessWidget {
  const AppSocioemocional({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider(AuthService())),
      ],
      child: MaterialApp(
        title: 'App Socioemocional',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF00BCD4),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
