import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphLineChart extends StatelessWidget {
  final List<LineChartBarData> lines;
  final List<String> xLabels; // List of day labels passed from GraphChartScreen
  final List<Color> colors;

  const GraphLineChart({
    Key? key,
    required this.lines,
    required this.xLabels,
    required this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double maxY = lines
        .expand((line) => line.spots)
        .map((spot) => spot.y)
        .fold<double>(
            double.negativeInfinity, (prev, y) => y > prev ? y : prev);

    if (maxY.isFinite) {
      maxY = (maxY / 10).ceilToDouble() * 10;
    } else {
      maxY = 100;
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 12,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 16,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.asMap().entries.map((entry) {
                final index = entry.key;
                final spot = entry.value;
                final color =
                    colors.length > index ? colors[index] : Colors.black;

                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
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
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < xLabels.length) {
                  return Text(
                    xLabels[index],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
              interval: 1, // Ensure a label for each index
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        minX: 0, // X-axis starts at index 0
        maxX: xLabels.length > 1
            ? (xLabels.length - 1).toDouble()
            : 0, // X-axis ends at the last index
        minY: 0,
        maxY: maxY,
        lineBarsData: lines,
      ),
    );
  }
}
