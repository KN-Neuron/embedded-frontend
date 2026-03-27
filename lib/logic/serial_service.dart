import 'dart:async';
import 'dart:typed_data';
import 'package:libserialport/libserialport.dart';

class SerialService {
  SerialPort? _port;
  bool _isConnected = false;
  SerialPortReader? _reader;
  StreamController<List<double>>? _controller;
  StreamSubscription? _readerSubscription;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    final availablePorts = SerialPort.availablePorts;
    if (availablePorts.isEmpty) {
      print('No serial ports found.');
      return;
    }
    print('Available ports: $availablePorts');
    final portName = '/dev/ttyACM0'; // Or the first available one
    
    _port = SerialPort(portName);
    if (!_port!.openReadWrite()) {
      print("Failed to open serial port: ${SerialPort.lastError}");
      _isConnected = false;
      return;
    }

    final config = _port!.config;
    config.baudRate = 115200;
    config.bits = 8;
    config.parity = SerialPortParity.none;
    config.stopBits = 1;
    config.setFlowControl(SerialPortFlowControl.none);
    _port!.config = config;

    _isConnected = true;
    print('Serial port connected.');
  }

  void disconnect() {
    _readerSubscription?.cancel();
    _controller?.close();
    _port?.close();
    _isConnected = false;
    _reader = null;
    _controller = null;
    _readerSubscription = null;
    print('Serial port disconnected.');
  }

  Stream<List<double>> startReading() {
    if (_controller == null) {
      _controller = StreamController<List<double>>.broadcast();
      _reader = SerialPortReader(_port!);
      List<int> buffer = [];
      _readerSubscription = _reader!.stream.listen((data) {
        buffer.addAll(data);
        while (buffer.length >= 25) {
          final startByteIndex = buffer.indexOf('A'.codeUnitAt(0));
          if (startByteIndex == -1) {
            buffer.clear();
            return;
          }
          if (startByteIndex > 0) {
            buffer.removeRange(0, startByteIndex);
          }
          if (buffer.length < 25) {
            return;
          }
          final packet = buffer.sublist(0, 25);
          buffer.removeRange(0, 25);
          if (packet[0] == 'A'.codeUnitAt(0)) {
            final channels = _parsePacket(Uint8List.fromList(packet));
            if (_controller != null && !_controller!.isClosed) {
              _controller!.add(channels);
            }
          }
        }
      });
    }
    return _controller!.stream;
  }

  List<double> _parsePacket(Uint8List packet) {
    final channels = <double>[];
    final data = ByteData.view(packet.buffer);

    for (int i = 0; i < 8; i++) {
      int offset = 1 + i * 3;
      // Read 3 bytes for a 24-bit signed integer (big-endian)
      int value = data.getUint8(offset) << 16 |
                  data.getUint8(offset + 1) << 8 |
                  data.getUint8(offset + 2);

      // Sign extend if the 24th bit is 1
      if ((value & 0x800000) != 0) {
        value = value - 0x1000000;
      }
      
      // Normalize and scale
      double processedValue = (value / 8388608.0) * 5.0; // 2^23, since it's signed
      channels.add(processedValue);
    }
    return channels;
  }
}
