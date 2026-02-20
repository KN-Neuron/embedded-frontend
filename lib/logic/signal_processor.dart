import 'dart:math';
import 'package:eeg_dashboard_app/core/complex.dart';
import 'package:eeg_dashboard_app/core/constants.dart';

List<Complex> fft(List<Complex> x) {
  int n = x.length;
  if (n <= 1) return x;
  final even = <Complex>[];
  final odd = <Complex>[];
  for (int i = 0; i < n; i++) {
    if (i.isEven) even.add(x[i]);
    else odd.add(x[i]);
  }
  final fe = fft(even);
  final fo = fft(odd);
  final result = List<Complex>.filled(n, const Complex(0, 0));
  for (int k = 0; k < n ~/ 2; k++) {
    final theta = -2 * pi * k / n;
    final wk = Complex(cos(theta), sin(theta));
    final t = wk * fo[k];
    result[k] = fe[k] + t;
    result[k + n ~/ 2] = fe[k] - t;
  }
  return result;
}

class SignalProcessor {
  static final Random _random = Random();

  static double generateSample(double t) {
    final alpha = sin(2 * pi * 10 * t);
    final theta = 0.5 * sin(2 * pi * 6 * t + pi/4);
    final beta = 0.2 * sin(2 * pi * 20 * t);
    final noise = 0.08 * (_random.nextDouble() * 2 - 1);
    return alpha + theta + beta + noise;
  }

  static List<double> spectrumFromBuffer(List<double> buffer) {
    int n = 1;
    while (n < buffer.length) n <<= 1;

    final complex = List<Complex>.generate(n, (i) {
      return i < buffer.length ? Complex(buffer[i], 0) : const Complex(0, 0);
    });

    final res = fft(complex);
    final half = res.sublist(0, n ~/ 2);
    return half.map((c) => c.magnitude()).toList();
  }

  static List<double> simplePSD(List<double> buffer) {
    final window = min(256, buffer.length);
    final step = (window / 2).floor();
    if (window < 8) return List.filled(window ~/ 2, 0.0);

    final accum = List<double>.filled(window ~/ 2, 0.0);
    int count = 0;

    for (int start = 0; start + window <= buffer.length; start += step) {
      final seg = buffer.sublist(start, start + window);
      final mags = spectrumFromBuffer(seg);
      for (int i = 0; i < accum.length && i < mags.length; i++) {
        accum[i] += mags[i] * mags[i];
      }
      count++;
    }

    if (count == 0) return accum;
    for (int i = 0; i < accum.length; i++) accum[i] /= count;
    return accum;
  }

  static double bandPower(List<double> spectrum, int fftSize, double freqLow,
      double freqHigh) {
    final df = sampleRate / fftSize;
    int startBin = (freqLow / df).floor().clamp(0, spectrum.length - 1);
    int endBin = (freqHigh / df).ceil().clamp(0, spectrum.length - 1);

    if (endBin <= startBin) return 0.0;

    double sum = 0;
    for (int i = startBin; i <= endBin; i++) sum += spectrum[i];

    return sum / (endBin - startBin + 1);
  }

  static Map<String, double> hjorthParameters(List<double> buffer) {
    if (buffer.isEmpty) return {'Activity': 0.0, 'Mobility': 0.0};

    final mean = buffer.reduce((a, b) => a + b) / buffer.length;
    final activity = buffer.map((v) => pow(v - mean, 2).toDouble()).reduce((a, b) => a + b) / buffer.length;

    final diff = List.generate(buffer.length - 1, (i) => buffer[i + 1] - buffer[i]);
    if (diff.isEmpty) return {'Activity': activity, 'Mobility': 0.0};

    final meanDiff = diff.reduce((a, b) => a + b) / diff.length;
    final activityDiff = diff.map((v) => pow(v - meanDiff, 2).toDouble()).reduce((a, b) => a + b) / diff.length;

    final mobility = activity > 1e-9 ? sqrt(activityDiff / activity) : 0.0;

    return {'Activity': activity, 'Mobility': mobility};
  }
}