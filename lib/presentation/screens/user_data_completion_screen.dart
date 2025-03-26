import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/user_profile.dart';
import 'package:xenify/presentation/providers/auth_provider.dart';
import 'package:xenify/presentation/screens/questionnaire_screen.dart';
import 'package:xenify/presentation/screens/dashboard_screen.dart';

class UserDataCompletionScreen extends ConsumerStatefulWidget {
  final UserProfile userProfile;

  const UserDataCompletionScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  ConsumerState<UserDataCompletionScreen> createState() =>
      _UserDataCompletionScreenState();
}

class _UserDataCompletionScreenState
    extends ConsumerState<UserDataCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  bool get _needsName =>
      widget.userProfile.displayName.isEmpty ||
      widget.userProfile.displayName == 'Usuario';
  bool get _needsEmail =>
      widget.userProfile.email == null || widget.userProfile.email!.isEmpty;

  @override
  void initState() {
    super.initState();

    // Pre-llenar los campos con los valores existentes (si hay)
    if (!_needsName) {
      _nameController.text = widget.userProfile.displayName;
    }

    if (!_needsEmail && widget.userProfile.email != null) {
      _emailController.text = widget.userProfile.email!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Crear un mapa con solo los campos que necesitan actualizarse
      final Map<String, dynamic> fieldsToUpdate = {};

      if (_needsName) {
        fieldsToUpdate['displayName'] = _nameController.text.trim();
      }

      if (_needsEmail) {
        fieldsToUpdate['email'] = _emailController.text.trim();
      }

      // Actualizar el perfil del usuario a través del provider
      // Nota: necesitarás implementar este método en tu AuthNotifier
      await ref.read(authNotifierProvider.notifier).updateUserProfileFields(
            widget.userProfile.uid,
            fieldsToUpdate,
          );

      // Navegar a la siguiente pantalla basándose en si completó el cuestionario inicial
      if (!mounted) return;

      if (widget.userProfile.completedInitialQuestionnaire) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuestionnaireScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Error al actualizar tus datos. Por favor, inténtalo de nuevo.';
        _isLoading = false;
      });
      print('Error en _submitData: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu Perfil'),
        // No permitir retroceder si se requieren datos
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Necesitamos un poco más de información para completar tu perfil',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Campo de nombre (solo se muestra si falta)
              if (_needsName) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ingresa tu nombre completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Campo de correo (solo se muestra si falta)
              if (_needsEmail) ...[
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    hintText: 'Ingresa tu correo electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingresa tu correo electrónico';
                    }

                    // Validación simple de formato de correo
                    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegExp.hasMatch(value)) {
                      return 'Por favor ingresa un correo electrónico válido';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Mensaje de error
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
              ],

              // Botón de envío
              ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Continuar', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
