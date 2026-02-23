import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:eeg_dashboard_app/core/constants.dart';
import 'package:eeg_dashboard_app/logic/signal_processor.dart';
import 'package:eeg_dashboard_app/ui/screens/educational_screen.dart';

import 'dashboard/controls_card.dart';
import 'dashboard/analysis_bar.dart';
import 'dashboard/signal_view.dart';
import 'dashboard/analysis_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  List<String> _channels = ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'];
  Map<String, List<double>> _buffers = {};
  int _bufferIndex = 0;

  bool _isFromFile = false;
  Map<String, List<double>> _fileData = {};
  int _filePlaybackIndex = 0;

  Timer? _timer;
  bool _isRunning = false;
  final double _offsetStep = 6.0;

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
  static const String _geminiApiKeyFileName = 'gemini_api_key.txt';

  bool _showAnalysisDrawer = true;

  @override
  void initState() {
    super.initState();
    _initBuffers();
    _loadApiKey();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initBuffers() {
    _buffers = { for (var ch in _channels) ch: List.filled(bufferLength, 0.0) };
    _bufferIndex = 0;

    if (_channels.isNotEmpty && !_channels.contains(_selectedAnalysisChannel)) {
      _selectedAnalysisChannel = _channels.first;
    }
  }

  Future<void> _loadApiKey() async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_geminiApiKeyFileName');
        if (await file.exists()) {
          _apiKey = (await file.readAsString()).trim();
          if (mounted) setState(() {});
        }
      } catch (e) {
        debugPrint('could not load API Key: $e');
      }
    }
  }

  Future<void> _saveApiKey(String key) async {
    if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$_geminiApiKeyFileName');
        await file.writeAsString(key.trim());
      } catch (e) {
        debugPrint('could not save API Key: $e');
      }
    }
    _apiKey = key.trim();
    if (mounted) setState(() {});
  }

  Future<void> _pickAndLoadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        _stopRealtime();
        final file = File(result.files.single.path!);
        final lines = await file.readAsLines();
        if (lines.isEmpty) return;

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

        setState(() {
          _channels = loadedChannels;
          _fileData = loadedData;
          _isFromFile = true;
          _filePlaybackIndex = 0;
          _initBuffers();
          _updateAnalysis();
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Loaded ${loadedChannels.length} channels from CSV')));
      }
    } catch (e) {
      debugPrint('Error loading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load file: $e')));
    }
  }

  void _useMockData() {
    _stopRealtime();
    setState(() {
      _isFromFile = false;
      _channels = ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'];
      _initBuffers();
      _updateAnalysis();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Switched to Mock Data')));
  }

  void _startRealtime() {
    if (_isRunning) return;
    if (_isFromFile && _fileData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file loaded!')));
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
        if (mounted) setState(() => _updateAnalysis());
      }
    });
    if (mounted) setState(() {});
  }

  void _stopRealtime() {
    _timer?.cancel();
    _isRunning = false;
    if (mounted) setState(() {});
  }

  List<double> _viewBuffer(String channel) {
    final view = <double>[];
    final buf = _buffers[channel] ?? List.filled(bufferLength, 0.0);
    for (int i = 0; i < bufferLength; i++) {
      view.add(buf[(_bufferIndex + i) % bufferLength]);
    }
    return view;
  }

  void _updateAnalysis() {
    if (_channels.isEmpty || !_buffers.containsKey(_selectedAnalysisChannel)) return;

    final view = _viewBuffer(_selectedAnalysisChannel);

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
  }

  Future<void> _performAIAnalysis() async {
    if (_apiKey.isEmpty) {
      if (mounted) setState(() => _aiAnalysisResult = 'error: API Key is not set');
      return;
    }
    if (!_isRunning) {
      if (mounted) setState(() => _aiAnalysisResult = 'error: please start the simulation first');
      return;
    }

    if (mounted) setState(() => _aiAnalysisResult = 'analyzing data with Gemini...');

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

    final prompt = """
      You are an expert neuroscientist. Analyze the following EEG power metrics and time-domain features (from channel $_selectedAnalysisChannel) and provide a brief, professional summary (max 3 sentences) on the likely state of the subject.
      
      Metrics:
      ${dataSummary.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}
      """;

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'contents': [{'parts': [{'text': prompt}]}]}),
      );

      final jsonResponse = json.decode(response.body);
      final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];

      if (mounted) setState(() => _aiAnalysisResult = text);
    } catch (e) {
      if (mounted) setState(() => _aiAnalysisResult = 'AI Analysis Error: $e');
    }
  }

  Widget _controlsCard(BuildContext context) {
    return ControlsCard(
      isRunning: _isRunning,
      onPickAndLoadFile: _pickAndLoadFile,
      onUseMockData: _useMockData,
      onStartStopToggle: () { _isRunning ? _stopRealtime() : _startRealtime(); },
      onOpenEducational: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EducationalScreen())),
      onToggleAnalysisDrawer: () => setState(() { _showAnalysisDrawer = !_showAnalysisDrawer; }),
      showAnalysisDrawer: _showAnalysisDrawer,
    );
  }

  Widget _analysisBar(BuildContext context) {
    if (_channels.isEmpty) return const SizedBox.shrink();
    return AnalysisBar(alpha: _alphaPower, beta: _betaPower, theta: _thetaPower, delta: _deltaPower, totalPower: _totalPower);
  }

  Widget _signalView(BuildContext context) {
    return SignalView(
      channels: _channels,
      viewBuffer: _viewBuffer,
      offsetStep: _offsetStep,
      sampleRate: sampleRate,
    );
  }

  Widget _analysisDrawerWidget(BuildContext context) {
    return AnalysisDrawer(
      channels: _channels,
      selectedChannel: _selectedAnalysisChannel,
      onSelectChannel: (s) { setState(() { _selectedAnalysisChannel = s; _updateAnalysis(); }); },
      hjorthActivity: _hjorthActivity,
      hjorthMobility: _hjorthMobility,
      alphaPeakFreq: _alphaPeakFreq,
      apiKey: _apiKey,
      onSaveApiKey: _saveApiKey,
      onPerformAIAnalysis: _performAIAnalysis,
      aiAnalysisResult: _aiAnalysisResult,
      spectrum: _spectrum,
      bufferLength: bufferLength,
      sampleRate: sampleRate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _isRunning ? 'RUNNING' : 'PAUSED',
                style: TextStyle(
                  color: _isRunning ? primaryColor : Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: _showAnalysisDrawer ? 7 : 10,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _controlsCard(context),
                  const SizedBox(height: 10),
                  if (_showAnalysisDrawer) _analysisBar(context),
                  if (_showAnalysisDrawer) const SizedBox(height: 10),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 12, top: 12, bottom: 4),
                        child: _signalView(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showAnalysisDrawer)
            Expanded(
              flex: 3,
              child: _analysisDrawerWidget(context),
            ),
        ],
      ),
    );
  }
}