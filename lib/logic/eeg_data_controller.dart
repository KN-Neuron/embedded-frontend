import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/band_config.dart';
import '../core/complex.dart';
import '../core/eeg_metrics.dart';
import '../core/constants.dart';
import '../data/eeg_repository.dart';
import 'signal_processor.dart';

class DataPipeline with ChangeNotifier {
  EegRepository _repository = MockEegRepository();
  Map<String, List<double>> _buffers = {};
  int _bufferIndex = 0;
  int _globalIndex = 0;
  Timer? _timer;
  bool _isRunning = false;
  String _selectedAnalysisChannel = 'Fp1';
  EegMetrics _currentMetrics = EegMetrics.empty();
  double _hjorthActivity = 0.0;
  double _hjorthMobility = 0.0;

  List<String> get channels => _repository.getChannels();
  bool get isFromFile => _repository is FileEegRepository;
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
    _buffers = { for (var ch in channels) ch: List.filled(bufferLength, 0.0) };
    _bufferIndex = 0;
    _globalIndex = 0;
  }

  Future<void> loadFile(String filePath) async {
    if (_isRunning) togglePlayback();
    final newRepository = await FileEegRepository.loadFromFile(filePath);
    if (newRepository.getChannels().isNotEmpty) {
      _repository = newRepository;
      if (!_repository.getChannels().contains(_selectedAnalysisChannel)) {
        _selectedAnalysisChannel = _repository.getChannels().first;
      }
      _initBuffers();
      notifyListeners();
    }
  }

  void useMockData() {
    if (_isRunning) togglePlayback();
    _repository = MockEegRepository();
    _selectedAnalysisChannel = 'Fp1';
    _initBuffers();
    notifyListeners();
  }

  void togglePlayback() {
    if (_isRunning) {
      _timer?.cancel();
      _isRunning = false;
    } else {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ sampleRate), (timer) {
        _updateBuffers();
        if (_bufferIndex % (bufferLength ~/ 4) == 0) {
          _performAnalysis();
          notifyListeners();
        }
      });
    }
    notifyListeners();
  }

  void _updateBuffers() {
    final nextSamples = _repository.getNextSamples(_globalIndex);
    nextSamples.forEach((channel, value) {
      if (_buffers.containsKey(channel)) {
        _buffers[channel]![_bufferIndex] = value;
      }
    });
    _bufferIndex = (_bufferIndex + 1) % bufferLength;
    _globalIndex++;
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
    if (!channels.contains(ch)) return;
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
      if (freq[i] >= alphaBand.minFreq && freq[i] <= alphaBand.maxFreq) {
        if (mag[i] > maxAlphaMag) {
          maxAlphaMag = mag[i];
          peakAlphaFreq = freq[i];
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