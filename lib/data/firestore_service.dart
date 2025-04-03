import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:xenify/domain/entities/user_profile.dart';

/// Servicio para gestionar operaciones con Firestore
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Colección de usuarios
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Obtener el perfil de usuario desde Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      print('🔍 FirestoreService - Buscando perfil con uid: $uid');
      final docSnapshot = await _usersCollection.doc(uid).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        print('✅ FirestoreService - Perfil encontrado en Firestore');
        final data = docSnapshot.data() as Map<String, dynamic>;
        return UserProfile.fromJson({
          ...data,
          'uid': uid, // Asegurar que el uid esté presente
        });
      }

      print(
          '⚠️ FirestoreService - No existe perfil en Firestore para uid: $uid');
      return null;
    } catch (e) {
      print('❌ FirestoreService - Error obteniendo perfil: $e');
      return null;
    }
  }

  /// Guardar o actualizar un perfil de usuario
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await _usersCollection.doc(profile.uid).set(
            profile.toJson(),
            SetOptions(merge: true),
          );
      print('✅ FirestoreService - Perfil guardado correctamente');
    } catch (e) {
      print('❌ FirestoreService - Error guardando perfil: $e');
      rethrow;
    }
  }

  /// Actualizar la última fecha de inicio de sesión del usuario
  Future<void> updateUserLastLogin(String uid, DateTime loginTime) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLoginAt': loginTime.toIso8601String(),
      });
      print(
          '✅ FirestoreService - Última fecha de inicio de sesión actualizada');
    } catch (e) {
      print(
          '❌ FirestoreService - Error actualizando fecha de inicio de sesión: $e');
      rethrow;
    }
  }

  /// Guardar respuestas del cuestionario inicial y marcar como completado
  Future<void> saveQuestionnaireAnswersAndComplete(
      String uid, Map<String, dynamic> answers) async {
    try {
      await _usersCollection.doc(uid).update({
        'initialQuestionnaire': answers,
        'completedInitialQuestionnaire': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      });
      print(
          '✅ FirestoreService - Cuestionario inicial guardado y marcado como completado');
    } catch (e) {
      print('❌ FirestoreService - Error guardando cuestionario: $e');
      rethrow;
    }
  }

  /// Actualizar campos específicos del perfil de usuario
  Future<void> updateUserProfileFields(
      String uid, Map<String, dynamic> fields) async {
    try {
      await _usersCollection.doc(uid).update(fields);
      print('✅ FirestoreService - Campos del perfil actualizados');
    } catch (e) {
      print('❌ FirestoreService - Error actualizando campos: $e');
      rethrow;
    }
  }

  /// Verificar si el setup inicial está completado
  Future<bool> isInitialSetupCompleted(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['completedInitialQuestionnaire'] == true;
      }
      return false;
    } catch (e) {
      print('❌ FirestoreService - Error verificando setup inicial: $e');
      return false;
    }
  }
}
