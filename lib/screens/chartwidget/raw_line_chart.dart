import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
// import 'package:mais_2025_iot/screens/chartwidget/app_colors.dart';

class RawLineChart extends StatelessWidget {
  final List<LineChartBarData> lines;
  final double maxX;
  final double? minX;
  final List<Color> colors;

  const RawLineChart({
    Key? key,
    required this.lines,
    required this.maxX,
    this.minX,
    required this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final startX =
        minX ?? (maxX - Duration(hours: 9).inMilliseconds).toDouble();
    final endX = maxX;

    double maxY = lines
        .expand((line) => line.spots)
        .map((spot) => spot.y)
        .fold<double>(
            double.negativeInfinity, (prev, y) => y > prev ? y : prev);

    // Ensure maxY is a finite number and round it up to the nearest 10 for better visualization
    if (maxY.isFinite) {
      maxY = (maxY / 10).ceilToDouble() * 10;
    } else {
      // Default maxY value if no data is available
      maxY = 100;
    }

    return LineChart(
      LineChartData(
        // Configuration for line touch interactions
        lineTouchData: LineTouchData(
          // Configuration for the tooltip displayed on touch
          touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 12,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipMargin: 16,
              // Callback to format the tooltip items
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final barIndex = spot.barIndex;
                  final color = colors.length > barIndex
                      ? colors[barIndex]
                      : Colors.black;

                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  );
                }).toList();
              }),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            // Optional: Handle touch if needed
          },
        ),
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: Duration(hours: 1).inMilliseconds.toDouble(),
              getTitlesWidget: (value, meta) {
                final dateTime =
                    DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(DateFormat('HH:00').format(dateTime),
                    style: TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: startX,
        maxX: endX,
        minY: 0,
        maxY: maxY,
        lineBarsData: lines,
      ),
    );
  }
}
