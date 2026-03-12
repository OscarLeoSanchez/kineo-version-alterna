import 'package:flutter/material.dart';

class SeriesBarChart extends StatelessWidget {
  const SeriesBarChart({
    super.key,
    required this.points,
    required this.suffix,
  });

  final List<Map<String, dynamic>> points;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Text('Sin puntos suficientes todavia.');
    }

    final values = points
        .map((entry) => (entry['value'] as num?)?.toDouble() ?? 0)
        .toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((entry) {
        final label = entry['label']?.toString() ?? '';
        final value = (entry['value'] as num?)?.toDouble() ?? 0;
        final factor = maxValue <= 0 ? 0.1 : (value / maxValue).clamp(0.1, 1.0);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}$suffix',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 96 * factor,
                  decoration: BoxDecoration(
                    color: const Color(0xFF275C58),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
