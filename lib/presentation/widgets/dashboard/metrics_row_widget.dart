import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:xenify/presentation/widgets/common/nutrient_row_widget.dart';

class MetricsRowWidget extends StatelessWidget {
  const MetricsRowWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget de Alimentos actualizado
            Expanded(
              flex: 50,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado con icono
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.restaurant,
                              color: Colors.green[700],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Alimentos',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lista de nutrientes
                      NutrientRowWidget(
                        name: 'Proteínas',
                        value: '62.5 g',
                        progress: 0.7,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 10),
                      NutrientRowWidget(
                        name: 'Grasas',
                        value: '45.8 g',
                        progress: 0.6,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 10),
                      NutrientRowWidget(
                        name: 'Carbos',
                        value: '180.3 g',
                        progress: 0.85,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 10),
                      NutrientRowWidget(
                        name: 'RDC',
                        value: '68%',
                        progress: 0.68,
                        color: Colors.green,
                      ),

                      const SizedBox(height: 16),

                      // Evaluación de la alimentación
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Buena',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Columna que contiene las dos gráficas (ocupa el 55% del ancho)
            Expanded(
              flex: 55,
              child: Column(
                children: [
                  // Widget de digestión semanal con LineChart
                  _buildChartCard(
                    context,
                    'Digestión',
                    Icons.monitor_heart_rounded,
                    Colors.blue,
                    _buildDigestionChart(),
                  ),

                  const SizedBox(height: 12),

                  // Widget de actividad física con LineChart
                  _buildChartCard(
                    context,
                    'Actividad física',
                    Icons.directions_run,
                    Colors.orange,
                    _buildActivityChart(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    String title,
    IconData icon,
    MaterialColor color,
    Widget chart,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color[700],
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: chart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigestionChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, 6.5),
              FlSpot(1, 8.0),
              FlSpot(2, 7.5),
              FlSpot(3, 9.0),
              FlSpot(4, 8.5),
              FlSpot(5, 7.0),
              FlSpot(6, 6.0),
            ],
            isCurved: true,
            color: Colors.blue[400],
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                Color dotColor = Colors.blue;
                if (spot.y >= 8.5) {
                  dotColor = Colors.green;
                } else if (spot.y <= 6.0) {
                  dotColor = Colors.orange;
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: dotColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.15),
            ),
          ),
        ],
        minY: 4,
        maxY: 10,
      ),
    );
  }

  Widget _buildActivityChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, 300),
              FlSpot(1, 600),
              FlSpot(2, 200),
              FlSpot(3, 800),
              FlSpot(4, 500),
              FlSpot(5, 900),
              FlSpot(6, 400),
            ],
            isCurved: true,
            color: Colors.orange[400],
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.orange,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.orange.withOpacity(0.15),
            ),
          ),
        ],
        minY: 0,
        maxY: 1000,
      ),
    );
  }
}
