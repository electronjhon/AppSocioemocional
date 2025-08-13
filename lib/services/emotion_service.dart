import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/emotion_record.dart';
import 'local_database_service.dart';
import 'connectivity_service.dart';

class EmotionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final ConnectivityService _connectivity = ConnectivityService();

  // Registrar emoción localmente y sincronizar si hay conexión
  Future<void> recordEmotion({
    required String studentUid,
    required String emotion,
    String? note,
  }) async {
    final now = DateTime.now().toUtc();
    final dayKey = DateFormat('yyyy-MM-dd').format(now);
    
    final emotionRecord = EmotionRecord(
      studentUid: studentUid,
      emotion: emotion,
      note: note,
      createdAt: now,
      dayKey: dayKey,
      isSynced: false,
    );

    // Guardar localmente
    await _localDb.insertEmotion(emotionRecord);

    // Intentar sincronizar si hay conexión
    if (await _connectivity.checkConnectivity()) {
      await _syncToFirebase(emotionRecord);
    }
  }

  // Sincronizar emoción a Firebase
  Future<void> _syncToFirebase(EmotionRecord emotion) async {
    try {
      await _db
          .collection('students')
          .doc(emotion.studentUid)
          .collection('emotions')
          .add({
        'emotion': emotion.emotion,
        'note': emotion.note,
        'createdAt': emotion.createdAt,
        'dayKey': emotion.dayKey,
      });
      
      // Marcar como sincronizado
      if (emotion.id != null) {
        await _localDb.markAsSynced(emotion.id!);
      }
    } catch (e) {
      print('Error syncing to Firebase: $e');
      // La emoción permanecerá como no sincronizada para intentar más tarde
    }
  }

  // Sincronizar todas las emociones no sincronizadas
  Future<void> syncUnsyncedEmotions() async {
    if (!await _connectivity.checkConnectivity()) {
      return; // No hay conexión
    }

    final unsyncedEmotions = await _localDb.getUnsyncedEmotions();
    
    for (final emotion in unsyncedEmotions) {
      await _syncToFirebase(emotion);
    }
  }

  // Obtener emociones del estudiante (local + Firebase si hay conexión)
  Stream<List<EmotionRecord>> watchStudentEmotions(String studentUid) async* {
    // Primero emitir datos locales
    final localEmotions = await _localDb.getEmotionsByStudent(studentUid);
    yield localEmotions;

    // Si hay conexión, intentar sincronizar y obtener datos actualizados
    if (await _connectivity.checkConnectivity()) {
      await syncUnsyncedEmotions();
      
      // Obtener datos actualizados de Firebase
      final firebaseStream = _db
          .collection('students')
          .doc(studentUid)
          .collection('emotions')
          .orderBy('createdAt', descending: true)
          .snapshots();

      await for (final snapshot in firebaseStream) {
        final firebaseEmotions = snapshot.docs.map((doc) {
          final data = doc.data();
          return EmotionRecord(
            id: doc.id,
            studentUid: studentUid,
            emotion: data['emotion'] as String,
            note: data['note'] as String?,
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            dayKey: data['dayKey'] as String,
            isSynced: true,
          );
        }).toList();

        // Combinar datos locales y de Firebase
        final allEmotions = [...localEmotions, ...firebaseEmotions];
        // Eliminar duplicados basándose en createdAt
        final uniqueEmotions = <EmotionRecord>[];
        final seenDates = <DateTime>{};
        
        for (final emotion in allEmotions) {
          if (!seenDates.contains(emotion.createdAt)) {
            uniqueEmotions.add(emotion);
            seenDates.add(emotion.createdAt);
          }
        }
        
        // Ordenar por fecha descendente
        uniqueEmotions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield uniqueEmotions;
      }
    }
  }

  // Obtener estadísticas locales del estudiante
  Future<Map<String, int>> getStudentEmotionStats(String studentUid) async {
    return await _localDb.getEmotionStats(studentUid);
  }

  // Obtener conteo de emociones locales
  Future<int> getStudentEmotionCount(String studentUid) async {
    return await _localDb.getEmotionCount(studentUid);
  }

  // Obtener todas las emociones locales del estudiante
  Future<List<EmotionRecord>> getLocalStudentEmotions(String studentUid) async {
    return await _localDb.getEmotionsByStudent(studentUid);
  }

  // Eliminar emoción local
  Future<void> deleteLocalEmotion(String emotionId) async {
    await _localDb.deleteEmotion(emotionId);
  }

  // Limpiar todas las emociones locales
  Future<void> clearLocalEmotions() async {
    await _localDb.clearAllEmotions();
  }

  // Obtener estudiantes del curso (solo Firebase)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchCourseStudents(String course) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'estudiante')
        .where('course', isEqualTo: course)
        .snapshots();
  }

  // Verificar si hay emociones no sincronizadas
  Future<bool> hasUnsyncedEmotions() async {
    final unsynced = await _localDb.getUnsyncedEmotions();
    return unsynced.isNotEmpty;
  }

  // Obtener emociones no sincronizadas
  Future<List<EmotionRecord>> getUnsyncedEmotions() async {
    return await _localDb.getUnsyncedEmotions();
  }
}


