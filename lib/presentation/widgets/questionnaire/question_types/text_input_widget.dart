import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/domain/entities/question.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';

/// Tipos de entradas de texto
enum TextInputFieldType {
  singleLine, // Una sola línea
  multiLine, // Múltiples líneas
  number, // Solo números
  email, // Email
  password, // Contraseña (ocultada)
  phone, // Teléfono
}

/// Widget para preguntas con respuesta mediante entradas de texto
class TextInputWidget extends ConsumerStatefulWidget {
  /// La pregunta a mostrar
  final Question question;

  /// La categoría de la pregunta (determina el color)
  final QuestionCategory category;

  /// Callback para cuando se actualiza el texto
  final Function(String) onTextUpdated;

  /// Callback para cuando se envía el texto (al presionar Enter o el botón)
  final Function(String) onTextSubmitted;

  /// Texto actual (si existe)
  final String? currentText;

  /// Tipo de entrada de texto
  final TextInputFieldType textInputType;

  /// Texto del placeholder
  final String? placeholder;

  /// Texto de ayuda
  final String? helperText;

  /// Indica si el campo es requerido
  final bool isRequired;

  /// Longitud máxima del texto
  final int? maxLength;

  /// Expresión regular para validación
  final String? validationRegex;

  /// Mensaje de error para validación fallida
  final String? validationErrorMessage;

  const TextInputWidget({
    Key? key,
    required this.question,
    required this.category,
    required this.onTextUpdated,
    required this.onTextSubmitted,
    this.currentText,
    this.textInputType = TextInputFieldType.singleLine,
    this.placeholder,
    this.helperText,
    this.isRequired = true,
    this.maxLength,
    this.validationRegex,
    this.validationErrorMessage,
  }) : super(key: key);

