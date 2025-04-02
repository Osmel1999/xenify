import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xenify/data/notification_service.dart';
import 'package:xenify/presentation/providers/auth_provider.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';
import 'package:xenify/presentation/screens/auth_screen.dart';
import 'package:xenify/presentation/screens/dashboard_screen.dart';
import 'package:xenify/presentation/screens/user_data_completion_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Inicializar servicio de notificaciones
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
    print('✅ Servicio de notificaciones inicializado correctamente en main');
  } catch (e) {
    print('❌ Error inicializando notificaciones en main: $e');
  }

  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xenify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AppStartupScreen(),
    );
  }
}

class AppStartupScreen extends ConsumerWidget {
  const AppStartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar tanto el estado de autenticación como el perfil del usuario
    final authState = ref.watch(authStateProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Usuario no autenticado, mostrar pantalla de login
          return const AuthScreen();
        }

        // Usuario autenticado, verificar el perfil
        print('🔄 AppStartupScreen - Iniciando userProfileAsync.when()');
        return userProfileAsync.when(
          data: (userProfile) {
            print(
                '📦 AppStartupScreen - Estado del perfil: ${userProfile != null ? "Perfil encontrado" : "Perfil null"}');
            if (userProfile == null) {
              print('⏳ AppStartupScreen - Esperando carga del perfil...');
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Si el perfil requiere completarse
            if (!userProfile.completedInitialQuestionnaire) {
              return UserDataCompletionScreen(userProfile: userProfile);
            }

            // Si todo está completo, mostrar el dashboard
            return const DashboardScreen();
          },
          loading: () {
            print('⌛ AppStartupScreen - Estado: loading');
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
          error: (error, stack) {
            print('❌ AppStartupScreen - Error: $error');
            print('📜 AppStartupScreen - Stack: $stack');
            return Scaffold(
              body: Center(
                child: Text('Error: $error'),
              ),
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
