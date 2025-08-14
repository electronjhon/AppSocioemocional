import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/emotion_service.dart';
import '../services/connectivity_service.dart';
import '../services/google_drive_service.dart';
import '../screens/student/emotion_history_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../providers/session_provider.dart';

class AppDrawer extends StatefulWidget {
  final AppUser user;
  final EmotionService emotionService;
  
  const AppDrawer({
    super.key,
    required this.user,
    required this.emotionService,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isConnected = true;
  bool _hasUnsyncedData = false;
  bool _isSignedInToGoogle = false;
  final ConnectivityService _connectivity = ConnectivityService();
  final GoogleDriveService _driveService = GoogleDriveService();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final isConnected = await _connectivity.checkConnectivity();
    final hasUnsynced = await widget.emotionService.hasUnsyncedEmotions();
    final isSignedInToGoogle = await _driveService.isSignedIn();
    
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
        _hasUnsyncedData = hasUnsynced;
        _isSignedInToGoogle = isSignedInToGoogle;
      });
    }
  }

  Future<void> _syncNow() async {
    if (!_isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sin conexión a internet'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      await widget.emotionService.syncUnsyncedEmotions();
      await _checkStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos sincronizados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

    Future<void> _exportToGoogleDrive(String format) async {
    if (!_isSignedInToGoogle) {
      try {
        final success = await _driveService.signIn();
        if (!success) {
          throw Exception('No se pudo conectar con Google Drive');
        }
        if (mounted) {
          setState(() {
            _isSignedInToGoogle = true;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al conectar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    try {
      final emotions = await widget.emotionService.getLocalStudentEmotions(widget.user.uid);
      
      if (emotions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay datos para exportar'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (format == 'csv') {
        await _driveService.exportEmotionsToDrive(emotions, widget.user);
      } else {
        await _driveService.exportJsonToDrive(emotions, widget.user);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos exportados a Google Drive (${format.toUpperCase()})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        await AuthService().signOut();
        
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
    return Drawer(
      child: Column(
        children: [
          // Header del drawer
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF00BCD4), Color(0xFF8BC34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    '${widget.user.firstName[0]}${widget.user.lastName[0]}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00BCD4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.user.firstName} ${widget.user.lastName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.user.role == 'estudiante' ? 'Estudiante' : 'Docente',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Curso: ${widget.user.course}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Estado de conexión
          ListTile(
            leading: Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            title: Text(_isConnected ? 'Conectado' : 'Sin conexión'),
            subtitle: _hasUnsyncedData 
                ? const Text('Datos pendientes de sincronizar', style: TextStyle(color: Colors.orange))
                : null,
            trailing: _hasUnsyncedData && _isConnected
                ? IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: _syncNow,
                    tooltip: 'Sincronizar ahora',
                  )
                : null,
          ),
          
          const Divider(),
          
          // Historial de emociones
          ListTile(
            leading: const Icon(Icons.history, color: Colors.blue),
            title: const Text('Historial de Emociones'),
            subtitle: const Text('Ver registro temporal'),
            onTap: () {
              Navigator.of(context).pop(); // Cerrar drawer
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EmotionHistoryScreen(
                    user: widget.user,
                    emotionService: widget.emotionService,
                  ),
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Sección de Google Drive
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Google Drive',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          
          ListTile(
            leading: Icon(
              _isSignedInToGoogle ? Icons.cloud_done : Icons.cloud_off,
              color: _isSignedInToGoogle ? Colors.green : Colors.grey,
            ),
            title: const Text('Estado de conexión'),
            subtitle: Text(_isSignedInToGoogle ? 'Conectado' : 'No conectado'),
          ),
          
          if (!_isSignedInToGoogle)
            ListTile(
              leading: const Icon(Icons.login, color: Colors.blue),
              title: const Text('Conectar con Google Drive'),
              onTap: () async {
                try {
                  final success = await _driveService.signIn();
                  if (mounted) {
                    setState(() {
                      _isSignedInToGoogle = success;
                    });
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Conectado a Google Drive'),
                          backgroundColor: Colors.green,
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
              },
            ),
          
          if (_isSignedInToGoogle) ...[
            ListTile(
              leading: const Icon(Icons.file_download, color: Colors.green),
              title: const Text('Exportar CSV'),
              subtitle: const Text('Para análisis en Excel'),
              onTap: () => _exportToGoogleDrive('csv'),
            ),
            
            ListTile(
              leading: const Icon(Icons.code, color: Colors.orange),
              title: const Text('Exportar JSON'),
              subtitle: const Text('Respaldo completo'),
              onTap: () => _exportToGoogleDrive('json'),
            ),
            
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Desconectar Google Drive'),
              onTap: () async {
                await _driveService.signOut();
                if (mounted) {
                  setState(() {
                    _isSignedInToGoogle = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Desconectado de Google Drive'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
            ),
          ],
          
          const Spacer(),
          
          const Divider(),
          
          // Cerrar sesión
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Cerrar sesión'),
            onTap: _signOut,
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
