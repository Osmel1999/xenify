import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xenify/presentation/widgets/dashboard/daily_questionnaire_wrapper.dart';
import 'package:xenify/presentation/widgets/dashboard/header_widget.dart';
import 'package:xenify/presentation/widgets/dashboard/wellbeing_card_widget.dart';
import '../widgets/dashboard/bottom_navigation_widget.dart';
import '../widgets/dashboard/digestive_health_card_widget.dart';
import '../widgets/dashboard/hydration_card_widget.dart';
import '../widgets/dashboard/meal_tracking_card_widget.dart';
import '../widgets/dashboard/medication_reminder_card_widget.dart';
import '../widgets/dashboard/metrics_row_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DailyQuestionnaireWrapper(
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const HeaderWidget(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 80,
                      ),
                      children: const [
                        WellbeingCardWidget(),
                        SizedBox(height: 16),
                        MetricsRowWidget(),
                        SizedBox(height: 16),
                        HydrationCardWidget(),
                        SizedBox(height: 16),
                        MealTrackingCardWidget(),
                        SizedBox(height: 16),
                        DigestiveHealthCardWidget(),
                        SizedBox(height: 16),
                        MedicationReminderCardWidget(),
                      ],
                    ),
                  ),
                ],
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BottomNavigationWidget(),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showQuickAddMenu(context),
          backgroundColor: Theme.of(context).primaryColor,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.local_drink),
              title: const Text('Registrar hidratación'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar registro de hidratación
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Registrar comida'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar registro de comida
              },
            ),
            ListTile(
              leading: const Icon(Icons.bathroom),
              title: const Text('Registrar ida al baño'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar registro de baño
              },
            ),
          ],
        ),
      ),
    );
  }
}
