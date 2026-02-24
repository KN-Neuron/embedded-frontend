import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/band_config.dart';
import '../core/complex.dart';
import '../core/eeg_metrics.dart';
import 'signal_processor.dart';
import '../core/constants.dart';

class EegAnalysisState extends ChangeNotifier {
  final double _fs = sampleRate.toDouble();

  String _selectedAnalysisChannel = 'Fp1';
  String get selectedAnalysisChannel => _selectedAnalysisChannel;

  EegMetrics _currentMetrics = EegMetrics.empty();
  EegMetrics get currentMetrics => _currentMetrics;

  double _hjorthActivity = 0.0;
  double get hjorthActivity => _hjorthActivity;

  double _hjorthMobility = 0.0;
  double get hjorthMobility => _hjorthMobility;

  void setSelectedChannel(String ch) {
    _selectedAnalysisChannel = ch;
    notifyListeners();
  }

  void updateAnalysis(List<double> signalBuffer) {
    if (signalBuffer.isEmpty) return;

    final hjorth = SignalProcessor.hjorthParameters(signalBuffer);
    _hjorthActivity = hjorth['Activity'] ?? 0.0;
    _hjorthMobility = hjorth['Mobility'] ?? 0.0;

    final windowedSamples = _applyHannWindow(signalBuffer);
    final fftResults = _computeFFT(windowedSamples);

    final mag = fftResults['mag']!;
    final freq = fftResults['freq']!;

    final bandPowers = _calculateBandPowers(mag, freq);

    double peakFreq = 0.0;
    double maxMag = 0.0;
    for (int i = 0; i < mag.length; i++) {
      if (mag[i] > maxMag && freq[i] > 1.0 && freq[i] < 40.0) {
        maxMag = mag[i];
        peakFreq = freq[i];
      }
    }

    _currentMetrics = EegMetrics(
      rawSamples: signalBuffer,
      fftMagnitude: mag,
      fftFrequencies: freq,
      bandPowers: bandPowers,
      dominantFrequency: peakFreq,
    );
    notifyListeners();
  }

  List<double> _applyHannWindow(List<double> signal) {
    final double n = signal.length.toDouble();
    final List<double> windowedSignal = List.filled(signal.length, 0.0);
    for (int i = 0; i < n; i++) {
      double windowValue = 0.5 * (1 - cos((2 * pi * i) / (n - 1)));
      windowedSignal[i] = signal[i] * windowValue;
    }
    return windowedSignal;
  }

  Map<String, List<double>> _computeFFT(List<double> windowed) {
    List<Complex> xComplex = windowed.map((v) => Complex(v, 0.0)).toList();
    List<Complex> x = fft(xComplex);

    int half = x.length ~/ 2;
    double m = windowed.length / 2.0;

    List<double> mag = List.generate(half, (i) => x[i].abs() / m);
    List<double> freq = List.generate(half, (i) => i * _fs / m);
    return {'mag': mag, 'freq': freq};
  }

  Map<String, double> _calculateBandPowers(List<double> mag, List<double> freq) {
    Map<String, List<double>> bandMags = {
      for (var band in BandConfig.bands.keys) band: []
    };

    for (int i = 0; i < freq.length; i++) {
      double f = freq[i];
      for (var band in BandConfig.bands.entries) {
        if (f >= band.value['range'][0] && f < band.value['range'][1]) {
          bandMags[band.key]!.add(mag[i] * mag[i]);
        }
      }
    }
    return bandMags.map((k, v) => MapEntry(k, v.isEmpty ? 0.0 : v.reduce((a, b) => a + b) / v.length));
  }
}