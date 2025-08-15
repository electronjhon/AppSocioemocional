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
  Future<bool> recordEmotion({
    required String studentUid,
    required String emotion,
    String? note,
  }) async {
    // Verificar si se puede registrar una nueva emoción
    if (!await canRecordEmotion(studentUid)) {
      throw Exception('Ya has registrado el máximo de 3 emociones para hoy');
    }

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

    return true;
  }

  // Sincronizar emoción a Firebase
  Future<void> _syncToFirebase(EmotionRecord emotion) async {
    try {
      final docRef = await _db
          .collection('students')
          .doc(emotion.studentUid)
          .collection('emotions')
          .add({
        'emotion': emotion.emotion,
        'note': emotion.note,
        'createdAt': emotion.createdAt,
        'dayKey': emotion.dayKey,
      });
      
      // Marcar como sincronizado con el ID de Firebase
      if (emotion.id != null) {
        await _localDb.markAsSynced(emotion.id!);
        // Actualizar el ID local con el ID de Firebase
        await _localDb.updateEmotionId(emotion.id!, docRef.id);
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

        // Combinar datos locales y de Firebase eliminando duplicados
        final allEmotions = <EmotionRecord>[];
        final seenIds = <String>{};
        final seenTimestamps = <DateTime>{};
        
        // Agregar emociones locales no sincronizadas
        for (final emotion in localEmotions) {
          if (!emotion.isSynced) {
            allEmotions.add(emotion);
            seenTimestamps.add(emotion.createdAt);
          }
        }
        
        // Agregar emociones de Firebase, evitando duplicados
        for (final emotion in firebaseEmotions) {
          if (!seenTimestamps.contains(emotion.createdAt)) {
            allEmotions.add(emotion);
            seenTimestamps.add(emotion.createdAt);
          }
        }
        
        // Ordenar por fecha descendente
        allEmotions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield allEmotions;
      }
    }
  }

  // Eliminar emoción (local y Firebase si está sincronizada)
  Future<void> deleteEmotion(EmotionRecord emotion) async {
    if (emotion.id != null) {
      // Si está sincronizada, eliminar primero de Firebase
      if (emotion.isSynced && await _connectivity.checkConnectivity()) {
        try {
          await _db
              .collection('students')
              .doc(emotion.studentUid)
              .collection('emotions')
              .doc(emotion.id)
              .delete();
        } catch (e) {
          print('Error deleting from Firebase: $e');
          // Continuar con la eliminación local aunque falle Firebase
        }
      }
      
      // Intentar eliminar de la base de datos local usando múltiples estrategias
      bool deleted = false;
      
      // Estrategia 1: Intentar eliminar por ID directo
      try {
        final rowsAffected = await _localDb.deleteEmotion(emotion.id!);
        if (rowsAffected > 0) {
          deleted = true;
          print('Successfully deleted by ID: ${emotion.id}');
        }
      } catch (e) {
        print('Failed to delete by ID: $e');
      }
      
      // Estrategia 2: Si no se pudo eliminar por ID, usar criterios múltiples
      if (!deleted) {
        try {
          final rowsAffected = await _localDb.deleteEmotionByMultipleCriteria(
            studentUid: emotion.studentUid,
            emotion: emotion.emotion,
            createdAt: emotion.createdAt,
            dayKey: emotion.dayKey,
          );
          if (rowsAffected > 0) {
            deleted = true;
            print('Successfully deleted by multiple criteria');
          }
        } catch (e) {
          print('Failed to delete by multiple criteria: $e');
        }
      }
      
      // Estrategia 3: Último recurso - eliminar por timestamp
      if (!deleted) {
        try {
          final rowsAffected = await _localDb.deleteEmotionByTimestamp(emotion.studentUid, emotion.createdAt);
          if (rowsAffected > 0) {
            deleted = true;
            print('Successfully deleted by timestamp');
          } else {
            print('No rows affected when deleting by timestamp');
          }
        } catch (e) {
          print('Failed to delete by timestamp: $e');
        }
      }
      
      if (!deleted) {
        throw Exception('No se pudo eliminar el registro de emoción');
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

  // Eliminar emoción local (método legacy - usar deleteEmotion en su lugar)
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

  // Verificar si se puede registrar una nueva emoción (máximo 3 por día)
  Future<bool> canRecordEmotion(String studentUid) async {
    final now = DateTime.now().toUtc();
    final dayKey = DateFormat('yyyy-MM-dd').format(now);
    final count = await _localDb.getEmotionCountForDay(studentUid, dayKey);
    return count < 3;
  }

  // Obtener el conteo de emociones para el día actual
  Future<int> getTodayEmotionCount(String studentUid) async {
    final now = DateTime.now().toUtc();
    final dayKey = DateFormat('yyyy-MM-dd').format(now);
    return await _localDb.getEmotionCountForDay(studentUid, dayKey);
  }
}


