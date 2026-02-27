import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/eeg_repository.dart';
import '../core/constants.dart';

class PlaybackService {
  EegRepository _repository = MockEegRepository();
  Map<String, List<double>> _buffers = {};
  int _bufferIndex = 0;
  int _globalIndex = 0;
  Timer? _timer;
  bool _isRunning = false;

  final VoidCallback onTick;
  final VoidCallback onAnalysisTrigger;

  PlaybackService({required this.onTick, required this.onAnalysisTrigger}) {
    _initBuffers();
  }

  List<String> get channels => _repository.getChannels();
  bool get isFromFile => _repository is FileEegRepository;
  bool get isRunning => _isRunning;

  void _initBuffers() {
    _buffers = { for (var ch in channels) ch: List.filled(bufferLength, 0.0) };
    _bufferIndex = 0;
    _globalIndex = 0;
  }

  void loadRepository(EegRepository repository) {
    _repository = repository;
    _initBuffers();
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ sampleRate), (timer) {
      _updateBuffers();
      onTick();
      if (_bufferIndex % (bufferLength ~/ 4) == 0) {
        onAnalysisTrigger();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
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

  List<double> getViewBuffer(String channel) {
    final view = <double>[];
    final buf = _buffers[channel] ?? List.filled(bufferLength, 0.0);
    for (int i = 0; i < bufferLength; i++) {
      view.add(buf[(_bufferIndex + i) % bufferLength]);
    }
    return view;
  }

  void dispose() {
    _timer?.cancel();
  }
}