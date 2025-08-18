import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/notification_message.dart';

class NotificationToast extends StatelessWidget {
  final NotificationMessage notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationToast({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  Future<void> _launchUrl(String url) async {
    try {
      print('Intentando abrir URL desde toast: $url');
      
      // Asegurar que la URL tenga el protocolo correcto
      String processedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        processedUrl = 'https://$url';
      }
      
      final uri = Uri.parse(processedUrl);
      print('URI procesada desde toast: $uri');
      
      // Intentar diferentes modos de lanzamiento
      bool launched = false;
      
      // Primero intentar con LaunchMode.externalApplication
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          print('URL abierta exitosamente desde toast con LaunchMode.externalApplication');
        }
      } catch (e) {
        print('Error con LaunchMode.externalApplication desde toast: $e');
      }
      
      // Si falla, intentar con LaunchMode.platformDefault
      if (!launched) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
            launched = true;
            print('URL abierta exitosamente desde toast con LaunchMode.platformDefault');
          }
        } catch (e) {
          print('Error con LaunchMode.platformDefault desde toast: $e');
        }
      }
      
      // Si aún falla, intentar con LaunchMode.inAppWebView
      if (!launched) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.inAppWebView);
            launched = true;
            print('URL abierta exitosamente desde toast con LaunchMode.inAppWebView');
          }
        } catch (e) {
          print('Error con LaunchMode.inAppWebView desde toast: $e');
        }
      }
      
      if (!launched) {
        print('No se pudo abrir la URL desde toast con ningún modo');
      }
      
    } catch (e) {
      print('Error abriendo URL desde toast: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BCD4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                                             const SizedBox(height: 4),
                       Text(
                         'De: ${notification.senderName}',
                         style: const TextStyle(
                           fontSize: 10,
                           color: Colors.grey,
                         ),
                       ),
                       if (notification.url != null && notification.url!.isNotEmpty) ...[
                         const SizedBox(height: 4),
                         InkWell(
                           onTap: () => _launchUrl(notification.url!),
                           child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               const Icon(
                                 Icons.link,
                                 size: 12,
                                 color: Color(0xFF00BCD4),
                               ),
                               const SizedBox(width: 4),
                               Text(
                                 'Ver enlace',
                                 style: const TextStyle(
                                   fontSize: 10,
                                   color: Color(0xFF00BCD4),
                                   fontWeight: FontWeight.w500,
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ],
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void show(
    BuildContext context,
    NotificationMessage notification, {
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: NotificationToast(
          notification: notification,
          onTap: () {
            overlayEntry.remove();
            if (onTap != null) onTap();
          },
          onDismiss: () {
            overlayEntry.remove();
          },
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
