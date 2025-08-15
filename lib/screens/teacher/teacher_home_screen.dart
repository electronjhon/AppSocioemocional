import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/session_provider.dart';
import '../../services/emotion_service.dart';
import '../../models/emotion_record.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/school_logo.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

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
    final emotionService = EmotionService();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SchoolLogo(size: 32.0, showBorder: false),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Hola, ${user.firstName}'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(
        user: user,
        emotionService: emotionService,
      ),
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Curso: ${user.course}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: emotionService.watchCourseStudents(user.course),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final students = snapshot.data!.docs;
                  if (students.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Sin estudiantes registrados',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (_, i) {
                      final s = students[i].data();
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF00BCD4),
                            child: Text(
                              '${s['firstName']?[0] ?? ''}${s['lastName']?[0] ?? ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Doc: ${s['documentId']} - Curso: ${s['course']}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _StudentDetailScreen(
                                  studentUid: s['uid'] as String,
                                  documentId: s['documentId'] as String,
                                  studentName: '${s['firstName'] ?? ''} ${s['lastName'] ?? ''}',
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: students.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentDetailScreen extends StatelessWidget {
  final String studentUid;
  final String documentId;
  final String studentName;
  
  const _StudentDetailScreen({
    required this.studentUid,
    required this.documentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final emotionService = EmotionService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Estudiante: $studentName'),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: StreamBuilder<List<EmotionRecord>>(
          stream: emotionService.watchStudentEmotions(studentUid),
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
                      'Sin registros de emociones',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final Map<String, int> counts = {};
            for (final emotion in emotions) {
              counts.update(emotion.emotion, (v) => v + 1, ifAbsent: () => 1);
            }
            
            // Asegurar que todas las emociones estén representadas
            final allEmotions = ['Feliz', 'Triste', 'Enojado', 'Ansioso', 'Calmado'];
            for (final emotion in allEmotions) {
              if (!counts.containsKey(emotion)) {
                counts[emotion] = 0;
              }
            }
            
            final sections = counts.entries.map((e) => PieChartSectionData(
                  color: _colorForEmotion(e.key),
                  value: e.value.toDouble(),
                  title: e.value > 0 ? '${e.value}' : '',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                )).toList();

            return Column(
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  height: 280,
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                                    children: allEmotions.map((emotion) {
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
                Expanded(
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Registros de Emociones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: emotions.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (_, i) {
                              final emotion = emotions[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _colorForEmotion(emotion.emotion),
                                  child: Icon(
                                    _getEmotionIcon(emotion.emotion),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  emotion.emotion,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emotion.createdAt.toLocal().toString().split('.')[0],
                                    ),
                                    if (emotion.note != null && emotion.note!.isNotEmpty)
                                      Text(
                                        'Nota: ${emotion.note}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: !emotion.isSynced
                                    ? const Icon(
                                        Icons.cloud_off,
                                        color: Colors.orange,
                                        size: 16,
                                      )
                                    : null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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


