import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:eeg_dashboard_app/core/constants.dart';
import 'package:eeg_dashboard_app/logic/signal_processor.dart';
import 'package:eeg_dashboard_app/ui/screens/educational_screen.dart';

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

  Widget _buildControlsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Text(
              'EEG Dashboard',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAndLoadFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Load CSV'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blueGrey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _useMockData,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Mock Data'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRunning ? _stopRealtime : _startRealtime,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Pause' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _isRunning ? Colors.red : primaryColor,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const EducationalScreen()),
                  ),
                  icon: const Icon(Icons.school, color: Colors.amber),
                  tooltip: 'Learn 10-20 System',
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showAnalysisDrawer = !_showAnalysisDrawer;
                    });
                  },
                  icon: Icon(_showAnalysisDrawer ? Icons.bar_chart : Icons.bar_chart_outlined, color: Colors.teal),
                  tooltip: 'Toggle Analysis Drawer',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisBar(BuildContext context) {
    if (_channels.isEmpty) return const SizedBox.shrink();

    final bands = {
      'Alpha': _alphaPower,
      'Beta': _betaPower,
      'Theta': _thetaPower,
      'Delta': _deltaPower,
    };
    final sortedBands = bands.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: sortedBands.map((e) {
            final percentage = (_totalPower > 0 ? e.value / _totalPower : 0.0) * 100;
            return Column(
              children: [
                Text(e.key, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: bandColors[e.key]!)),
                const SizedBox(height: 4),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(color: bandColors[e.key]!),
                ),
                Text(
                  'Power: ${e.value.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSignalView(BuildContext context) {
    if (_channels.isEmpty) return const Center(child: Text('awaiting EEG data...'));

    List<LineChartBarData> lineBars = [];

    for (int i = 0; i < _channels.length; i++) {
      final chName = _channels[i];
      final view = _viewBuffer(chName);
      final offset = i * _offsetStep;

      lineBars.add(
        LineChartBarData(
          spots: List.generate(view.length, (idx) => FlSpot(idx.toDouble(), view[idx] + offset)),
          isCurved: true,
          curveSmoothness: 0.1,
          color: primaryColor.withOpacity(0.8),
          barWidth: 1.2,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: -(_offsetStep / 2),
        maxY: (_channels.length * _offsetStep) - (_offsetStep / 2),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 1.0,
                  getTitlesWidget: (value, meta) {
                    for (int i = 0; i < _channels.length; i++) {
                      if ((value - (i * _offsetStep)).abs() < 0.1) {
                        return Center(child: Text(_channels[i], style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)));
                      }
                    }
                    return const SizedBox.shrink();
                  }
              )
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10)),
        lineBarsData: lineBars,
      ),
    );
  }

  static Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 10);
    if (value.toInt() % (sampleRate * 1) == 0) {
      return SideTitleWidget(meta: meta, child: Text('${value ~/ sampleRate} s', style: style));
    }
    return const SizedBox.shrink();
  }

  Widget _buildSpectrumChart(BuildContext context) {
    if (_spectrum.isEmpty) return const Center(child: Text('awaiting EEG data...'));

    int fftSize = 1;
    while (fftSize < bufferLength) fftSize <<= 1;
    final df = sampleRate / fftSize;

    return BarChart(
      BarChartData(
        maxY: _spectrum.reduce(max) * 1.2,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              getTitlesWidget: (value, meta) {
                final freq = value * df;
                if (freq % 5 == 0 && freq <= 30) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text('${freq.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_spectrum.length, (i) {
          final freq = i * df;
          Color color;
          if (freq >= deltaLow && freq <= deltaHigh) color = bandColors['Delta']!;
          else if (freq > deltaHigh && freq <= thetaHigh) color = bandColors['Theta']!;
          else if (freq > thetaHigh && freq <= alphaHigh) color = bandColors['Alpha']!;
          else if (freq > alphaHigh && freq <= betaHigh) color = bandColors['Beta']!;
          else color = Colors.grey.withOpacity(0.3);

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: _spectrum[i],
                color: color,
                width: 1,
                borderRadius: BorderRadius.zero,
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAnalysisDrawer(BuildContext context) {
    return Container(
      color: cardColor.withOpacity(0.5),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Analyze Channel:', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: primaryColor)),
                      DropdownButton<String>(
                        value: _selectedAnalysisChannel,
                        dropdownColor: cardColor,
                        underline: Container(height: 1, color: primaryColor),
                        items: _channels.map((String ch) {
                          return DropdownMenuItem<String>(
                            value: ch,
                            child: Text(ch, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedAnalysisChannel = newValue;
                              _updateAnalysis();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildMetricRow('Hjorth Activity:', _hjorthActivity.toStringAsFixed(4)),
                  _buildMetricRow('Hjorth Mobility:', _hjorthMobility.toStringAsFixed(4)),
                  _buildMetricRow('Alpha Peak Freq:', '${_alphaPeakFreq.toStringAsFixed(2)} Hz'),
                ],
              ),
            ),
          ),
          Card(
            color: cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0).copyWith(bottom: 0),
                  child: Text('FFT Power Spectrum (PSD)', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: primaryColor)),
                ),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildSpectrumChart(context),
                  ),
                ),
              ],
            ),
          ),
          Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gemini AI Analysis', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: secondaryColor)),
                  const SizedBox(height: 10),
                  TextField(
                    onSubmitted: _saveApiKey,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _apiKey.isNotEmpty ? 'API Key Set' : 'Enter Gemini API Key',
                      border: const OutlineInputBorder(),
                      suffixIcon: Icon(_apiKey.isNotEmpty ? Icons.check_circle : Icons.vpn_key),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _performAIAnalysis,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('analyze with AI'),
                      style: ElevatedButton.styleFrom(backgroundColor: secondaryColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_aiAnalysisResult, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ].expand((widget) => [widget, const SizedBox(height: 10)]).toList(),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: primaryColor)),
        ],
      ),
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
                  _buildControlsCard(context),
                  const SizedBox(height: 10),
                  if (_showAnalysisDrawer) _buildAnalysisBar(context),
                  if (_showAnalysisDrawer) const SizedBox(height: 10),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 4, right: 12, top: 12, bottom: 4),
                        child: _buildSignalView(context),
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
              child: _buildAnalysisDrawer(context),
            ),
        ],
      ),
    );
  }
}