import 'package:flutter/material.dart';

class MontageInfoPanel extends StatelessWidget {
  final String title;
  final String description;
  final Color color;

  const MontageInfoPanel({Key? key, required this.title, required this.description, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(height: 1.5, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}