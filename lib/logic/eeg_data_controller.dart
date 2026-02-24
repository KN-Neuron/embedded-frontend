import 'dart:async';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import '../core/eeg_metrics.dart';
import 'signal_processor.dart';
import '../core/constants.dart';
import 'ai_analysis_service.dart';

/// manages and updates the EEG data and analysis results using Provider
class EegDataController with ChangeNotifier {
  final AiAnalysisService _aiService = AiAnalysisService();

  List<String> _channels = ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'];
  Map<String, List<double>> _buffers = {};
  int _bufferIndex = 0;

  bool _isFromFile = false;
  Map<String, List<double>> _fileData = {};
  int _filePlaybackIndex = 0;

  Timer? _timer;
  bool _isRunning = false;
  final double offsetStep = 6.0;

  String _selectedAnalysisChannel = 'Fp1';

  List<double> _spectrum = [];
  double _totalPower = 0.0;
  double _alphaPower = 0.0;
  double _betaPower = 0.0;
  double _thetaPower = 0.0;
  double _deltaPower = 0.0;
  double _alphaPeakFreq = 0.0;

  double _hjorthActivity = 0.0;
  double _hjorthMobility = 0.0;

  String _aiAnalysisResult = 'press "analyze with AI" to get a report.';
  String _apiKey = '';

  EegMetrics _currentMetrics = EegMetrics.empty();

  EegDataController() {
    _initBuffers();
    _initApiKey();
  }

  List<String> get channels => List.unmodifiable(_channels);
  bool get isFromFile => _isFromFile;
  bool get isRunning => _isRunning;
  String get selectedAnalysisChannel => _selectedAnalysisChannel;
  List<double> get spectrum => List.unmodifiable(_spectrum);
  double get totalPower => _totalPower;
  double get alphaPower => _alphaPower;
  double get betaPower => _betaPower;
  double get thetaPower => _thetaPower;
  double get deltaPower => _deltaPower;
  double get alphaPeakFreq => _alphaPeakFreq;
  double get hjorthActivity => _hjorthActivity;
  double get hjorthMobility => _hjorthMobility;
  String get aiAnalysisResult => _aiAnalysisResult;
  String get apiKey => _apiKey;
  EegMetrics get currentMetrics => _currentMetrics;

  void _initBuffers() {
    _buffers = { for (var ch in _channels) ch: List.filled(bufferLength, 0.0) };
    _bufferIndex = 0;

    if (_channels.isNotEmpty && !_channels.contains(_selectedAnalysisChannel)) {
      _selectedAnalysisChannel = _channels.first;
    }
  }

  Future<void> _initApiKey() async {
    try {
      _apiKey = await _aiService.loadApiKey();
      if (_apiKey.isNotEmpty) notifyListeners();
    } catch (e) {
      if (kDebugMode) debugPrint('could not load API Key: $e');
    }
  }

  Future<void> saveApiKey(String key) async {
    await _aiService.saveApiKey(key);
    _apiKey = key.trim();
    notifyListeners();
  }

  /// load CSV file at [path], parse channels and numeric data.
  /// returns true on success, false on failure or empty data.
  Future<bool> loadCsvFromPath(String path) async {
    try {
      final file = File(path);
      final lines = await file.readAsLines();
      if (lines.isEmpty) return false;

      final headers = lines.first.split(',');
      List<String> loadedChannels = [];
      List<int> channelIndices = [];

      for (int i = 0; i < headers.length; i++) {
        final h = headers[i].trim();
        if (h.isNotEmpty && h != 'Class' && h != 'ID') {
          loadedChannels.add(h);
          channelIndices.add(i);
        }
      }

      Map<String, List<double>> loadedData = { for (var ch in loadedChannels) ch: [] };

      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.length < headers.length) continue;

        for (int j = 0; j < loadedChannels.length; j++) {
          final ch = loadedChannels[j];
          final idx = channelIndices[j];
          final val = (double.tryParse(parts[idx].trim()) ?? 0.0) / 100.0;
          loadedData[ch]!.add(val);
        }
      }

      if (loadedChannels.isEmpty) return false;

