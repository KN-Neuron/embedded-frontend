import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eeg_dashboard_app/core/constants.dart';

class SpectrumChart extends StatelessWidget {
  final List<double> spectrum;
  final int bufferLength;
  final int sampleRate;

  const SpectrumChart({Key? key, required this.spectrum, required this.bufferLength, required this.sampleRate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (spectrum.isEmpty) return const Center(child: Text('awaiting EEG data...'));

    int fftSize = 1;
    while (fftSize < bufferLength) fftSize <<= 1;
    final df = sampleRate / fftSize;

    return BarChart(
      BarChartData(
        maxY: spectrum.reduce(max) * 1.2,
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
        barGroups: List.generate(spectrum.length, (i) {
          final freq = i * df;
          Color color;
          if (freq >= deltaLow && freq <= deltaHigh) color = bandColors['Delta']!;
          else if (freq > deltaHigh && freq <= thetaHigh) color = bandColors['Theta']!;
          else if (freq > thetaHigh && freq <= alphaHigh) color = bandColors['Alpha']!;
          else if (freq > alphaHigh && freq <= betaHigh) color = bandColors['Beta']!;
          else color = Colors.grey.withAlpha((0.3 * 255).round());

          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: spectrum[i],
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
}