import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isConnected = true;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    // Verificar estado inicial
    final result = await _connectivity.checkConnectivity();
    _isConnected = result != ConnectivityResult.none;

    // Escuchar cambios de conectividad
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = result != ConnectivityResult.none;
    return _isConnected;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
