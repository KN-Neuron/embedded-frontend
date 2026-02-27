import 'dart:io';
import 'package:eeg_dashboard_app/logic/signal_processor.dart';

abstract class EegRepository {
  Map<String, double> getNextSamples(int index);
  List<String> getChannels();
}

class MockEegRepository implements EegRepository {
  final List<String> _channels = ['Fp1', 'Fp2', 'C3', 'C4', 'P3', 'P4', 'O1', 'O2'];

  @override
  List<String> getChannels() => _channels;

  @override
  Map<String, double> getNextSamples(int index) {
    final t = index / 256.0;
    return {
      for (int i = 0; i < _channels.length; i++)
        _channels[i]: SignalProcessor.generateSample(t + i * 0.1)
    };
  }
}

class FileEegRepository implements EegRepository {
  final Map<String, List<double>> fileData;
  final List<String> channels;

  FileEegRepository._(this.fileData, this.channels);

  static Future<FileEegRepository> loadFromFile(String filePath) async {
    final file = File(filePath);
    final lines = await file.readAsLines();
    if (lines.isEmpty) return FileEegRepository._({}, []);

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

    Map<String, List<double>> loadedData = {
      for (var ch in loadedChannels) ch: []
    };

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

    return FileEegRepository._(loadedData, loadedChannels);
  }

  @override
  List<String> getChannels() => channels;

  @override
  Map<String, double> getNextSamples(int index) {
    if (channels.isEmpty) return {};
    return {
      for (var ch in channels)
        if (fileData[ch]!.isNotEmpty)
          ch: fileData[ch]![index % fileData[ch]!.length]
    };
  }
}