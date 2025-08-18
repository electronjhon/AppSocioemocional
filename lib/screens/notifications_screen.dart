import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notification_message.dart';
import '../services/notification_service.dart';
import '../providers/session_provider.dart';
import '../widgets/gradient_background.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _markingAllAsRead = false;

  Future<void> _markAllAsRead() async {
    final session = context.read<SessionProvider>();
    final currentUser = session.profile;
    
    if (currentUser == null) return;

    setState(() {
      _markingAllAsRead = true;
    });

    try {
      await _notificationService.markAllAsRead(currentUser.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
            backgroundColor: Colors.green,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _markingAllAsRead = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final session = context.read<SessionProvider>();
    final currentUser = session.profile;
    
    if (currentUser == null) return;

    try {
      await _notificationService.markAsRead(currentUser.uid, notificationId);
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

  Future<void> _launchUrl(String url) async {
    try {
      print('Intentando abrir URL: $url');
      
      // Asegurar que la URL tenga el protocolo correcto
      String processedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        processedUrl = 'https://$url';
      }
      
      final uri = Uri.parse(processedUrl);
      print('URI procesada: $uri');
      
      // Intentar diferentes modos de lanzamiento
      bool launched = false;
      
      // Primero intentar con LaunchMode.externalApplication
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          print('URL abierta exitosamente con LaunchMode.externalApplication');
        }
      } catch (e) {
        print('Error con LaunchMode.externalApplication: $e');
      }
      
      // Si falla, intentar con LaunchMode.platformDefault
      if (!launched) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
            launched = true;
            print('URL abierta exitosamente con LaunchMode.platformDefault');
          }
        } catch (e) {
          print('Error con LaunchMode.platformDefault: $e');
        }
      }
      
      // Si aún falla, intentar con LaunchMode.inAppWebView
      if (!launched) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
            launched = true;
            print('URL abierta exitosamente con LaunchMode.inAppWebView');
          }
        } catch (e) {
          print('Error con LaunchMode.inAppWebView: $e');
        }
      }
      
      if (!launched) {
        throw Exception('No se pudo abrir la URL con ningún modo');
      }
      
    } catch (e) {
      print('Error abriendo URL: $e');
      if (mounted) {
        // Mostrar diálogo con opciones
        await _showUrlErrorDialog(url);
      }
    }
  }

  Future<void> _showUrlErrorDialog(String url) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No se pudo abrir el enlace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('La aplicación no pudo abrir automáticamente el enlace.'),
            const SizedBox(height: 8),
            Text(
              'URL: $url',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Si estás usando un emulador, asegúrate de tener un navegador instalado.'),
            const SizedBox(height: 8),
            const Text('¿Qué deseas hacer?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('copy'),
            child: const Text('Copiar URL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('try_again'),
            child: const Text('Intentar de nuevo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('open_browser'),
            child: const Text('Abrir en navegador'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    switch (result) {
      case 'copy':
        // Copiar URL al portapapeles
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('URL copiada al portapapeles'),
              backgroundColor: Colors.green,
            ),
          );
        }
        break;
      case 'try_again':
        // Intentar abrir de nuevo
        _launchUrl(url);
        break;
      case 'open_browser':
        // Intentar abrir específicamente en navegador
        try {
          final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
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
        break;
      case 'cancel':
      default:
        // No hacer nada
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final currentUser = session.profile;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Píldoras'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        actions: [
          StreamBuilder<List<NotificationMessage>>(
            stream: _notificationService.watchUserNotifications(currentUser.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final unreadCount = snapshot.data!
                  .where((notification) => !notification.isRead)
                  .length;
              
              if (unreadCount == 0) return const SizedBox.shrink();
              
              return TextButton(
                onPressed: _markingAllAsRead ? null : _markAllAsRead,
                child: _markingAllAsRead
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Marcar todo como leído',
                        style: TextStyle(color: Colors.white),
                      ),
              );
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: StreamBuilder<List<NotificationMessage>>(
          stream: _notificationService.watchUserNotifications(currentUser.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!;
            
            if (notifications.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No hay píldoras',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Las píldoras enviadas por los administradores aparecerán aquí',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: notification.isRead ? 2 : 4,
                  color: notification.isRead 
                      ? Colors.white 
                      : Colors.blue.shade50,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead 
                          ? Colors.grey 
                          : const Color(0xFF00BCD4),
                      child: Icon(
                        notification.isRead 
                            ? Icons.notifications 
                            : Icons.notifications_active,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead 
                            ? FontWeight.normal 
                            : FontWeight.bold,
                        color: notification.isRead 
                            ? Colors.grey.shade700 
                            : Colors.black87,
                      ),
                    ),
                                         subtitle: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const SizedBox(height: 8),
                         Text(
                           notification.message,
                           style: TextStyle(
                             color: notification.isRead 
                                 ? Colors.grey.shade600 
                                 : Colors.black87,
                           ),
                         ),
                         if (notification.url != null && notification.url!.isNotEmpty) ...[
                           const SizedBox(height: 8),
                           InkWell(
                             onTap: () => _launchUrl(notification.url!),
                             child: Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(
                                 color: const Color(0xFF00BCD4).withOpacity(0.1),
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(
                                   color: const Color(0xFF00BCD4).withOpacity(0.3),
                                 ),
                               ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   const Icon(
                                     Icons.link,
                                     size: 16,
                                     color: Color(0xFF00BCD4),
                                   ),
                                   const SizedBox(width: 4),
                                   Flexible(
                                     child: Text(
                                       'Ver enlace',
                                       style: const TextStyle(
                                         fontSize: 12,
                                         color: Color(0xFF00BCD4),
                                         fontWeight: FontWeight.w500,
                                       ),
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ),
                         ],
                         const SizedBox(height: 8),
                         Row(
                           children: [
                             Icon(
                               Icons.person,
                               size: 16,
                               color: Colors.grey.shade600,
                             ),
                             const SizedBox(width: 4),
                             Text(
                               notification.senderName,
                               style: TextStyle(
                                 fontSize: 12,
                                 color: Colors.grey.shade600,
                               ),
                             ),
                             const Spacer(),
                             Text(
                               DateFormat('dd/MM/yyyy HH:mm').format(
                                 notification.createdAt.toLocal(),
                               ),
                               style: TextStyle(
                                 fontSize: 12,
                                 color: Colors.grey.shade600,
                               ),
                             ),
                           ],
                         ),
                       ],
                     ),
                                         trailing: PopupMenuButton<String>(
                       onSelected: (value) {
                         if (value == 'read' && !notification.isRead) {
                           _markAsRead(notification.id!);
                         }
                       },
                       itemBuilder: (context) => [
                         if (!notification.isRead)
                           const PopupMenuItem(
                             value: 'read',
                             child: Row(
                               children: [
                                 Icon(Icons.mark_email_read),
                                 SizedBox(width: 8),
                                 Text('Marcar como leída'),
                               ],
                             ),
                           ),
                       ],
                     ),
                    onTap: () {
                      if (!notification.isRead) {
                        _markAsRead(notification.id!);
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
