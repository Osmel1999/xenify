import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xenify/domain/entities/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colección de usuarios
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Guardar perfil de usuario
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _usersCollection.doc(profile.uid).set(profile.toJson());
    } catch (e) {
      print('Error al guardar perfil de usuario: $e');
      rethrow;
    }
  }

  // Obtener perfil de usuario
  Future<UserProfile?> getUserProfile(String uid) async {
    print('📡 FirestoreService - Iniciando obtención de perfil para UID: $uid');
    try {
      print('🔍 FirestoreService - Buscando documento en colección users...');
      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists) {
        print('⚠️ FirestoreService - No existe documento para el UID: $uid');
        return null;
      }

      if (doc.data() == null) {
        print(
            '⚠️ FirestoreService - Documento existe pero está vacío para UID: $uid');
        return null;
      }

      print(
          '✅ FirestoreService - Documento encontrado, intentando deserializar...');
      final data = doc.data() as Map<String, dynamic>;
      print('📄 FirestoreService - Datos raw del documento: $data');

      final profile = UserProfile.fromJson(data);
      print('✅ FirestoreService - Perfil deserializado exitosamente');
      return profile;
    } catch (e) {
      print('❌ FirestoreService - Error al obtener perfil de usuario: $e');
      print('❌ FirestoreService - Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Actualizar el último inicio de sesión
  Future<void> updateUserLastLogin(String uid, DateTime lastLogin) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLoginAt': lastLogin.toIso8601String(),
      });
    } catch (e) {
      print('Error al actualizar último inicio de sesión: $e');
      rethrow;
    }
  }

  // Marcar que el usuario completó el cuestionario inicial
  Future<void> markInitialQuestionnaireCompleted(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'completedInitialQuestionnaire': true,
      });
    } catch (e) {
      print('Error al marcar cuestionario como completado: $e');
      rethrow;
    }
  }

  // Nuevo método para actualizar campos específicos del perfil de usuario
  Future<void> updateUserProfileFields(
      String uid, Map<String, dynamic> fields) async {
    try {
      // Convertir cualquier objeto complejo a formato JSON si es necesario
      final fieldsToUpdate = _prepareFieldsForFirestore(fields);

      // Actualizar solo los campos especificados
      await _usersCollection.doc(uid).update(fieldsToUpdate);

      print('Campos actualizados con éxito: ${fields.keys.join(', ')}');
    } catch (e) {
      print('Error al actualizar campos del perfil: $e');
      rethrow;
    }
  }

  // Guardar respuestas del cuestionario inicial
  Future<void> saveQuestionnaireAnswers(
      String uid, Map<String, dynamic> answers) async {
    try {
      print('📝 Guardando respuestas del cuestionario en Firestore');
      await _usersCollection.doc(uid).update({
        'initialQuestionnaire': answers,
        'questionnaireCompletedAt': DateTime.now().toIso8601String(),
      });
      print('✅ Respuestas del cuestionario guardadas exitosamente');
    } catch (e) {
      print('❌ Error al guardar respuestas del cuestionario: $e');
      rethrow;
    }
  }

  // Método auxiliar para preparar campos para Firestore
  Map<String, dynamic> _prepareFieldsForFirestore(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};

    fields.forEach((key, value) {
      if (value is DateTime) {
        // Convertir DateTime a String ISO8601
        result[key] = value.toIso8601String();
      } else if (value is Iterable) {
        // Convertir iterables a listas
        result[key] = value.toList();
      } else if (value is Map) {
        // Convertir mapas anidados recursivamente
        result[key] = _prepareFieldsForFirestore(value as Map<String, dynamic>);
      } else {
        // Mantener otros tipos sin cambios
        result[key] = value;
      }
    });

    return result;
  }

  // Método para actualizar el perfil completo
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _usersCollection.doc(profile.uid).update(profile.toJson());
    } catch (e) {
      print('Error al actualizar perfil de usuario: $e');
      rethrow;
    }
  }
}
