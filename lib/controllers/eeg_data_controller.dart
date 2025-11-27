import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/eeg_metrics.dart';
import '../../processors/eeg_analysis_processor.dart';

/// manages and updates the EEG data and analysis results using Provider
class EegDataController with ChangeNotifier {
  final EegAnalysisProcessor _processor = EegAnalysisProcessor();
  EegMetrics _currentMetrics = EegMetrics.empty();
  Timer? _timer;

  EegMetrics get currentMetrics => _currentMetrics;

  EegDataController() {
    startAnalysisLoop();
  }

  /// start of the data simulation and processing loop!!
  void startAnalysisLoop() {
    updateData();

    // recurring timer to simulate real-time updates every 4 seconds
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      updateData();
    });
  }

  /// executes the signal processor and updates the state
  void updateData() {
    try {
      _currentMetrics = _processor.processSignal();
      // notifies all listening UI widgets to rebuild
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('error updating EEG data :c : $e');
      }
      // someday, there will be an error state metric here..
    }
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}