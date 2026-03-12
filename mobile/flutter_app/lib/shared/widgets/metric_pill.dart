import 'package:flutter/material.dart';

class MetricPill extends StatelessWidget {
  const MetricPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
