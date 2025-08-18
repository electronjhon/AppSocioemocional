import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/session_provider.dart';
import '../../services/emotion_service.dart';
import '../../services/notification_service.dart';
import '../../models/emotion_record.dart';
import '../../models/notification_message.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/school_logo.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/notification_badge.dart';
import '../../widgets/notification_toast.dart';
import '../../widgets/whatsapp_button.dart';
import '../../widgets/virtual_pet.dart';
import '../notifications_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _emotions = const ['Feliz', 'Triste', 'Enojado', 'Ansioso', 'Calmado'];
  String? _selected;
  final EmotionService _emotionService = EmotionService();
  final NotificationService _notificationService = NotificationService();
  int _todayEmotionCount = 0;
  bool _canRecordMore = true;
  final TextEditingController _noteController = TextEditingController();
  List<NotificationMessage> _previousNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadTodayEmotionCount();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _listenToNotifications() {
    final session = context.read<SessionProvider>();
    if (session.profile != null) {
      _notificationService.watchUserNotifications(session.profile!.uid).listen((notifications) {
        if (mounted) {
          // Verificar si hay nuevas notificaciones no leídas
          final newUnreadNotifications = notifications
              .where((notification) => 
                  !notification.isRead && 
                  !_previousNotifications.any((prev) => prev.id == notification.id))
              .toList();
          
          // Mostrar toast para cada nueva notificación
          for (final notification in newUnreadNotifications) {
            NotificationToast.show(
              context,
              notification,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            );
          }
          
          _previousNotifications = notifications;
        }
      });
    }
  }

  Future<void> _loadTodayEmotionCount() async {
    final session = context.read<SessionProvider>();
    if (session.profile != null) {
      final count = await _emotionService.getTodayEmotionCount(session.profile!.uid);
      final canRecord = await _emotionService.canRecordEmotion(session.profile!.uid);
      if (mounted) {
        setState(() {
          _todayEmotionCount = count;
          _canRecordMore = canRecord;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    
    // Si no hay sesión o perfil, mostrar loading
    if (!session.isLoggedIn || session.profile == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final user = session.profile!;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(
              avatarAsset: user.avatarAsset,
              size: 32.0,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Hola, ${user.firstName}'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        actions: [
          NotificationBadge(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          WhatsAppButton(
            userName: '${user.firstName} ${user.lastName}',
            userDocument: user.documentId,
            userCourse: user.course,
          ),
        ],
      ),
      drawer: AppDrawer(
        user: user,
        emotionService: _emotionService,
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '¿Cómo te sientes hoy?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _canRecordMore ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_todayEmotionCount/3',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Botones de emociones en una sola fila
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _emotions.map((e) {
                    final selected = _selected == e;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selected = e;
                            _noteController.clear(); // Limpiar nota al cambiar emoción
                          });
                        },
                        icon: Icon(
                          _getEmotionIcon(e),
                          color: Colors.white,
                        ),
                        label: Text(e),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selected 
                              ? _colorForEmotion(e) 
                              : _colorForEmotion(e).withOpacity(0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: selected ? 4 : 2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              // Campo de texto para la nota (solo visible si hay emoción seleccionada)
              if (_selected != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _colorForEmotion(_selected!).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Por qué te sientes $_selected?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _colorForEmotion(_selected!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        maxLength: 200,
                        decoration: const InputDecoration(
                          hintText: 'Escribe aquí el motivo de tu emoción...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!_canRecordMore)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Registra nuevas emociones mañana.',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!_canRecordMore) const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selected == null || !_canRecordMore)
                      ? null
                      : () async {
                          try {
                            await _emotionService.recordEmotion(
                              studentUid: user.uid,
                              emotion: _selected!,
                              note: _noteController.text.trim(),
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Emoción "${_selected!}" registrada'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {
                                _selected = null;
                                _noteController.clear();
                              });
                              // Actualizar el contador
                              await _loadTodayEmotionCount();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00BCD4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _canRecordMore ? 'Registrar Emoción' : 'Límite alcanzado (3/día)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Resumen hasta Hoy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<EmotionRecord>>(
                stream: _emotionService.watchStudentEmotions(user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final emotions = snapshot.data!;
                  if (emotions.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sentiment_neutral, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No hay registros de emociones',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // Conteo para gráfica circular
                  final Map<String, int> counts = {};
                  for (final emotion in emotions) {
                    counts.update(emotion.emotion, (v) => v + 1, ifAbsent: () => 1);
                  }
                  
                  // Asegurar que todas las emociones estén representadas
                  for (final emotion in _emotions) {
                    if (!counts.containsKey(emotion)) {
                      counts[emotion] = 0;
                    }
                  }
                  
                  final sections = counts.entries.map((e) {
                    final color = _colorForEmotion(e.key);
                    return PieChartSectionData(
                      color: color,
                      value: e.value.toDouble(),
                      title: e.value > 0 ? '${e.value}' : '',
                      radius: 60,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();

                  return Column(
                    children: [
                      SizedBox(
                        height: 280,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Distribución de Emociones',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Row(
                                    children: [
                                      // Gráfica circular
                                      Expanded(
                                        flex: 2,
                                        child: PieChart(
                                          PieChartData(
                                            sections: sections,
                                            sectionsSpace: 2,
                                            centerSpaceRadius: 40,
                                            borderData: FlBorderData(show: false),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Leyenda
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: _emotions.map((emotion) {
                                            final count = counts[emotion] ?? 0;
                                            final color = _colorForEmotion(emotion);
                                            return Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 4),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 16,
                                                    height: 16,
                                                    decoration: BoxDecoration(
                                                      color: color,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      emotion,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '$count',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 320,
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mascota Virtual',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Reacciona según tu emoción predominante',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        VirtualPet(
                                          dominantEmotion: _getDominantEmotion(emotions),
                                          totalEmotions: emotions.length,
                                        ),
                                        const SizedBox(height: 20),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          child: Text(
                                            _getPetMessage(_getDominantEmotion(emotions)),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Total de registros: ${emotions.length}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60), // Espacio adicional al final
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDominantEmotion(List<EmotionRecord> emotions) {
    if (emotions.isEmpty) return 'calmado';

    // Contar cada emoción
    Map<String, int> emotionCounts = {};
    for (final emotion in emotions) {
      emotionCounts[emotion.emotion] = (emotionCounts[emotion.emotion] ?? 0) + 1;
    }

    // Encontrar la emoción más frecuente
    String dominantEmotion = 'calmado';
    int maxCount = 0;

    emotionCounts.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantEmotion = emotion;
      }
    });

    return dominantEmotion;
  }

  String _getPetMessage(String dominantEmotion) {
    switch (dominantEmotion.toLowerCase()) {
      case 'feliz':
        return '¡Estoy muy feliz de verte! 😊\nSigue registrando emociones positivas';
      case 'triste':
        return 'Estoy aquí para acompañarte... 💙\nEs normal sentirse triste a veces';
      case 'enojado':
        return 'Respira profundo... 😤\nLa calma te ayudará a sentirte mejor';
      case 'ansioso':
        return 'Tranquilo, todo estará bien... 😰\nRespira y relájate';
      case 'calmado':
        return 'Me siento muy tranquilo contigo 😌\nMantén esa paz interior';
      default:
        return '¡Hola! Soy tu mascota virtual 🐾\nRegistra tus emociones para conocerme mejor';
    }
  }

  Color _colorForEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'feliz':
        return Colors.orangeAccent;
      case 'triste':
        return Colors.blueAccent;
      case 'enojado':
        return Colors.redAccent;
      case 'ansioso':
        return Colors.purpleAccent;
      case 'calmado':
        return Colors.greenAccent;
      default:
        return Colors.teal;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'feliz':
        return Icons.sentiment_very_satisfied;
      case 'triste':
        return Icons.sentiment_very_dissatisfied;
      case 'enojado':
        return Icons.sentiment_dissatisfied;
      case 'ansioso':
        return Icons.sentiment_neutral;
      case 'calmado':
        return Icons.sentiment_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
}


