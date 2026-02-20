import 'dart:math';
import '../core/band_config.dart';
import '../core/complex.dart';
import '../core/eeg_metrics.dart';

/// processor for synthetic EEG signal generation and analysis (FFT, Band Power)
class EegAnalysisProcessor {
  final double _fs = 256.0;
  final int _n = 1024;
  final Random _rand = Random();

  /// generates a synthetic EEG signal with Alpha (10Hz), Theta (6Hz), and noise
  List<double> _generateSignal() {
    final List<double> signal = [];
    for (int i = 0; i < _n; i++) {
      double t = i / _fs;
      double alpha = 1.0 * sin(2 * pi * 10 * t);
      double theta = 0.5 * sin(2 * pi * 6 * t);
      double noise = 0.1 * (_rand.nextDouble() * 2 - 1);
      signal.add(alpha + theta + noise);
    }
    return signal;
  }

  /// applies a Hann window to the signal to reduce spectral leakage
  List<double> _applyHannWindow(List<double> signal) {
    final double N = signal.length.toDouble();
    final List<double> windowedSignal = List.filled(signal.length, 0.0);
    for (int i = 0; i < N; i++) {
      double windowValue = 0.5 * (1.0 - cos(2 * pi * i / (N - 1)));
      windowedSignal[i] = signal[i] * windowValue;
    }
    return windowedSignal;
  }

  /// recursive Cooley-Tukey FFT
  List<Complex> _fftRecursive(List<Complex> x) {
    int n = x.length;
    if (n == 1) return [x[0]];

    List<Complex> even = _fftRecursive([for (int i = 0; i < n; i += 2) x[i]]);
    List<Complex> odd = _fftRecursive([for (int i = 1; i < n; i += 2) x[i]]);
    List<Complex> X = List.filled(n, const Complex(0, 0));

    // precompute twiddle factors heree
    List<Complex> twiddles = List.generate(n ~/ 2, (k) => Complex.expi(-2 * pi * k / n));    for (int k = 0; k < n ~/ 2; k++) {
      Complex t = odd[k] * twiddles[k];
      X[k] = even[k] + t;
      X[k + n ~/ 2] = even[k] - t;
    }
    return X;
  }

  /// computes the FFT of a real-valued signal, including zero-padding
  Map<String, List<double>> _computeFFT(List<double> signal) {
    int n = signal.length;
    int m = pow(2, (log(n) / log(2)).ceil()).toInt();
    List<double> padded = List<double>.from(signal)..addAll(List.filled(m - n, 0));
    List<Complex> x = padded.map((v) => Complex(v, 0)).toList();
    List<Complex> X = _fftRecursive(x);

    int half = m ~/ 2;
    List<double> mag = List.generate(half, (i) => X[i].abs() / m);
    List<double> freq = List.generate(half, (i) => i * _fs / m);
    return {'mag': mag, 'freq': freq};
  }

  /// calculates power for each EEG band
  Map<String, double> _calculateBandPowers(List<double> mag, List<double> freq) {
    Map<String, List<double>> bandMags = {for (var band in BandConfig.bands.keys) band: []};
    for (int i = 0; i < freq.length; i++) {
      double f = freq[i];
      for (var band in BandConfig.bands.entries) {
        if (f >= band.value['range'][0] && f < band.value['range'][1]) {
          // Power Spectral Density (PSD) = magnitude squared/frequency bin
          bandMags[band.key]!.add(mag[i] * mag[i]);
        }
      }
    }
    return bandMags.map((k, v) => MapEntry(k, v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length));
  }

  /// main public method to process a new signal 'chunk'
  EegMetrics processSignal() {
    final rawSamples = _generateSignal();
    final windowedSamples = _applyHannWindow(rawSamples);
    final fftResults = _computeFFT(windowedSamples);

    final mag = fftResults['mag']!;
    final freq = fftResults['freq']!;

    final bandPowers = _calculateBandPowers(mag, freq);
    final dominantFrequency = mag.isNotEmpty ? freq[mag.indexOf(mag.reduce(max))] : 0.0;

    return EegMetrics(
      rawSamples: rawSamples,
      fftMagnitude: mag,
      fftFrequencies: freq,
      bandPowers: bandPowers,
      dominantFrequency: dominantFrequency,
    );
  }
}