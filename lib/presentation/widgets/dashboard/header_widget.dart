import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:xenify/presentation/providers/auth_provider.dart';
import 'package:xenify/presentation/providers/daily_questionnaire_provider.dart';
import 'package:xenify/presentation/widgets/common/wellbeing_indicator_widget.dart';
import 'package:xenify/domain/entities/daily_questionnaire.dart';

class HeaderWidget extends ConsumerWidget {
  const HeaderWidget({Key? key}) : super(key: key);

  String _getMoodText(int? mood) {
    if (mood == null) return 'N/A';
    switch (mood) {
      case 1:
        return 'Mal';
      case 2:
        return 'Regular';
      case 3:
        return 'Normal';
      case 4:
        return 'Bien';
      case 5:
        return 'Excelente';
      default:
        return 'N/A';
    }
  }

  IconData _getMoodIcon(int? mood) {
    if (mood == null) return Icons.sentiment_neutral;
    switch (mood) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  String _getEnergyText(int? energy) {
    if (energy == null) return 'N/A';
    return '$energy%';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final dailyQuestionnaireService =
        ref.watch(dailyQuestionnaireServiceProvider);

    // Obtener el último cuestionario completado (matutino o nocturno)
    final lastMorningQuestionnaire = dailyQuestionnaireService
        .getTodayQuestionnaire(QuestionnaireType.morning);
    final lastEveningQuestionnaire = dailyQuestionnaireService
        .getTodayQuestionnaire(QuestionnaireType.evening);

    // Usar el cuestionario más reciente que esté completado
    final lastQuestionnaire = lastEveningQuestionnaire?.isCompleted == true
        ? lastEveningQuestionnaire
        : lastMorningQuestionnaire?.isCompleted == true
            ? lastMorningQuestionnaire
            : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: userProfileAsync.when(
        data: (userProfile) {
          // Determinar el avatar a mostrar
          Widget avatar;
          if (userProfile?.photoURL != null) {
            avatar = CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(userProfile!.photoURL!),
            );
          } else {
            final bool isFemale =
                userProfile?.gender?.toLowerCase() == 'femenino';
            avatar = CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                isFemale ? Icons.face_3 : Icons.face_6,
                color: Theme.of(context).primaryColor,
                size: 30,
              ),
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${userProfile?.displayName ?? 'Usuario'}!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (lastQuestionnaire != null) ...[
                WellbeingIndicatorCompactWidget(
                  '${lastQuestionnaire.sleepQuality ?? 'N/A'}h',
                  Icons.bedtime,
                  Theme.of(context).primaryColor,
                ),
                WellbeingIndicatorCompactWidget(
                  _getEnergyText(lastQuestionnaire.energyLevel),
                  Icons.battery_5_bar_rounded,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ),
                WellbeingIndicatorCompactWidget(
                  _getMoodText(lastQuestionnaire.mood),
                  _getMoodIcon(lastQuestionnaire.mood),
                  Theme.of(context).primaryColor,
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
