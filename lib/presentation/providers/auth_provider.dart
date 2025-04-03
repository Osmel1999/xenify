import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/data/auth_service.dart';
import 'package:xenify/data/firestore_service.dart';
import 'package:xenify/data/daily_questionnaire_service.dart';
import 'package:xenify/data/local_storage.dart';
import 'package:xenify/domain/entities/user_profile.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';

// Provider del servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider del servicio de Firestore
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Provider del estado de autenticación
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Provider del perfil de usuario
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  print(
      '🔍 UserProfileProvider - Estado de autenticación: ${authState.value != null ? "Autenticado" : "No autenticado"}');

  // Si no hay usuario autenticado, retornar null
  if (authState.value == null) {
    print('❌ UserProfileProvider - Usuario no autenticado, retornando null');
    return null;
  }

  print(
      '👤 UserProfileProvider - Intentando obtener perfil desde almacenamiento local');

  try {
    // Intentar obtener el perfil desde el almacenamiento local
    final profile = await LocalStorage.loadUserProfile();
    final dailyQuestionnaireService =
        ref.watch(dailyQuestionnaireServiceProvider);

    if (profile != null) {
      print('✅ UserProfileProvider - Perfil obtenido desde local storage');
      // Sincronizar el estado del setup inicial
      await dailyQuestionnaireService
          .syncInitialSetupWithFirestore(profile.completedInitialQuestionnaire);
      return profile;
    }

    print('⚠️ UserProfileProvider - No se encontró perfil en local storage');

    // Si no hay perfil en local storage, intentar obtenerlo de Firestore
    print('🔄 UserProfileProvider - Intentando obtener perfil desde Firestore');
    final firestoreService = ref.read(firestoreServiceProvider);
    final uid = authState.value!.uid;

    final firestoreProfile = await firestoreService.getUserProfile(uid);

    if (firestoreProfile != null) {
      print('✅ UserProfileProvider - Perfil obtenido desde Firestore');
      // Guardar el perfil en el almacenamiento local para futuros accesos
      await LocalStorage.saveUserProfile(firestoreProfile);

      // Sincronizar el estado del setup inicial
      await dailyQuestionnaireService.syncInitialSetupWithFirestore(
          firestoreProfile.completedInitialQuestionnaire);

      return firestoreProfile;
    }

    print('❌ UserProfileProvider - No se encontró perfil en Firestore');
    return null;
  } catch (e) {
    print('❌ UserProfileProvider - Error al obtener perfil: $e');
    return null;
  }
});

// Notifier para gestionar el estado de autenticación
class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final DailyQuestionnaireService _dailyQuestionnaireService;
  final Ref _ref;
  UserProfile? _currentProfile;

  AuthNotifier(this._ref, this._authService, this._firestoreService,
      this._dailyQuestionnaireService)
      : super(AuthStatus.initial);

  // Getter para el perfil de usuario actual
  UserProfile? get currentProfile => _currentProfile;

  Future<UserProfile?> signInWithPlatform() async {
    try {
      state = AuthStatus.loading;
      final userProfile = await _authService.signInWithPlatform();

      if (userProfile != null) {
        _currentProfile = userProfile;

        // Guardar el perfil en el almacenamiento local
        await LocalStorage.saveUserProfile(userProfile);
        print('✅ Perfil guardado en almacenamiento local');

        // Verificar si el perfil requiere completarse
        if (_authService.profileRequiresCompletion(userProfile)) {
          state = AuthStatus.requiresCompletion;
        } else {
          state = AuthStatus.authenticated;
        }
      } else {
        state = AuthStatus.unauthenticated;
      }

      return userProfile;
    } catch (e) {
      state = AuthStatus.error;
      print('Error en AuthNotifier.signInWithPlatform: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      state = AuthStatus.loading;
      await _authService.signOut();
      _currentProfile = null;
      state = AuthStatus.unauthenticated;
    } catch (e) {
      state = AuthStatus.error;
      print('Error en AuthNotifier.signOut: $e');
      rethrow;
    }
  }

  Future<void> markInitialQuestionnaireCompleted(
      Map<String, dynamic> answers) async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        print(
            '🔄 Guardando cuestionario inicial y marcándolo como completado...');

        // Actualizar en Firestore con las respuestas y marcar como completado
        await _firestoreService.saveQuestionnaireAnswersAndComplete(
            user.uid, answers);

        // Actualizar el perfil en memoria
        if (_currentProfile != null) {
          _currentProfile =
              _currentProfile!.copyWith(completedInitialQuestionnaire: true);

          // Guardar el perfil actualizado en el almacenamiento local
          await LocalStorage.saveUserProfile(_currentProfile!);
          print('✅ Perfil actualizado guardado en almacenamiento local');
        }

        // Marcar el setup inicial como completado en DailyQuestionnaireService
        await _dailyQuestionnaireService.setInitialSetupCompleted(true);

        print('✅ Setup inicial guardado y marcado como completado');

        // Refrescar el provider del perfil
        _ref.refresh(userProfileProvider);
      }
    } catch (e) {
      print('❌ Error al guardar y marcar cuestionario como completado: $e');
      rethrow;
    }
  }

  // Nuevo método para actualizar campos específicos del perfil
  Future<void> updateUserProfileFields(
      String uid, Map<String, dynamic> fields) async {
    try {
      state = AuthStatus.loading;
      await _firestoreService.updateUserProfileFields(uid, fields);

      // Actualizar el perfil en memoria
      if (_currentProfile != null) {
        _currentProfile = _currentProfile!.copyWith(
          displayName: fields['displayName'] ?? _currentProfile!.displayName,
          email: fields['email'] ?? _currentProfile!.email,
        );

        // Guardar el perfil actualizado en el almacenamiento local
        await LocalStorage.saveUserProfile(_currentProfile!);
        print('✅ Perfil actualizado guardado en almacenamiento local');
      }

      // Recargar el perfil en el provider
      _ref.refresh(userProfileProvider);

      state = AuthStatus.authenticated;
    } catch (e) {
      state = AuthStatus.error;
      print('❌ Error al actualizar campos del perfil: $e');
      rethrow;
    }
  }
}

// Provider del Notifier de autenticación
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(
    ref,
    ref.watch(authServiceProvider),
    ref.watch(firestoreServiceProvider),
    ref.watch(dailyQuestionnaireServiceProvider),
  );
});
