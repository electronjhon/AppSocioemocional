import 'package:flutter/material.dart';
import '../services/google_drive_service.dart';
import '../services/emotion_service.dart';
import '../models/app_user.dart';

class ExportWidget extends StatefulWidget {
  final AppUser user;
  final EmotionService emotionService;
  
  const ExportWidget({
    super.key,
    required this.user,
    required this.emotionService,
  });

  @override
  State<ExportWidget> createState() => _ExportWidgetState();
}

class _ExportWidgetState extends State<ExportWidget> {
  final GoogleDriveService _driveService = GoogleDriveService();
  bool _isExporting = false;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    final signedIn = await _driveService.isSignedIn();
    if (mounted) {
      setState(() {
        _isSignedIn = signedIn;
      });
    }
  }

  Future<void> _signInToGoogle() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final success = await _driveService.signIn();
      if (mounted) {
        setState(() {
          _isSignedIn = success;
        });
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conectado a Google Drive'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al conectar con Google Drive'),
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
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _exportToCSV() async {
    await _exportData('csv');
  }

  Future<void> _exportToJSON() async {
    await _exportData('json');
  }

  Future<void> _exportData(String format) async {
    if (!_isSignedIn) {
      await _signInToGoogle();
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // Obtener todas las emociones locales
      final emotions = await widget.emotionService.getLocalStudentEmotions(widget.user.uid);
      
      if (emotions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay datos para exportar'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      String? fileId;
      if (format == 'csv') {
        fileId = await _driveService.exportEmotionsToDrive(emotions, widget.user);
      } else {
        fileId = await _driveService.exportJsonToDrive(emotions, widget.user);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Datos exportados a Google Drive (${format.toUpperCase()})'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver',
              onPressed: () => _openInDrive(fileId),
            ),
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
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _openInDrive(String? fileId) {
    if (fileId != null) {
      // Abrir en Google Drive web
      // En una implementación real, podrías usar url_launcher
      print('Abrir archivo en Drive: $fileId');
    }
  }

  Future<void> _signOut() async {
    await _driveService.signOut();
    if (mounted) {
      setState(() {
        _isSignedIn = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desconectado de Google Drive'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                  color: _isSignedIn ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Exportar a Google Drive',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_isSignedIn)
              ElevatedButton.icon(
                onPressed: _isExporting ? null : _signInToGoogle,
                icon: _isExporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(_isExporting ? 'Conectando...' : 'Conectar con Google Drive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportToCSV,
                      icon: const Icon(Icons.file_download),
                      label: const Text('Exportar CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportToJSON,
                      icon: const Icon(Icons.code),
                      label: const Text('Exportar JSON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Desconectar'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
            if (_isExporting)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
