import 'dart:async';

import 'package:flutter/foundation.dart';
import '../core/eeg_metrics.dart';
import '../core/constants.dart';
import '../data/eeg_repository.dart';
import 'playback_service.dart';
import 'analysis_engine.dart';

class DataPipeline with ChangeNotifier {
  late final PlaybackService _playbackService;
  final AnalysisEngine _analysisEngine = AnalysisEngine();

  String _selectedAnalysisChannel = 'Fp1';
  EegMetrics _currentMetrics = EegMetrics.empty();
  double _hjorthActivity = 0.0;
  double _hjorthMobility = 0.0;
  final double offsetStep = 6.0;
  bool _isAnalyzing = false;

  bool _isLiveMode = false;
  StreamSubscription<List<double>>? _serialSubscription;
  Map<String, List<double>> _liveBuffers = {};
  int _liveBufferIndex = 0;
  final List<String> _liveChannels = List.generate(8, (i) => 'CH${i + 1}');

  DataPipeline() {
    _playbackService = PlaybackService(
      onTick: () {
        if (!_isLiveMode) notifyListeners();
      },
      onAnalysisTrigger: () {
        if (!_isLiveMode) _performAnalysis();
      },
    );
    _initLiveBuffers();
  }

  void _initLiveBuffers() {
    _liveBuffers = { for (var ch in _liveChannels) ch: List.filled(bufferLength, 0.0) };
    _liveBufferIndex = 0;
  }

  List<String> get channels => _isLiveMode ? _liveChannels : _playbackService.channels;
  bool get isFromFile => _isLiveMode ? false : _playbackService.isFromFile;
  bool get isRunning => _isLiveMode ? (_serialSubscription != null) : _playbackService.isRunning;
  String get selectedAnalysisChannel => _selectedAnalysisChannel;
  EegMetrics get currentMetrics => _currentMetrics;
  double get hjorthActivity => _hjorthActivity;
  double get hjorthMobility => _hjorthMobility;

  Future<void> loadFile(String filePath) async {
    if (isRunning) togglePlayback();
    _isLiveMode = false;
    final newRepository = await FileEegRepository.loadFromFile(filePath);
    if (newRepository.getChannels().isNotEmpty) {
      _playbackService.loadRepository(newRepository);
      if (!_playbackService.channels.contains(_selectedAnalysisChannel)) {
        _selectedAnalysisChannel = _playbackService.channels.first;
      }
      notifyListeners();
    }
  }

  void useMockData() {
    if (isRunning) togglePlayback();
    _isLiveMode = false;
    _playbackService.loadRepository(MockEegRepository());
    _selectedAnalysisChannel = 'Fp1';
    notifyListeners();
  }

  void togglePlayback() {
    if (_isLiveMode) return; // Should use toggleSerialPlayback for live mode
    if (_playbackService.isRunning) {
      _playbackService.stop();
    } else {
      _playbackService.start();
    }
    notifyListeners();
  }

  void toggleSerialPlayback(Stream<List<double>> serialStream) {
    if (_serialSubscription != null) {
      // Is running, so stop
      _serialSubscription?.cancel();
      _serialSubscription = null;
      _isLiveMode = false;
      // Reset selected channel
      if (!_playbackService.channels.contains(_selectedAnalysisChannel)) {
        _selectedAnalysisChannel = _playbackService.channels.first;
      }
    } else {
      // Is not running, so start
      _isLiveMode = true;
      if (!_liveChannels.contains(_selectedAnalysisChannel)) {
        _selectedAnalysisChannel = _liveChannels.first;
      }
      _initLiveBuffers();
      _serialSubscription = serialStream.listen((data) {
        _updateLiveBuffers(data);
        notifyListeners();
        if (_liveBufferIndex % (bufferLength ~/ 4) == 0) {
          _performAnalysis();
        }
      });
    }
    notifyListeners();
  }

  void _updateLiveBuffers(List<double> samples) {
    for (int i = 0; i < samples.length; i++) {
      if (i < _liveChannels.length) {
        final channel = _liveChannels[i];
        _liveBuffers[channel]![_liveBufferIndex] = samples[i];
      }
    }
    _liveBufferIndex = (_liveBufferIndex + 1) % bufferLength;
  }

  List<double> viewBuffer(String channel) {
    if (_isLiveMode) {
      final view = <double>[];
      final buf = _liveBuffers[channel] ?? List.filled(bufferLength, 0.0);
      for (int i = 0; i < bufferLength; i++) {
        view.add(buf[(_liveBufferIndex + i) % bufferLength]);
      }
      return view;
    } else {
      return _playbackService.getViewBuffer(channel);
    }
  }

  void setSelectedChannel(String ch) {
    if (!channels.contains(ch)) return;
    _selectedAnalysisChannel = ch;
    _performAnalysis();
  }

  Future<void> _performAnalysis() async {
    if (_isAnalyzing) return;
    _isAnalyzing = true;

    final view = viewBuffer(_selectedAnalysisChannel);
    final result = await _analysisEngine.analyze(view, sampleRate);

    _currentMetrics = result.metrics;
    _hjorthActivity = result.hjorthActivity;
    _hjorthMobility = result.hjorthMobility;

    _isAnalyzing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackService.dispose();
    _serialSubscription?.cancel();
    super.dispose();
  }
}