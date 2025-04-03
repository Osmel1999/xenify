import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';

// Variable para almacenar la instancia de SharedPreferences
SharedPreferences? _sharedPreferences;

// Función para inicializar el container con SharedPreferences
void initializeProviderContainer(SharedPreferences prefs) {
  _sharedPreferences = prefs;
  // Recreate the container with overrides if needed
  final updatedContainer = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Replace the global container with the updated one
  providerContainer = updatedContainer;
}

// Contenedor global de providers que se puede acceder desde fuera del árbol de widgets
ProviderContainer providerContainer = ProviderContainer();
