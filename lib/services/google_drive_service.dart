import 'dart:convert';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/emotion_record.dart';
import '../models/app_user.dart';

class GoogleDriveService {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/userinfo.email',
  ];

  GoogleSignIn? _googleSignIn;
  drive.DriveApi? _driveApi;

  GoogleDriveService() {
    _googleSignIn = GoogleSignIn(scopes: _scopes);
  }

  Future<bool> isSignedIn() async {
    return await _googleSignIn!.isSignedIn();
  }

  Future<bool> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn!.signIn();
      if (account != null) {
        await account.authentication;
        _driveApi = drive.DriveApi(http.Client());
        return true;
      }
      return false;
    } catch (e) {
      print('Error signing in to Google: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn!.signOut();
    _driveApi = null;
  }

  Future<String?> exportEmotionsToDrive(
    List<EmotionRecord> emotions,
    AppUser user,
  ) async {
    if (_driveApi == null) {
      final signedIn = await signIn();
      if (!signedIn) {
        throw Exception('No se pudo autenticar con Google Drive');
      }
    }

    try {
      // Crear contenido CSV
      final csvContent = _generateCsvContent(emotions, user);
      final fileName = 'emociones_${user.firstName}_${user.lastName}_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      // Crear archivo en Drive
      final file = drive.File()
        ..name = fileName
        ..parents = ['root']
        ..mimeType = 'text/csv';

      final media = drive.Media(
        Stream.value(utf8.encode(csvContent)),
        csvContent.length,
      );

      final createdFile = await _driveApi!.files.create(file, uploadMedia: media);
      return createdFile.id;
    } catch (e) {
      print('Error exporting to Drive: $e');
      rethrow;
    }
  }

  Future<String?> exportJsonToDrive(
    List<EmotionRecord> emotions,
    AppUser user,
  ) async {
    if (_driveApi == null) {
      final signedIn = await signIn();
      if (!signedIn) {
        throw Exception('No se pudo autenticar con Google Drive');
      }
    }

    try {
      // Crear contenido JSON
      final jsonData = {
        'user': {
          'uid': user.uid,
          'documentId': user.documentId,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'course': user.course,
          'role': user.role,
        },
        'exportDate': DateTime.now().toIso8601String(),
        'totalRecords': emotions.length,
        'emotions': emotions.map((e) => {
          'id': e.id,
          'emotion': e.emotion,
          'note': e.note,
          'createdAt': e.createdAt.toIso8601String(),
          'dayKey': e.dayKey,
          'isSynced': e.isSynced,
        }).toList(),
      };

      final jsonContent = jsonEncode(jsonData);
      final fileName = 'emociones_${user.firstName}_${user.lastName}_${DateTime.now().millisecondsSinceEpoch}.json';
      
      // Crear archivo en Drive
      final file = drive.File()
        ..name = fileName
        ..parents = ['root']
        ..mimeType = 'application/json';

      final media = drive.Media(
        Stream.value(utf8.encode(jsonContent)),
        jsonContent.length,
      );

      final createdFile = await _driveApi!.files.create(file, uploadMedia: media);
      return createdFile.id;
    } catch (e) {
      print('Error exporting JSON to Drive: $e');
      rethrow;
    }
  }

  String _generateCsvContent(List<EmotionRecord> emotions, AppUser user) {
    final buffer = StringBuffer();
    
    // Encabezados
    buffer.writeln('Usuario,Documento,Nombre,Apellido,Curso,Emoción,Nota,Fecha,Código_Día,Sincronizado');
    
    // Datos
    for (final emotion in emotions) {
      buffer.writeln([
        user.uid,
        user.documentId,
        user.firstName,
        user.lastName,
        user.course,
        emotion.emotion,
        emotion.note ?? '',
        emotion.createdAt.toIso8601String(),
        emotion.dayKey,
        emotion.isSynced ? 'Sí' : 'No',
      ].map((field) => '"${field.replaceAll('"', '""')}"').join(','));
    }
    
    return buffer.toString();
  }

  Future<List<drive.File>> listExportedFiles() async {
    if (_driveApi == null) {
      throw Exception('No autenticado con Google Drive');
    }

    try {
      final response = await _driveApi!.files.list(
        q: "name contains 'emociones_' and trashed = false",
        orderBy: 'createdTime desc',
      );
      return response.files ?? [];
    } catch (e) {
      print('Error listing files: $e');
      rethrow;
    }
  }

  Future<void> deleteExportedFile(String fileId) async {
    if (_driveApi == null) {
      throw Exception('No autenticado con Google Drive');
    }

    try {
      await _driveApi!.files.delete(fileId);
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }
}
