import 'dart:async';
import 'package:flutter/foundation.dart';
import 'signal_processor.dart';
import '../core/constants.dart';
import 'eeg_analysis_processor.dart';

class PlaybackController with ChangeNotifier {
  final EegAnalysisState analysisState;

  List<String> _channels = ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'];
  List<String> get channels => List.unmodifiable(_channels);

  Map<String, List<double>> _buffers = {};
  int _bufferIndex = 0;

  bool _isFromFile = false;
  bool get isFromFile => _isFromFile;

  Map<String, List<double>> _fileData = {};
  int _filePlaybackIndex = 0;

  Timer? _timer;
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  final double offsetStep = 6.0;

  PlaybackController(this.analysisState) {
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
    if (!_channels.contains(analysisState.selectedAnalysisChannel)) {
      analysisState.setSelectedChannel(_channels.first);
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
      _timer?.cancel();
      _isRunning = false;
      notifyListeners();
    } else {
      if (_isFromFile && _fileData.isEmpty) return;
      _isRunning = true;
      _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ sampleRate), (timer) {
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
        if (_bufferIndex % (bufferLength ~/ 4) == 0) {
          final view = viewBuffer(analysisState.selectedAnalysisChannel);
          analysisState.updateAnalysis(view);
          notifyListeners();
        }
      });
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}