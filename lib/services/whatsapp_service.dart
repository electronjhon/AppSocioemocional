import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static const String _whatsappNumberKey = 'whatsapp_contact_number';
  static const String _defaultWhatsAppNumber = '+573193046233';

  // Obtener el número de WhatsApp configurado
  static Future<String> getWhatsAppNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_whatsappNumberKey) ?? _defaultWhatsAppNumber;
  }

  // Configurar el número de WhatsApp
  static Future<bool> setWhatsAppNumber(String number) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_whatsappNumberKey, number);
    } catch (e) {
      print('Error configurando número de WhatsApp: $e');
      return false;
    }
  }

  // Enviar mensaje por WhatsApp
  static Future<bool> sendWhatsAppMessage({
    String? message,
    String? customNumber,
    String? userName,
    String? userDocument,
    String? userCourse,
  }) async {
    try {
      final number = customNumber ?? await getWhatsAppNumber();
      final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Construir el mensaje completo con información del usuario
      String fullMessage = '';
      
      // Agregar información del usuario si está disponible
      if (userName != null || userDocument != null || userCourse != null) {
        fullMessage += '👤 *Información del Usuario:*\n';
        if (userName != null) fullMessage += '• Nombre: $userName\n';
        if (userDocument != null) fullMessage += '• Documento: $userDocument\n';
        if (userCourse != null) fullMessage += '• Curso: $userCourse\n';
        fullMessage += '\n';
      }
      
      // Agregar el mensaje personalizado
      if (message != null && message.isNotEmpty) {
        fullMessage += '💬 *Mensaje:*\n$message';
      } else {
        fullMessage += '💬 *Mensaje:*\nHola, necesito ayuda con la aplicación AppSocioemocional.';
      }
      
      // Construir la URL de WhatsApp
      String whatsappUrl = 'https://wa.me/$cleanNumber';
      final encodedMessage = Uri.encodeComponent(fullMessage);
      whatsappUrl += '?text=$encodedMessage';

      print('Intentando abrir WhatsApp con URL: $whatsappUrl');
      
      final uri = Uri.parse(whatsappUrl);
      
      // Verificar si se puede abrir WhatsApp
      if (!await canLaunchUrl(uri)) {
        print('No se puede abrir WhatsApp con la URL: $whatsappUrl');
        return false;
      }

      // Intentar abrir WhatsApp
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      print('WhatsApp abierto exitosamente');
      return true;
      
    } catch (e) {
      print('Error enviando mensaje por WhatsApp: $e');
      return false;
    }
  }

  // Validar formato de número de teléfono
  static bool isValidPhoneNumber(String number) {
    // Patrón para números de teléfono internacionales
    final phonePattern = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phonePattern.hasMatch(number.replaceAll(RegExp(r'[^\d+]'), ''));
  }

  // Formatear número de teléfono para mostrar
  static String formatPhoneNumber(String number) {
    final cleanNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanNumber.startsWith('+57')) {
      // Formato para Colombia
      final withoutCountry = cleanNumber.substring(3);
      if (withoutCountry.length == 10) {
        return '+57 ${withoutCountry.substring(0, 3)} ${withoutCountry.substring(3, 6)} ${withoutCountry.substring(6)}';
      }
    }
    
    return cleanNumber;
  }
}
