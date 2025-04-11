import 'package:flutter/material.dart';

class ChartLegend extends StatelessWidget {
  final List<LegendItemData> items;

  const ChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    // Use Wrap widget to arrange legend items in a flexible layout
    return Wrap(
      spacing: 16.0, // Spacing between legend items
      runSpacing: 8.0, // Spacing between rows of legend items
      alignment: WrapAlignment.center, // Align legend items to the center
      children: items
          .map((item) => _LegendItem(
                icon: item.icon,
                color: item.color,
                label: item.label,
              ))
          .toList(),
    );
  }
}

class LegendItemData {
  final IconData icon;
  final Color color;
  final String label;

  LegendItemData({
    required this.icon,
    required this.color,
    required this.label,
  });
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16.0),
        const SizedBox(width: 4.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            color: color, // Match the label color to the icon color
          ),
        ),
        const SizedBox(width: 8.0),
      ],
    );
  }
}
