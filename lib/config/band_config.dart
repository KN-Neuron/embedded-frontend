import 'package:flutter/material.dart';

/// configuration for EEG frequency bands (and FFT visualization)
class BandConfig {
  static const Map<String, Map<String, dynamic>> bands = {
    'Delta': {
      'range': [0.5, 4.0],
      'description': 'Deep sleep, unconscious processing',
      'color': Colors.blue,
    },
    'Theta': {
      'range': [4.0, 8.0],
      'description': 'Drowsiness, meditation',
      'color': Colors.green,
    },
    'Alpha': {
      'range': [8.0, 13.0],
      'description': 'Relaxed alertness',
      'color': Colors.purple,
    },
    'Beta': {
      'range': [13.0, 30.0],
      'description': 'Active concentration',
      'color': Colors.red,
    },
  };
}