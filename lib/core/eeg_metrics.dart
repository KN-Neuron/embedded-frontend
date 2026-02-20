/// this is a data model to hold the results of the EEG signal analysis
class EegMetrics {

  /// time-series data points for the raw signal chart
  final List<double> rawSamples;

  /// magnitude spectrum after FFT and normalization
  final List<double> fftMagnitude;

  /// frequency axis points corresponding to the FFT magnitude
  final List<double> fftFrequencies;

  /// calculated average power for each canonical EEG band (like delta and so on)
  final Map<String, double> bandPowers;

  /// frequency with the highest magnitude in the spectrum
  final double dominantFrequency;

  const EegMetrics({
    required this.rawSamples,
    required this.fftMagnitude,
    required this.fftFrequencies,
    required this.bandPowers,
    required this.dominantFrequency,
  });

  /// a static empty instance for initialization before data is ready
  static EegMetrics empty() => const EegMetrics(
    rawSamples: [],
    fftMagnitude: [],
    fftFrequencies: [],
    bandPowers: {},
    dominantFrequency: 0.0,
  );
}