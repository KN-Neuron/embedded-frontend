import 'package:flutter/foundation.dart';
import '../core/band_config.dart';
import '../core/complex.dart';
import '../core/eeg_metrics.dart';
import 'signal_processor.dart';

class AnalysisResult {
  final EegMetrics metrics;
  final double hjorthActivity;
  final double hjorthMobility;

  AnalysisResult(this.metrics, this.hjorthActivity, this.hjorthMobility);
}

class AnalysisPayload {
  final List<double> view;
  final int sampleRate;

  AnalysisPayload(this.view, this.sampleRate);
}

class AnalysisEngine {
  Future<AnalysisResult> analyze(List<double> view, int sampleRate) async {
    if (view.isEmpty) {
      return AnalysisResult(EegMetrics.empty(), 0.0, 0.0);
    }
    return await compute(_processSync, AnalysisPayload(view, sampleRate));
  }

  static AnalysisResult _processSync(AnalysisPayload payload) {
    final view = payload.view;
    final sampleRate = payload.sampleRate;

    final hjorth = SignalProcessor.hjorthParameters(view);
    final hjorthActivity = hjorth['Activity'] ?? 0.0;
    final hjorthMobility = hjorth['Mobility'] ?? 0.0;

    final windowedSamples = SignalProcessor.applyHannWindow(view);
    final complexSamples = windowedSamples.map((v) => Complex(v, 0.0)).toList();
    final fftResults = SignalProcessor.fft(complexSamples);

    int half = fftResults.length ~/ 2;
    double n = windowedSamples.length.toDouble();
    List<double> mag = List.generate(half, (i) => fftResults[i].abs() / (n / 2));
    List<double> freq = List.generate(half, (i) => i * sampleRate / n);

    Map<String, double> bandPowers = {};
    for (var band in BandConfig.allBands) {
      bandPowers[band.name] = SignalProcessor.bandPower(mag, mag.length * 2, band.minFreq, band.maxFreq);
    }

    double peakAlphaFreq = 0.0;
    double maxAlphaMag = -1.0;
    final alphaBand = BandConfig.allBands.firstWhere((b) => b.name == 'Alpha');

    for (int i = 0; i < mag.length; i++) {
      if (freq[i] >= alphaBand.minFreq && freq[i] <= alphaBand.maxFreq) {
        if (mag[i] > maxAlphaMag) {
          maxAlphaMag = mag[i];
          peakAlphaFreq = freq[i];
        }
      }
    }

    final metrics = EegMetrics(
      rawSamples: view,
      fftMagnitude: mag,
      fftFrequencies: freq,
      bandPowers: bandPowers,
      dominantFrequency: peakAlphaFreq,
    );

    return AnalysisResult(metrics, hjorthActivity, hjorthMobility);
  }
}