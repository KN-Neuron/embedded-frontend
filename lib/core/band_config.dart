import 'package:flutter/material.dart';

class BandConfig {
  final String name;
  final double minFreq;
  final double maxFreq;
  final Color color;
  final String description;

  const BandConfig({
    required this.name,
    required this.minFreq,
    required this.maxFreq,
    required this.color,
    required this.description,
  });

  static const List<BandConfig> allBands = [
    BandConfig(
      name: 'Delta',
      minFreq: 0.5,
      maxFreq: 4.0,
      color: Color(0xFF00BFFF),
      description: 'Deep sleep, unconscious processing',
    ),
    BandConfig(
      name: 'Theta',
      minFreq: 4.0,
      maxFreq: 8.0,
      color: Color(0xFF32CD32),
      description: 'Drowsiness, meditation',
    ),
    BandConfig(
      name: 'Alpha',
      minFreq: 8.0,
      maxFreq: 13.0,
      color: Color(0xFFFFD700),
      description: 'Relaxed alertness',
    ),
    BandConfig(
      name: 'Beta',
      minFreq: 13.0,
      maxFreq: 30.0,
      color: Color(0xFFFF0000),
      description: 'Active concentration',
    ),
  ];

  static BandConfig? findByFrequency(double freq) {
    for (var band in allBands) {
      if (freq >= band.minFreq && freq <= band.maxFreq) return band;
    }
    return null;
  }

  static Map<String, Color> get colorMap => {
    for (var band in allBands) band.name: band.color
  };
}