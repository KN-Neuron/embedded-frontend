import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eeg_dashboard_app/core/constants.dart';

class SignalView extends StatelessWidget {
  final List<String> channels;
  final List<double> Function(String channel) viewBuffer;
  final double offsetStep;
  final int sampleRate;

  const SignalView({
    Key? key,
    required this.channels,
    required this.viewBuffer,
    required this.offsetStep,
    required this.sampleRate
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const Center(child: Text('awaiting EEG data...'));

    List<LineChartBarData> lineBars = [];

    for (int i = 0; i < channels.length; i++) {
      final chName = channels[i];
      final view = viewBuffer(chName);
      final offset = i * offsetStep;

      lineBars.add(
        LineChartBarData(
          spots: List.generate(view.length, (idx) => FlSpot(idx.toDouble(), view[idx] + offset)),
          isCurved: true,
          curveSmoothness: 0.1,
          color: primaryColor.withAlpha((0.8 * 255).round()),
          barWidth: 1.2,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minY: -(offsetStep / 2),
        maxY: (channels.length * offsetStep) - (offsetStep / 2),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: offsetStep,
                  getTitlesWidget: (value, meta) {
                    for (int i = 0; i < channels.length; i++) {
                      if ((value - (i * offsetStep)).abs() < 0.1) {
                        return Center(child: Text(channels[i], style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)));
                      }
                    }
                    return const SizedBox.shrink();
                  }
              )
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            if (value.toInt() % (sampleRate * 1) == 0) {
              return SideTitleWidget(meta: meta, child: Text('${value ~/ sampleRate} s', style: const TextStyle(color: Colors.grey, fontSize: 10)));
            }
            return const SizedBox.shrink();
          })),
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
}