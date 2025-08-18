import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notification_message.dart';
import '../models/app_user.dart';
import 'local_database_service.dart';
import 'connectivity_service.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Enviar notificación desde administrador
  Future<bool> sendNotification({
    required String title,
    required String message,
    String? url,
    required String senderUid,
    required String senderName,
    required List<String> targetRoles,
    List<String> targetCourses = const [],
    String? specificRecipientUid,
  }) async {
    try {
             final notification = NotificationMessage(
         title: title,
         message: message,
         url: url,
         senderUid: senderUid,
         senderName: senderName,
         createdAt: DateTime.now().toUtc(),
         targetRoles: targetRoles,
         targetCourses: targetCourses,
         recipientUid: specificRecipientUid,
       );

      // Guardar en Firebase
      print('Guardando notificación en Firebase...');
      final notificationData = notification.toMap();
      print('Datos de notificación: $notificationData');
      
      final docRef = await _db.collection('notifications').add(notificationData);
      print('Notificación guardada con ID: ${docRef.id}');
      
      // Actualizar con el ID generado
      await _db.collection('notifications').doc(docRef.id).update({
        'id': docRef.id,
      });
      print('ID actualizado en la notificación');

      // Si hay conexión, distribuir a usuarios objetivo
      if (await _connectivity.checkConnectivity()) {
        await _distributeNotification(notification.copyWith(id: docRef.id));
      }

      return true;
    } catch (e) {
      print('Error enviando notificación: $e');
      return false;
    }
  }

  // Distribuir notificación a usuarios objetivo
  Future<void> _distributeNotification(NotificationMessage notification) async {
    try {
      Query query = _db.collection('users');
      
      // Filtrar por roles
      if (notification.targetRoles.isNotEmpty) {
        query = query.where('role', whereIn: notification.targetRoles);
      }
      
      // Filtrar por cursos si se especifica
      if (notification.targetCourses.isNotEmpty) {
        query = query.where('course', whereIn: notification.targetCourses);
      }

      final usersSnapshot = await query.get();
      
      // Crear notificaciones para cada usuario objetivo
      final batch = _db.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final userUid = userData['uid'] as String;
        
        // Verificar si es un destinatario específico
        if (notification.recipientUid != null && 
            notification.recipientUid != userUid) {
          continue;
        }

        // Crear notificación personal para el usuario
        final userNotification = notification.copyWith(
          recipientUid: userUid,
          isRead: false,
        );

        final userNotificationRef = _db
            .collection('users')
            .doc(userUid)
            .collection('notifications')
            .doc();

        batch.set(userNotificationRef, userNotification.toMap());
      }
      
      await batch.commit();
    } catch (e) {
      print('Error distribuyendo notificación: $e');
    }
  }

  // Obtener notificaciones del usuario (stream en tiempo real)
  Stream<List<NotificationMessage>> watchUserNotifications(String userUid) {
    return _db
        .collection('users')
        .doc(userUid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationMessage.fromMap(doc.data()))
            .toList());
  }

  // Obtener notificaciones no leídas del usuario
  Future<List<NotificationMessage>> getUnreadNotifications(String userUid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .where('isRead', isEqualTo: 0)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => NotificationMessage.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error obteniendo notificaciones no leídas: $e');
      return [];
    }
  }

  // Contar notificaciones no leídas
  Future<int> getUnreadCount(String userUid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .where('isRead', isEqualTo: 0)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error contando notificaciones no leídas: $e');
      return 0;
    }
  }

  // Marcar notificación como leída
  Future<bool> markAsRead(String userUid, String notificationId) async {
    try {
      print('Marcando notificación como leída: $notificationId para usuario: $userUid');
      
      // Buscar la notificación por el ID original
      final querySnapshot = await _db
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .where('id', isEqualTo: notificationId)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final docRef = querySnapshot.docs.first.reference;
        await docRef.update({'isRead': 1});
        print('Notificación marcada como leída exitosamente');
        return true;
      } else {
        // Si no se encuentra por ID, intentar directamente con el notificationId
        await _db
            .collection('users')
            .doc(userUid)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': 1});
        print('Notificación marcada como leída exitosamente (método directo)');
        return true;
      }
    } catch (e) {
      print('Error marcando notificación como leída: $e');
      return false;
    }
  }

  // Marcar todas las notificaciones como leídas
  Future<bool> markAllAsRead(String userUid) async {
    try {
      print('Marcando todas las notificaciones como leídas para usuario: $userUid');
      
      // Obtener todas las notificaciones no leídas
      final unreadSnapshot = await _db
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .where('isRead', isEqualTo: 0)
          .get();
      
      if (unreadSnapshot.docs.isEmpty) {
        print('No hay notificaciones no leídas para marcar');
        return true;
      }
      
      final batch = _db.batch();
      
      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'isRead': 1});
      }
      
      await batch.commit();
      print('Todas las notificaciones marcadas como leídas exitosamente');
      return true;
    } catch (e) {
      print('Error marcando todas las notificaciones como leídas: $e');
      return false;
    }
  }

  // Eliminar notificación de usuario
  Future<bool> deleteNotification(String userUid, String notificationId) async {
    try {
      await _db
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      return true;
    } catch (e) {
      print('Error eliminando notificación: $e');
      return false;
    }
  }

  // Eliminar notificación del historial (solo para administradores)
  Future<bool> deleteSentNotification(String notificationId) async {
    try {
      print('Eliminando notificación del historial: $notificationId');
      
      // Eliminar de la colección principal
      await _db.collection('notifications').doc(notificationId).delete();
      
      // Eliminar de todos los usuarios que la recibieron
      final usersSnapshot = await _db.collection('users').get();
      final batch = _db.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        final userNotificationsSnapshot = await _db
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .where('id', isEqualTo: notificationId)
            .get();
        
        for (final notificationDoc in userNotificationsSnapshot.docs) {
          batch.delete(notificationDoc.reference);
        }
      }
      
      await batch.commit();
      print('Notificación eliminada del historial y de todos los usuarios');
      return true;
    } catch (e) {
      print('Error eliminando notificación del historial: $e');
      return false;
    }
  }

  // Eliminar todas las notificaciones enviadas por un administrador
  Future<bool> deleteAllSentNotifications(String senderUid) async {
    try {
      print('Eliminando todas las notificaciones enviadas por: $senderUid');
      
      // Obtener todas las notificaciones enviadas
      final sentNotifications = await getSentNotifications(senderUid);
      
      if (sentNotifications.isEmpty) {
        print('No hay notificaciones para eliminar');
        return true;
      }
      
      // Eliminar de la colección principal
      final batch = _db.batch();
      for (final notification in sentNotifications) {
        if (notification.id != null) {
          batch.delete(_db.collection('notifications').doc(notification.id));
        }
      }
      await batch.commit();
      
      // Eliminar de todos los usuarios
      final usersSnapshot = await _db.collection('users').get();
      final userBatch = _db.batch();
      
      for (final userDoc in usersSnapshot.docs) {
        for (final notification in sentNotifications) {
          if (notification.id != null) {
            final userNotificationsSnapshot = await _db
                .collection('users')
                .doc(userDoc.id)
                .collection('notifications')
                .where('id', isEqualTo: notification.id)
                .get();
            
            for (final notificationDoc in userNotificationsSnapshot.docs) {
              userBatch.delete(notificationDoc.reference);
            }
          }
        }
      }
      
      await userBatch.commit();
      print('Todas las notificaciones eliminadas exitosamente');
      return true;
    } catch (e) {
      print('Error eliminando todas las notificaciones: $e');
      return false;
    }
  }

  // Obtener todas las notificaciones enviadas por un administrador
  Future<List<NotificationMessage>> getSentNotifications(String senderUid) async {
    try {
      print('Buscando notificaciones enviadas por: $senderUid');
      
      // Primero intentar con ordenamiento
      try {
        final snapshot = await _db
            .collection('notifications')
            .where('senderUid', isEqualTo: senderUid)
            .orderBy('createdAt', descending: true)
            .get();

        print('Encontradas ${snapshot.docs.length} notificaciones enviadas');
        
        final notifications = snapshot.docs
            .map((doc) {
              print('Documento encontrado: ${doc.data()}');
              return NotificationMessage.fromMap(doc.data());
            })
            .toList();
        
        print('Notificaciones procesadas: ${notifications.length}');
        return notifications;
      } catch (orderError) {
        print('Error con ordenamiento, intentando sin ordenar: $orderError');
        
        // Si falla el ordenamiento, intentar sin ordenar
        final snapshot = await _db
            .collection('notifications')
            .where('senderUid', isEqualTo: senderUid)
            .get();

        print('Encontradas ${snapshot.docs.length} notificaciones enviadas (sin ordenar)');
        
        final notifications = snapshot.docs
            .map((doc) {
              print('Documento encontrado: ${doc.data()}');
              return NotificationMessage.fromMap(doc.data());
            })
            .toList();
        
        // Ordenar manualmente
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        print('Notificaciones procesadas: ${notifications.length}');
        return notifications;
      }
    } catch (e) {
      print('Error obteniendo notificaciones enviadas: $e');
      return [];
    }
  }

  // Verificar disponibilidad de navegadores
  Future<bool> checkBrowserAvailability() async {
    try {
      // Probar con una URL simple
      final testUri = Uri.parse('https://www.google.com');
      return await canLaunchUrl(testUri);
    } catch (e) {
      print('Error verificando disponibilidad de navegador: $e');
      return false;
    }
  }

  // Abrir URL con múltiples intentos
  Future<bool> openUrl(String url) async {
    try {
      print('Servicio: Intentando abrir URL: $url');
      
      // Asegurar que la URL tenga el protocolo correcto
      String processedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        processedUrl = 'https://$url';
      }
      
      final uri = Uri.parse(processedUrl);
      print('Servicio: URI procesada: $uri');
      
      // Verificar si se puede abrir
      if (!await canLaunchUrl(uri)) {
        print('Servicio: No se puede abrir la URL: $uri');
        return false;
      }
      
      // Intentar diferentes modos de lanzamiento
      List<LaunchMode> modes = [
        LaunchMode.externalApplication,
        LaunchMode.platformDefault,
        LaunchMode.inAppWebView,
      ];
      
      for (final mode in modes) {
        try {
          await launchUrl(uri, mode: mode);
          print('Servicio: URL abierta exitosamente con $mode');
          return true;
        } catch (e) {
          print('Servicio: Error con $mode: $e');
          continue;
        }
      }
      
      print('Servicio: No se pudo abrir la URL con ningún modo');
      return false;
      
    } catch (e) {
      print('Servicio: Error abriendo URL: $e');
      return false;
    }
  }

  // Obtener estadísticas de notificaciones
  Future<Map<String, dynamic>> getNotificationStats(String userUid) async {
    try {
      final totalSnapshot = await _db
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .count()
          .get();

      final unreadSnapshot = await _db
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .where('isRead', isEqualTo: 0)
          .count()
          .get();

      final totalCount = totalSnapshot.count ?? 0;
      final unreadCount = unreadSnapshot.count ?? 0;

      return {
        'total': totalCount,
        'unread': unreadCount,
        'read': totalCount - unreadCount,
      };
    } catch (e) {
      print('Error obteniendo estadísticas de notificaciones: $e');
      return {'total': 0, 'unread': 0, 'read': 0};
    }
  }
}
