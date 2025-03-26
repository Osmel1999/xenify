import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/data/auth_service.dart';
import 'package:xenify/presentation/providers/auth_provider.dart';
import 'package:xenify/presentation/screens/questionnaire_screen.dart';
import 'package:xenify/presentation/screens/dashboard_screen.dart';
import 'package:xenify/presentation/screens/user_data_completion_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithPlatform() async {
    if (!mounted) return; // Protección inicial

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Iniciar sesión con el proveedor de la plataforma
      final userProfile =
          await ref.read(authNotifierProvider.notifier).signInWithPlatform();

      // Importante: verifica mounted antes de continuar
      if (!mounted) return;

      if (userProfile != null) {
        // Obtener el estado actual de autenticación
        final authStatus = ref.read(authNotifierProvider);

        if (authStatus == AuthStatus.requiresCompletion) {
          // Navegar a la pantalla de completar datos
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => UserDataCompletionScreen(
                userProfile: userProfile,
              ),
            ),
          );
        } else {
          // Decidir a dónde navegar basado en si el usuario completó el cuestionario inicial
          if (userProfile.completedInitialQuestionnaire) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const QuestionnaireScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Verifica si el widget sigue montado antes de actualizar el estado
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error al iniciar sesión. Por favor, inténtalo de nuevo.';
        });
      }
      print('Error en _signInWithPlatform: $e');
    } finally {
      // Verifica si el widget sigue montado antes de actualizar el estado
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo o imagen de la app
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Xenify',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tu compañero para una salud integral',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botón de inicio de sesión
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithPlatform,
                icon: Icon(
                  Platform.isAndroid ? Icons.android : Icons.apple,
                ),
                label: Text(
                  'Iniciar con ${Platform.isAndroid ? 'Google' : 'Apple'}',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ),

              const SizedBox(height: 48),

              // Texto legal
              const Text(
                'Al iniciar sesión, aceptas nuestros Términos de Servicio y Política de Privacidad',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
