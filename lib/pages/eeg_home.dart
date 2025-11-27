import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io' show Platform, File;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eeg_dashboard_app/utils/constants.dart';
import 'package:eeg_dashboard_app/utils/signal_processor.dart';
import 'package:eeg_dashboard_app/pages/brain_demo_page.dart';

class EEGHome extends StatefulWidget {
  const EEGHome({super.key});
  @override
  State<EEGHome> createState() => _EEGHomeState();
}

class _EEGHomeState extends State<EEGHome> with SingleTickerProviderStateMixin {
  final List<double> _eegBuffer = List.filled(bufferLength, 0.0);
  int _bufferIndex = 0;
  Timer? _timer;
  bool _isRunning = false;

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
    _loadApiKey();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
        _apiKey = key.trim();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint('could not save API Key: $e');
      }
    } else {
      _apiKey = key.trim();
      if (mounted) setState(() {});
    }
  }

  void _startRealtime() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ sampleRate), (timer) {
      final t = _bufferIndex / sampleRate;
      final sample = SignalProcessor.generateSample(t);
      _eegBuffer[_bufferIndex] = sample;
      _bufferIndex = (_bufferIndex + 1) % bufferLength;

      if (_bufferIndex % (bufferLength ~/ 4) == 0) {
        if (mounted) {
          setState(() {
            _updateAnalysis();
          });
        }
      }
    });
    if (mounted) setState(() {});
  }

  void _stopRealtime() {
    _timer?.cancel();
    _isRunning = false;
    if (mounted) setState(() {});
  }

  List<double> _viewBuffer() {
    final view = <double>[];
    for (int i = 0; i < bufferLength; i++) {
      view.add(_eegBuffer[(_bufferIndex + i) % bufferLength]);
    }
    return view;
  }

  void _updateAnalysis() {
    final view = _viewBuffer();

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
      'TotalPower': _totalPower.toStringAsFixed(2),
      'AlphaPower': _alphaPower.toStringAsFixed(2),
      'BetaPower': _betaPower.toStringAsFixed(2),
      'ThetaPower': _thetaPower.toStringAsFixed(2),
      'DeltaPower': _deltaPower.toStringAsFixed(2),
      'AlphaPeakFreq': _alphaPeakFreq.toStringAsFixed(2),
      'HjorthActivity': _hjorthActivity.toStringAsFixed(2),
      'HjorthMobility': _hjorthMobility.toStringAsFixed(2),
    };

    final prompt = """
      You are an expert neuroscientist. Analyze the following synthetic EEG power metrics and provide a brief, professional summary (max 3 sentences) on the likely state of the subject (e.g., relaxed, focused, drowsy).
      
      Metrics:
      ${dataSummary.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}
      
      Based on the dominant bands, what is the most probable state?
      """;

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [{'parts': [{'text': prompt}]}],
        }),
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
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Dashboard Title on the Left
            Text(
              'EEG Data Simulator',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),

            // Buttons on the Right
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? _stopRealtime : _startRealtime,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'pause' : 'start'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: _isRunning ? Colors.red : primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BrainDemoPage()),
                  ),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('learn'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.amber,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAnalysisDrawer = !_showAnalysisDrawer;
                    });
                  },
                  icon: Icon(_showAnalysisDrawer ? Icons.bar_chart : Icons.bar_chart_outlined),
                  label: Text(_showAnalysisDrawer ? 'hide data analysis' : 'show data analysis'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalView(List<double> view, BuildContext context) {
    if (view.isEmpty) return const Center(child: Text('awaiting data...'));

    return LineChart(
      LineChartData(
        minY: -2.0,
        maxY: 2.0,
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: _bottomTitles)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: cardColor)),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(view.length, (i) => FlSpot(i.toDouble(), view[i])),
            isCurved: false,
            color: primaryColor,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  static Widget _bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(color: Colors.grey, fontSize: 10);
    String text;
    if (value.toInt() % (sampleRate * 1) == 0) {
      text = '${value ~/ sampleRate} s';
    } else {
      return Container();
    }
    return SideTitleWidget(
        meta: meta,
        child: Text(text, style: style)
    );
  }

  Widget _buildAnalysisBar(BuildContext context) {
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
                  e.value.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAnalysisDrawer(List<double> view, BuildContext context) {
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
                  Text('Hjorth Parameters', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: primaryColor)),
                  const SizedBox(height: 10),
                  _buildMetricRow('Activity (Variance):', _hjorthActivity.toStringAsFixed(4)),
                  _buildMetricRow('Mobility (Complexity):', _hjorthMobility.toStringAsFixed(4)),
                  _buildMetricRow('Alpha Peak Freq:', '${_alphaPeakFreq.toStringAsFixed(2)} Hz'),
                ],
              ),
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

  Widget _buildSpectrumChart(BuildContext context) {
    if (_spectrum.isEmpty) return const Center(child: Text('run simulation to view spectrum'));

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
                return Container();
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

  @override
  Widget build(BuildContext context) {
    final view = _viewBuffer();
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
                  _buildAnalysisBar(context),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildSignalView(view, context),
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
              child: _buildAnalysisDrawer(view, context),
            ),
        ],
      ),
    );
  }
}