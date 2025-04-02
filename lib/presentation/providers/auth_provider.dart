import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/data/auth_service.dart';
import 'package:xenify/data/firestore_service.dart';
import 'package:xenify/domain/entities/user_profile.dart';

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
      '👤 UserProfileProvider - Intentando obtener perfil para UID: ${authState.value!.uid}');

  // Obtener perfil del usuario
  final firestoreService = ref.watch(firestoreServiceProvider);
  try {
    final profile = await firestoreService.getUserProfile(authState.value!.uid);
    print(profile != null
        ? '✅ UserProfileProvider - Perfil obtenido exitosamente: ${profile.toString()}'
        : '⚠️ UserProfileProvider - No se encontró perfil para el usuario');
    return profile;
  } catch (e) {
    print('❌ UserProfileProvider - Error al obtener perfil: $e');
    rethrow;
  }
});

// Notifier para gestionar el estado de autenticación
class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final Ref _ref;
  UserProfile? _currentProfile;

  AuthNotifier(this._ref, this._authService, this._firestoreService)
      : super(AuthStatus.initial);

  // Getter para el perfil de usuario actual
  UserProfile? get currentProfile => _currentProfile;

  Future<UserProfile?> signInWithPlatform() async {
    try {
      state = AuthStatus.loading;
      final userProfile = await _authService.signInWithPlatform();

      if (userProfile != null) {
        _currentProfile = userProfile;

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

  Future<void> markInitialQuestionnaireCompleted() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        await _firestoreService.markInitialQuestionnaireCompleted(user.uid);
        if (_currentProfile != null) {
          _currentProfile =
              _currentProfile!.copyWith(completedInitialQuestionnaire: true);
        }
        _ref.refresh(userProfileProvider);
      }
    } catch (e) {
      print('Error al marcar cuestionario como completado: $e');
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
      }

      // Recargar el perfil en el provider
      _ref.refresh(userProfileProvider);

      state = AuthStatus.authenticated;
    } catch (e) {
      state = AuthStatus.error;
      print('Error al actualizar campos del perfil: $e');
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
  );
});
