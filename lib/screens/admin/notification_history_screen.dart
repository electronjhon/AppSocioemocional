import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_message.dart';
import '../../services/notification_service.dart';
import '../../providers/session_provider.dart';
import '../../widgets/gradient_background.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isDeleting = false;

  Future<void> _deleteNotification(String notificationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar píldora'),
        content: const Text('¿Estás seguro de que quieres eliminar esta píldora? Esta acción eliminará la píldora de todos los usuarios que la recibieron.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final success = await _notificationService.deleteSentNotification(notificationId);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Píldora eliminada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {}); // Refrescar la lista
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al eliminar la píldora'),
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
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  Future<void> _deleteAllNotifications(String senderUid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todas las píldoras'),
        content: const Text('¿Estás seguro de que quieres eliminar TODAS las píldoras enviadas? Esta acción no se puede deshacer y eliminará todas las píldoras de todos los usuarios.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar todas'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        final success = await _notificationService.deleteAllSentNotifications(senderUid);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Todas las píldoras eliminadas exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {}); // Refrescar la lista
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error al eliminar las píldoras'),
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
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final currentUser = session.profile;

    print('Usuario actual en historial: ${currentUser?.uid} - ${currentUser?.firstName} ${currentUser?.lastName}');

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Píldoras'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        actions: [
          if (!_isDeleting)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete_all') {
                  _deleteAllNotifications(currentUser.uid);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar todas', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          if (_isDeleting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: GradientBackground(
        child: FutureBuilder<List<NotificationMessage>>(
          future: _notificationService.getSentNotifications(currentUser.uid),
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
                      'No hay píldoras enviadas',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Las píldoras que envíes aparecerán aquí',
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
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.notifications_active,
                              color: Color(0xFF00BCD4),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(
                                notification.createdAt.toLocal(),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                                                 const SizedBox(height: 8),
                         Text(
                           notification.message,
                           style: const TextStyle(fontSize: 14),
                         ),
                         if (notification.url != null && notification.url!.isNotEmpty) ...[
                           const SizedBox(height: 8),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.blue.shade50,
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(color: Colors.blue.shade200),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 const Icon(
                                   Icons.link,
                                   size: 16,
                                   color: Colors.blue,
                                 ),
                                 const SizedBox(width: 4),
                                 Flexible(
                                   child: Text(
                                     notification.url!,
                                     style: const TextStyle(
                                       fontSize: 12,
                                       color: Colors.blue,
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ],
                                                 const SizedBox(height: 12),
                         Row(
                           children: [
                             Expanded(
                               child: Wrap(
                                 spacing: 8,
                                 children: [
                                   Chip(
                                     label: Text('Roles: ${notification.targetRoles.join(', ')}'),
                                     backgroundColor: Colors.blue.shade100,
                                   ),
                                   if (notification.targetCourses.isNotEmpty)
                                     Chip(
                                       label: Text('Cursos: ${notification.targetCourses.join(', ')}'),
                                       backgroundColor: Colors.green.shade100,
                                     ),
                                   if (notification.recipientUid != null)
                                     const Chip(
                                       label: Text('Usuario específico'),
                                       backgroundColor: Colors.orange,
                                       labelStyle: TextStyle(color: Colors.white),
                                     ),
                                 ],
                               ),
                             ),
                             if (!_isDeleting && notification.id != null)
                               IconButton(
                                 onPressed: () => _deleteNotification(notification.id!),
                                 icon: const Icon(Icons.delete, color: Colors.red),
                                 tooltip: 'Eliminar píldora',
                               ),
                           ],
                         ),
                      ],
                    ),
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
