import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/band_config.dart';
import '../core/complex.dart';
import '../core/eeg_metrics.dart';
import '../core/constants.dart';
import 'signal_processor.dart';

class DataPipeline with ChangeNotifier {
  List<String> _channels = ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'];
  Map<String, List<double>> _buffers = {};
  int _bufferIndex = 0;
  bool _isFromFile = false;
  Map<String, List<double>> _fileData = {};
  int _filePlaybackIndex = 0;
  Timer? _timer;
  bool _isRunning = false;
  String _selectedAnalysisChannel = 'Fp1';
  EegMetrics _currentMetrics = EegMetrics.empty();
  double _hjorthActivity = 0.0;
  double _hjorthMobility = 0.0;

  List<String> get channels => List.unmodifiable(_channels);
  bool get isFromFile => _isFromFile;
  bool get isRunning => _isRunning;
  String get selectedAnalysisChannel => _selectedAnalysisChannel;
  EegMetrics get currentMetrics => _currentMetrics;
  double get hjorthActivity => _hjorthActivity;
  double get hjorthMobility => _hjorthMobility;
  final double offsetStep = 6.0;

  DataPipeline() {
    _initBuffers();
  }

  void _initBuffers() {
    _buffers = { for (var ch in _channels) ch: List.filled(bufferLength, 0.0) };
    _bufferIndex = 0;
  }

  void loadFileData(Map<String, List<double>> data, List<String> newChannels) {
    if (_isRunning) togglePlayback();
    _channels = newChannels;
    _fileData = data;
    _isFromFile = true;
    _filePlaybackIndex = 0;
    if (!_channels.contains(_selectedAnalysisChannel)) {
      _selectedAnalysisChannel = _channels.first;
    }
    _initBuffers();
    notifyListeners();
  }

  void useMockData() {
    if (_isRunning) togglePlayback();
    _isFromFile = false;
    _channels = ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'];
    _initBuffers();
    notifyListeners();
  }

  void togglePlayback() {
    if (_isRunning) {
      _stopPlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_isFromFile && _fileData.isEmpty) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ sampleRate), (timer) {
      _updateBuffers();
      _maybeUpdateAnalysis();
    });
    notifyListeners();
  }

  void _stopPlayback() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void _updateBuffers() {
    if (_isFromFile) {
      for (var ch in _channels) {
        if (_fileData.containsKey(ch)) {
          _buffers[ch]![_bufferIndex] = _fileData[ch]![_filePlaybackIndex % _fileData[ch]!.length];
        }
      }
      _filePlaybackIndex++;
    } else {
      final t = _bufferIndex / sampleRate;
      for (int i = 0; i < _channels.length; i++) {
        final ch = _channels[i];
        _buffers[ch]![_bufferIndex] = SignalProcessor.generateSample(t + i * 0.1);
      }
    }
    _bufferIndex = (_bufferIndex + 1) % bufferLength;
  }

  void _maybeUpdateAnalysis() {
    if (_bufferIndex % (bufferLength ~/ 4) == 0) {
      _performAnalysis();
      notifyListeners();
    }
  }

  List<double> viewBuffer(String channel) {
    final view = <double>[];
    final buf = _buffers[channel] ?? List.filled(bufferLength, 0.0);
    for (int i = 0; i < bufferLength; i++) {
      view.add(buf[(_bufferIndex + i) % bufferLength]);
    }
    return view;
  }

  void setSelectedChannel(String ch) {
    if (!_channels.contains(ch)) return;
    _selectedAnalysisChannel = ch;
    _performAnalysis();
    notifyListeners();
  }

  void _performAnalysis() {
    final view = viewBuffer(_selectedAnalysisChannel);
    if (view.isEmpty) return;

    final hjorth = SignalProcessor.hjorthParameters(view);
    _hjorthActivity = hjorth['Activity'] ?? 0.0;
    _hjorthMobility = hjorth['Mobility'] ?? 0.0;

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
      double currentFreq = freq[i];
      if (currentFreq >= alphaBand.minFreq && currentFreq <= alphaBand.maxFreq) {
        if (mag[i] > maxAlphaMag) {
          maxAlphaMag = mag[i];
          peakAlphaFreq = currentFreq;
        }
      }
    }

    _currentMetrics = EegMetrics(
      rawSamples: view,
      fftMagnitude: mag,
      fftFrequencies: freq,
      bandPowers: bandPowers,
      dominantFrequency: peakAlphaFreq,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}