import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:convert';
import 'package:xenify/data/firestore_service.dart';
import 'package:xenify/domain/entities/user_profile.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
  requiresCompletion, // Nuevo estado para indicar que se requieren datos adicionales
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Método de autenticación automática basado en la plataforma
  Future<UserProfile?> signInWithPlatform() async {
    try {
      if (Platform.isAndroid) {
        return await signInWithGoogle();
      } else if (Platform.isIOS) {
        return await signInWithApple();
      }
      return null;
    } catch (e) {
      print('Error en autenticación de plataforma: $e');
      rethrow;
    }
  }

  // Iniciar sesión con Google
  Future<UserProfile?> signInWithGoogle() async {
    try {
      // Iniciar flujo de inicio de sesión de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el inicio de sesión
        return null;
      }

      // Obtener detalles de autenticación de la solicitud
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear una credencial para Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión con credencial
      final userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('No se pudo obtener el usuario de Firebase');
      }

      // Verificar si es un usuario nuevo
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Obtener o crear el perfil de usuario
      return await _handleUserAuthentication(user, isNewUser);
    } catch (e) {
      print('Error en Google Sign-In: $e');
      rethrow;
    }
  }

  // Iniciar sesión con Apple
  Future<UserProfile?> signInWithApple() async {
    try {
      // Preparar el proveedor de autenticación de Apple
      final appleProvider = OAuthProvider('apple.com');

      // Configurar el alcance de la solicitud
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      // Importante: Usar signInWithPopup en lugar de signInWithCredential
      final result = await _auth.signInWithProvider(appleProvider);
      final User? user = result.user;

      if (user == null) {
        throw Exception('No se pudo obtener el usuario de Firebase');
      }

      // Verificar si es un usuario nuevo
      final isNewUser = result.additionalUserInfo?.isNewUser ?? false;

      // Continuar con tu lógica de manejo de usuario
      return await _handleUserAuthentication(user, isNewUser);
    } catch (e) {
      print('Error detallado en Sign in with Apple: $e');
      rethrow;
    }
  }

  // Verificar si faltan datos en el perfil
  bool profileRequiresCompletion(UserProfile profile) {
    final needsName =
        profile.displayName.isEmpty || profile.displayName == 'Usuario';
    final needsEmail = profile.email == null || profile.email!.isEmpty;

    return needsName || needsEmail;
  }

  // Manejar la autenticación del usuario
  Future<UserProfile> _handleUserAuthentication(
      User user, bool isNewUser) async {
    final now = DateTime.now();

    if (isNewUser) {
      // Crear nuevo perfil de usuario
      final newProfile = UserProfile(
        uid: user.uid,
        displayName: user.displayName ?? 'Usuario',
        email: user.email,
        photoURL: user.photoURL,
        createdAt: now,
        lastLoginAt: now,
        completedInitialQuestionnaire: false,
      );

      // Guardar en Firestore
      await _firestoreService.saveUserProfile(newProfile);
      return newProfile;
    } else {
      // Obtener perfil existente
      UserProfile? existingProfile =
          await _firestoreService.getUserProfile(user.uid);

      if (existingProfile != null) {
        // Actualizar la fecha de último inicio de sesión
        final updatedProfile = existingProfile.copyWith(lastLoginAt: now);
        await _firestoreService.updateUserLastLogin(user.uid, now);
        return updatedProfile;
      } else {
        // Esto podría ocurrir si los datos de Firestore se corrompieron o eliminaron
        // Crear un nuevo perfil basado en la información de Firebase Auth
        final recoveredProfile = UserProfile(
          uid: user.uid,
          displayName: user.displayName ?? 'Usuario',
          email: user.email,
          photoURL: user.photoURL,
          createdAt: now, // Estimación, ya que el original se perdió
          lastLoginAt: now,
          completedInitialQuestionnaire:
              false, // Conservador, mejor pedir de nuevo
        );

        await _firestoreService.saveUserProfile(recoveredProfile);
        return recoveredProfile;
      }
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    if (Platform.isAndroid) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // Generar un nonce aleatorio para Sign in with Apple
  String _generateRandomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // Generar SHA256 hash del string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