  @override
  ConsumerState<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends ConsumerState<TextInputWidget> {
  late TextEditingController _controller;
  String? _errorMessage;
  bool _isValid = true;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentText ?? '');
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = QuestionnaireTheme.getCategoryColor(widget.category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Campo de texto
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _errorMessage != null
                  ? Colors.red
                  : _isFocused
                      ? categoryColor
                      : _controller.text.isNotEmpty
                          ? categoryColor.withOpacity(0.5)
                          : Colors.grey.shade300,
              width: _isFocused ||
                      _errorMessage != null ||
                      _controller.text.isNotEmpty
                  ? 2
                  : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.placeholder ?? 'Escribe tu respuesta aquí...',
              helperText: widget.helperText,
              errorText: _errorMessage,
              counterText: widget.maxLength != null ? null : '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: _getPrefixIcon(categoryColor),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _errorMessage = null;
                          _isValid = true;
                        });
                      },
                      color: Colors.grey.shade600,
                    )
                  : null,
              helperStyle: QuestionnaireTheme.secondaryTextStyle,
              hintStyle: QuestionnaireTheme.secondaryTextStyle.copyWith(
                color: Colors.grey.shade400,
              ),
              errorStyle: QuestionnaireTheme.secondaryTextStyle.copyWith(
                color: Colors.red,
              ),
            ),
            style: QuestionnaireTheme.optionTextStyle,
            keyboardType: _getKeyboardType(),
            textCapitalization: _getTextCapitalization(),
            textInputAction: _getTextInputAction(),
            obscureText: widget.textInputType == TextInputFieldType.password,
            maxLength: widget.maxLength,
            maxLines: _getMaxLines(),
            inputFormatters: _getInputFormatters(),
            onSubmitted: (value) {
              if (_validate(value)) {
                widget.onTextSubmitted(value);
              }
            },
          ),
        ),

        // Mensaje de caracteres restantes (si aplica)
        if (widget.maxLength != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Text(
              '${_controller.text.length}/${widget.maxLength} caracteres',
              style: QuestionnaireTheme.secondaryTextStyle.copyWith(
                color: _controller.text.length > (widget.maxLength! * 0.8)
                    ? _controller.text.length >= widget.maxLength!
                        ? Colors.red
                        : Colors.orange
                    : Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),

        const SizedBox(height: 24),

        // Botón para enviar
        _buildSubmitButton(context, categoryColor),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, Color categoryColor) {
    final bool isEnabled =
        !widget.isRequired || _controller.text.isNotEmpty && _isValid;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: isEnabled ? categoryColor : Colors.grey.shade400,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: categoryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: isEnabled
              ? () {
                  if (_validate(_controller.text)) {
                    widget.onTextSubmitted(_controller.text);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              'Continuar',
              style: QuestionnaireTheme.buttonTextStyle.copyWith(
                color: isEnabled ? Colors.white : Colors.grey.shade200,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Obtiene el icono del prefijo según el tipo de entrada
  Widget? _getPrefixIcon(Color color) {
    IconData? iconData;

    switch (widget.textInputType) {
      case TextInputFieldType.email:
        iconData = Icons.email_outlined;
        break;
      case TextInputFieldType.phone:
        iconData = Icons.phone_outlined;
        break;
      case TextInputFieldType.password:
        iconData = Icons.lock_outlined;
        break;
      case TextInputFieldType.number:
        iconData = Icons.numbers_outlined;
        break;
      case TextInputFieldType.multiLine:
        iconData = Icons.text_fields_outlined;
        break;
      default:
        return null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Icon(
        iconData,
        color: _isFocused ? color : Colors.grey.shade600,
        size: 22,
      ),
    );
  }

  // Obtiene el tipo de teclado según el tipo de entrada
  TextInputType _getKeyboardType() {
    switch (widget.textInputType) {
      case TextInputFieldType.multiLine:
        return TextInputType.multiline;
      case TextInputFieldType.number:
        return TextInputType.number;
      case TextInputFieldType.email:
        return TextInputType.emailAddress;
      case TextInputFieldType.phone:
        return TextInputType.phone;
      default:
        return TextInputType.text;
    }
  }

  // Obtiene la capitalización según el tipo de entrada
  TextCapitalization _getTextCapitalization() {
    switch (widget.textInputType) {
      case TextInputFieldType.email:
      case TextInputFieldType.password:
        return TextCapitalization.none;
      default:
        return TextCapitalization.sentences;
    }
  }

  // Obtiene la acción del teclado según el tipo de entrada
  TextInputAction _getTextInputAction() {
    switch (widget.textInputType) {
      case TextInputFieldType.multiLine:
        return TextInputAction.newline;
      default:
        return TextInputAction.done;
    }
  }

  // Obtiene el número máximo de líneas según el tipo de entrada
  int _getMaxLines() {
    switch (widget.textInputType) {
      case TextInputFieldType.multiLine:
        return 5;
      default:
        return 1;
    }
  }

  // Obtiene los formateadores de entrada según el tipo
  List<TextInputFormatter>? _getInputFormatters() {
    switch (widget.textInputType) {
      case TextInputFieldType.number:
        return [FilteringTextInputFormatter.digitsOnly];
      case TextInputFieldType.phone:
        return [FilteringTextInputFormatter.digitsOnly];
      default:
        return null;
    }
  }

  // Maneja cambios en el texto
  void _onTextChanged() {
    setState(() {
      _validate(_controller.text);
    });

    widget.onTextUpdated(_controller.text);
  }

  // Valida el texto según las reglas establecidas
  bool _validate(String value) {
    setState(() {
      _errorMessage = null;
      _isValid = true;
    });

    // Validar si es requerido
    if (widget.isRequired && value.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Este campo es requerido';
        _isValid = false;
      });
      return false;
    }

    // Validar según tipo
    if (value.isNotEmpty) {
      if (widget.textInputType == TextInputFieldType.email) {
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          setState(() {
            _errorMessage = 'Ingresa un correo electrónico válido';
            _isValid = false;
          });
          return false;
        }
      } else if (widget.textInputType == TextInputFieldType.phone) {
        final phoneRegex = RegExp(r'^\d{7,15}$');
        if (!phoneRegex.hasMatch(value)) {
          setState(() {
            _errorMessage = 'Ingresa un número de teléfono válido';
            _isValid = false;
          });
          return false;
        }
      }

      // Validar con expresión regular personalizada
      if (widget.validationRegex != null) {
        final regex = RegExp(widget.validationRegex!);
        if (!regex.hasMatch(value)) {
          setState(() {
            _errorMessage = widget.validationErrorMessage ?? 'Formato inválido';
            _isValid = false;
          });
          return false;
        }
      }
    }

    return true;
  }
}
