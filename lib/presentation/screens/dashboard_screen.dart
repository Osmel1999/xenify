import 'package:flutter/material.dart';
import 'package:xenify/presentation/widgets/dashboard/header_widget.dart';
import 'package:xenify/presentation/widgets/dashboard/wellbeing_card_widget.dart';

import '../widgets/dashboard/bottom_navigation_widget.dart';
import '../widgets/dashboard/digestive_health_card_widget.dart';
import '../widgets/dashboard/hydration_card_widget.dart';
import '../widgets/dashboard/meal_tracking_card_widget.dart';
import '../widgets/dashboard/medication_reminder_card_widget.dart';
import '../widgets/dashboard/metrics_row_widget.dart';
// Otros imports...

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        onPressed: () {},
        backgroundColor: Theme.of(context).primaryColor,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
