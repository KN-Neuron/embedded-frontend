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

  DataPipeline() {
    _playbackService = PlaybackService(
      onTick: () {},
      onAnalysisTrigger: () {
        _performAnalysis();
        notifyListeners();
      },
    );
  }

  List<String> get channels => _playbackService.channels;
  bool get isFromFile => _playbackService.isFromFile;
  bool get isRunning => _playbackService.isRunning;
  String get selectedAnalysisChannel => _selectedAnalysisChannel;
  EegMetrics get currentMetrics => _currentMetrics;
  double get hjorthActivity => _hjorthActivity;
  double get hjorthMobility => _hjorthMobility;

  Future<void> loadFile(String filePath) async {
    if (_playbackService.isRunning) _playbackService.stop();
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
    if (_playbackService.isRunning) _playbackService.stop();
    _playbackService.loadRepository(MockEegRepository());
    _selectedAnalysisChannel = 'Fp1';
    notifyListeners();
  }

  void togglePlayback() {
    if (_playbackService.isRunning) {
      _playbackService.stop();
    } else {
      _playbackService.start();
    }
    notifyListeners();
  }

  List<double> viewBuffer(String channel) {
    return _playbackService.getViewBuffer(channel);
  }

  void setSelectedChannel(String ch) {
    if (!channels.contains(ch)) return;
    _selectedAnalysisChannel = ch;
    _performAnalysis();
    notifyListeners();
  }

  void _performAnalysis() {
    final view = _playbackService.getViewBuffer(_selectedAnalysisChannel);
    final result = _analysisEngine.analyze(view, sampleRate);
    _currentMetrics = result.metrics;
    _hjorthActivity = result.hjorthActivity;
    _hjorthMobility = result.hjorthMobility;
  }

  @override
  void dispose() {
    _playbackService.dispose();
    super.dispose();
  }
}