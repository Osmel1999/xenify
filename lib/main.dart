import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:xenify/data/notification_service.dart';
import 'package:xenify/presentation/providers/auth_provider.dart';
import 'package:xenify/presentation/screens/auth_screen.dart';
import 'package:xenify/presentation/screens/dashboard_screen.dart';
import 'package:xenify/presentation/screens/questionnaire_screen.dart';
import 'package:xenify/presentation/screens/user_data_completion_screen.dart';
import 'package:xenify/data/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Inicializar el servicio de notificaciones
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authStatusState = ref.watch(authNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Xenify',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: authState.when(
        data: (user) {
          if (user != null) {
            // Usuario autenticado
            final profileAsync = ref.watch(userProfileProvider);

            return profileAsync.when(
              data: (profile) {
                if (profile == null) {
                  // Si no hay perfil pero hay usuario, algo salió mal
                  return const AuthScreen();
                }

                // Verificar si el perfil necesita completarse
                final authService = ref.read(authServiceProvider);
                if (authService.profileRequiresCompletion(profile) ||
                    authStatusState == AuthStatus.requiresCompletion) {
                  return UserDataCompletionScreen(userProfile: profile);
                }

                // Decidir pantalla basado en si completó el cuestionario inicial
                if (profile.completedInitialQuestionnaire) {
                  return const DashboardScreen();
                } else {
                  return const QuestionnaireScreen();
                }
              },
              loading: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const AuthScreen(),
            );
          } else {
            // Usuario no autenticado
            return const AuthScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const AuthScreen(),
      ),
    );
  }
}