      _channels = loadedChannels;
      _fileData = loadedData;
      _isFromFile = true;
      _filePlaybackIndex = 0;
      _initBuffers();
      _updateAnalysis();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading CSV: $e');
      return false;
    }
  }

  void useMockData() {
    stopRealtime();
    _isFromFile = false;
    _channels = ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'];
    _initBuffers();
    _updateAnalysis();
    notifyListeners();
  }

  void startRealtime() {
    if (_isRunning) return;
    if (_isFromFile && _fileData.isEmpty) {
      return;
    }

    _isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ sampleRate), (timer) {
      if (_isFromFile) {
        for (var ch in _channels) {
          _buffers[ch]![_bufferIndex] = _fileData[ch]![_filePlaybackIndex % _fileData[ch]!.length];
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

      if (_bufferIndex % (bufferLength ~/ 4) == 0) {
        _updateAnalysis();
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void stopRealtime() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void toggleRealtime() {
    if (_isRunning) stopRealtime(); else startRealtime();
  }

  List<double> viewBuffer(String channel) {
    final view = <double>[];
    final buf = _buffers[channel] ?? List.filled(bufferLength, 0.0);
    for (int i = 0; i < bufferLength; i++) {
      view.add(buf[(_bufferIndex + i) % bufferLength]);
    }
    return view;
  }

  void _updateAnalysis() {
    if (_channels.isEmpty || !_buffers.containsKey(_selectedAnalysisChannel)) return;

    final view = viewBuffer(_selectedAnalysisChannel);

    final spectrum = SignalProcessor.spectrumFromBuffer(view);
    int fftSize = 1;
    while (fftSize < view.length) fftSize <<= 1;
    _spectrum = spectrum;

    _deltaPower = SignalProcessor.bandPower(spectrum, fftSize, deltaLow, deltaHigh);
    _thetaPower = SignalProcessor.bandPower(spectrum, fftSize, thetaLow, thetaHigh);
    _alphaPower = SignalProcessor.bandPower(spectrum, fftSize, alphaLow, alphaHigh);
    _betaPower = SignalProcessor.bandPower(spectrum, fftSize, betaLow, betaHigh);
    _totalPower = _deltaPower + _thetaPower + _alphaPower + _betaPower;

    double maxMag = 0.0;
    int maxBin = 0;
    final df = sampleRate / fftSize;
    for (int i = (alphaLow / df).floor(); i <= (alphaHigh / df).ceil(); i++) {
      if (i < spectrum.length && spectrum[i] > maxMag) {
        maxMag = spectrum[i];
        maxBin = i;
      }
    }
    _alphaPeakFreq = maxBin * df;

    final hjorth = SignalProcessor.hjorthParameters(view);
    _hjorthActivity = hjorth['Activity']!;
    _hjorthMobility = hjorth['Mobility']!;

    _currentMetrics = EegMetrics(
      rawSamples: view,
      fftMagnitude: spectrum,
      fftFrequencies: List.generate(spectrum.length, (i) => i * df),
      bandPowers: {
        'Delta': _deltaPower,
        'Theta': _thetaPower,
        'Alpha': _alphaPower,
        'Beta': _betaPower,
      },
      dominantFrequency: _alphaPeakFreq,
    );
  }

  void setSelectedChannel(String ch) {
    if (!_channels.contains(ch)) return;
    _selectedAnalysisChannel = ch;
    _updateAnalysis();
    notifyListeners();
  }

  Future<void> performAIAnalysis() async {
    final dataSummary = {
      'Source': _isFromFile ? 'Loaded Dataset' : 'Mocked Synthetic Data',
      'Analysis Channel': _selectedAnalysisChannel,
      'TotalPower': _totalPower.toStringAsFixed(2),
      'AlphaPower': _alphaPower.toStringAsFixed(2),
      'BetaPower': _betaPower.toStringAsFixed(2),
      'ThetaPower': _thetaPower.toStringAsFixed(2),
      'DeltaPower': _deltaPower.toStringAsFixed(2),
      'AlphaPeakFreq': _alphaPeakFreq.toStringAsFixed(2),
      'HjorthActivity (Variance)': _hjorthActivity.toStringAsFixed(4),
      'HjorthMobility': _hjorthMobility.toStringAsFixed(4),
    };

    _aiAnalysisResult = 'analyzing data with Gemini...';
    notifyListeners();

    final result = await _aiService.analyzeWithGemini(dataSummary, apiKey: _apiKey);

    _aiAnalysisResult = result;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}