import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/presentation/theme/questionnaire_theme.dart';

class AdaptiveQuestionnaire extends ConsumerWidget {
  final Widget child;
  final QuestionCategory category;

  const AdaptiveQuestionnaire({
    super.key,
    required this.child,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final isTablet = size.width >= 600;
    final isDesktop = size.width >= 1024;

    final horizontalPadding = isDesktop
        ? 32.0
        : isTablet
            ? 24.0
            : 16.0;

    final verticalPadding = isDesktop
        ? 32.0
        : isTablet
            ? 24.0
            : 16.0;

    final backgroundColor =
        isDarkMode ? Colors.grey[900] : QuestionnaireTheme.backgroundColor;

    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;

    final textColor =
        isDarkMode ? Colors.white : QuestionnaireTheme.textPrimaryColor;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop
                  ? 1200
                  : isTablet
                      ? 800
                      : size.width,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (!isDarkMode)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16.0 * textScaleFactor,
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.apply(
                              bodyColor: textColor,
                              displayColor: textColor,
                              fontSizeFactor: textScaleFactor,
                            ),
                        iconTheme: IconThemeData(
                          color: QuestionnaireTheme.getCategoryColor(category),
                          size: 24 * textScaleFactor,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension AdaptiveQuestionnaireExtension on Widget {
  Widget makeAdaptive(QuestionCategory category) {
    return AdaptiveQuestionnaire(
      category: category,
      child: this,
    );
  }
}
