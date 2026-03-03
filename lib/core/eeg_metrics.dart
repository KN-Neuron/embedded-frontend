class EegMetrics {
  final List<double> rawSamples;
  final List<double> fftMagnitude;
  final List<double> fftFrequencies;
  final Map<String, double> bandPowers;
  final double dominantFrequency;

  EegMetrics({
    required this.rawSamples,
    required this.fftMagnitude,
    required this.fftFrequencies,
    required this.bandPowers,
    required this.dominantFrequency,
  });

  factory EegMetrics.empty() {
    return EegMetrics(
      rawSamples: [],
      fftMagnitude: [],
      fftFrequencies: [],
      bandPowers: {},
      dominantFrequency: 0.0,
    );
  }
}