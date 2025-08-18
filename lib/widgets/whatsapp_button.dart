import 'package:flutter/material.dart';
import '../services/whatsapp_service.dart';

class WhatsAppButton extends StatelessWidget {
  final String? customMessage;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? userName;
  final String? userDocument;
  final String? userCourse;

  const WhatsAppButton({
    super.key,
    this.customMessage,
    this.backgroundColor,
    this.iconColor,
    this.userName,
    this.userDocument,
    this.userCourse,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _showWhatsAppDialog(context),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.message,
          color: iconColor ?? Colors.white,
          size: 20,
        ),
      ),
      tooltip: 'Contactar por WhatsApp',
    );
  }

  Future<void> _showWhatsAppDialog(BuildContext context) async {
    final TextEditingController messageController = TextEditingController(
      text: customMessage ?? 'Hola, necesito ayuda con la aplicación AppSocioemocional.',
    );

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.message,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Contactar por WhatsApp'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escribe tu mensaje:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Se incluirá automáticamente: ${userName ?? 'N/A'}, Doc: ${userDocument ?? 'N/A'}, Curso: ${userCourse ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Escribe tu mensaje aquí...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: WhatsAppService.getWhatsAppNumber(),
              builder: (context, snapshot) {
                final number = snapshot.data ?? '+573193046233';
                return Text(
                  'Se enviará a: ${WhatsAppService.formatPhoneNumber(number)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop({
                'message': messageController.text.trim(),
              });
            },
            icon: const Icon(Icons.send),
            label: const Text('Enviar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null && result['message'] != null) {
      final success = await WhatsAppService.sendWhatsAppMessage(
        message: result['message']!,
        userName: userName,
        userDocument: userDocument,
        userCourse: userCourse,
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp abierto exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp. Asegúrate de tener la aplicación instalada.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
