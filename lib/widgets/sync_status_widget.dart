import 'package:flutter/material.dart';
import '../services/emotion_service.dart';
import '../services/connectivity_service.dart';

class SyncStatusWidget extends StatefulWidget {
  final EmotionService emotionService;
  
  const SyncStatusWidget({
    super.key,
    required this.emotionService,
  });

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  bool _isSyncing = false;
  bool _hasUnsyncedData = false;
  bool _isConnected = true;
  final ConnectivityService _connectivity = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final hasUnsynced = await widget.emotionService.hasUnsyncedEmotions();
    final isConnected = await _connectivity.checkConnectivity();
    
    if (mounted) {
      setState(() {
        _hasUnsyncedData = hasUnsynced;
        _isConnected = isConnected;
      });
    }
  }

  Future<void> _syncNow() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sin conexión a internet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _isConnected ? Icons.wifi : Icons.wifi_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isConnected ? 'Conectado' : 'Sin conexión',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_hasUnsyncedData)
                    Text(
                      'Datos pendientes de sincronizar',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
            if (_hasUnsyncedData && _isConnected)
              ElevatedButton.icon(
                onPressed: _isSyncing ? null : _syncNow,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
