class EegMetrics {
  final List<double> rawSamples;
  final List<double> fftMagnitude;
  final List<double> fftFrequencies;
  final Map<String, double> bandPowers;
  final double dominantFrequency;

  const EegMetrics({
    required this.rawSamples,
    required this.fftMagnitude,
    required this.fftFrequencies,
    required this.bandPowers,
    required this.dominantFrequency,
  });

  static EegMetrics empty() => const EegMetrics(
    rawSamples: [],
    fftMagnitude: [],
    fftFrequencies: [],
    bandPowers: {},
    dominantFrequency: 0.0,
  );

  Map<String, String> toAiSummary({
    required bool isFromFile,
    required String channelName,
    required double hjorthActivity,
    required double hjorthMobility,
  }) {
    final totalPower = bandPowers.isEmpty
        ? 0.0
        : bandPowers.values.reduce((a, b) => a + b);

    return {
      'Source': isFromFile ? 'Loaded Dataset' : 'Mocked Synthetic Data',
      'Analysis Channel': channelName,
      'Total Power': totalPower.toStringAsFixed(2),
      'Alpha Power': (bandPowers['Alpha'] ?? 0.0).toStringAsFixed(2),
      'Beta Power': (bandPowers['Beta'] ?? 0.0).toStringAsFixed(2),
      'Theta Power': (bandPowers['Theta'] ?? 0.0).toStringAsFixed(2),
      'Delta Power': (bandPowers['Delta'] ?? 0.0).toStringAsFixed(2),
      'Alpha Peak Freq': dominantFrequency.toStringAsFixed(2),
      'Hjorth Activity (Var)': hjorthActivity.toStringAsFixed(4),
      'Hjorth Mobility': hjorthMobility.toStringAsFixed(4),
    };
  }
}