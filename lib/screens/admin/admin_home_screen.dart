import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/school_logo.dart';
import '../../screens/login_screen.dart';
import '../../providers/session_provider.dart';
import 'package:provider/provider.dart';
import 'user_management_screen.dart';
import 'create_user_screen.dart';
import 'send_notification_screen.dart';
import 'notification_history_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final AppUser user;
  
  const AdminHomeScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthService _authService = AuthService();







  Future<void> _deleteAllEmotions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Emociones'),
        content: const Text('¿Estás seguro de que quieres eliminar TODAS las emociones de TODOS los usuarios?\n\nEsta acción es irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _authService.deleteAllEmotions();
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Todas las emociones han sido eliminadas'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al eliminar todas las emociones'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Mostrar indicador de carga
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Preparar el SessionProvider para el cierre de sesión
        final sessionProvider = context.read<SessionProvider>();
        sessionProvider.prepareForSignOut();

        // Cerrar sesión de Firebase
        await _authService.signOut();
        
        // Cerrar el diálogo de carga
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Navegar directamente a la pantalla de login
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }

        // Restaurar el SessionProvider después de un breve delay
        Future.delayed(const Duration(milliseconds: 500), () {
          sessionProvider.restoreAfterSignOut();
        });
        
      } catch (e) {
        // Cerrar el diálogo de carga si hay error
        if (mounted) {
          Navigator.of(context).pop();
          
          // Mostrar mensaje de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                '${widget.user.firstName[0]}${widget.user.lastName[0]}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00BCD4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Panel de Administración'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: GradientBackground(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido, ${widget.user.firstName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00BCD4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Panel de Administración',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Acciones administrativas
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acciones Administrativas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.person_add,
                              title: 'Agregar Usuario',
                              subtitle: '',
                              color: Colors.green,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CreateUserScreen(
                                      authService: _authService,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.people,
                              title: 'Gestionar Usuarios',
                              subtitle: '',
                              color: Colors.blue,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UserManagementScreen(
                                      authService: _authService,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.delete_sweep,
                              title: 'Eliminar Total Registros',
                              subtitle: '',
                              color: Colors.red,
                              onTap: _deleteAllEmotions,
                            ),
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.notifications_active,
                              title: 'Enviar Píldora',
                              subtitle: 'Enviar notificación a estudiantes',
                              color: Colors.orange,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SendNotificationScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.history,
                              title: 'Historial de Píldoras',
                              subtitle: 'Ver notificaciones enviadas',
                              color: Colors.purple,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const NotificationHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
