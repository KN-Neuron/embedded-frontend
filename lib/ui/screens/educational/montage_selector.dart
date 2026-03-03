import 'package:flutter/material.dart';
import '../educational_screen.dart';

class MontageSelector extends StatelessWidget {
  final Montage activeMontage;
  final ValueChanged<Montage> onChanged;
  final Map<Montage, Map<String, Object?>> montageDescriptions;

  const MontageSelector({Key? key, required this.activeMontage, required this.onChanged, required this.montageDescriptions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: Montage.values.map((montage) {
            final color = montageDescriptions[montage]?['color'] as Color? ?? Colors.white;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<Montage>(
                  value: montage,
                  groupValue: activeMontage,
                  onChanged: (Montage? value) {
                    if (value != null) onChanged(value);
                  },
                  activeColor: color,
                ),
                Text(
                  montage.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: activeMontage == montage ? color : Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}