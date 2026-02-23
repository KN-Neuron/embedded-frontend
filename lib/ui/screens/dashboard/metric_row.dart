import 'package:flutter/material.dart';
import 'package:eeg_dashboard_app/core/constants.dart';

class MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const MetricRow({Key? key, required this.label, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: primaryColor)),
        ],
      ),
    );
  }
}