import 'package:flutter/material.dart';
import 'dart:math';

enum Montage { system, referential, bipolar }

class ElectrodeLocation2D {
  final String label;
  final double x;
  final double y;
  const ElectrodeLocation2D(this.label, this.x, this.y);
}
// electrode data, for both 10-20 and montages types
const List<ElectrodeLocation2D> _electrodeLayout = [

  // top row
  ElectrodeLocation2D('Fp1', -0.35, -0.8),
  ElectrodeLocation2D('Fp2', 0.35, -0.8),
  // second row
  ElectrodeLocation2D('F7', -0.65, -0.4),
  ElectrodeLocation2D('F3', -0.35, -0.4),
  ElectrodeLocation2D('Fz', 0.0, -0.4),
  ElectrodeLocation2D('F4', 0.35, -0.4),
  ElectrodeLocation2D('F8', 0.65, -0.4),
  // third Row (central)
  ElectrodeLocation2D('A1', -0.85, 0.0), // ear reference (left)
  ElectrodeLocation2D('T3', -0.65, 0.0),
  ElectrodeLocation2D('C3', -0.35, 0.0),
  ElectrodeLocation2D('Cz', 0.0, 0.0),
  ElectrodeLocation2D('C4', 0.35, 0.0),
  ElectrodeLocation2D('T4', 0.65, 0.0),
  ElectrodeLocation2D('A2', 0.85, 0.0), // ear reference (right)
  // fourth Row
  ElectrodeLocation2D('T5', -0.65, 0.4),
  ElectrodeLocation2D('P3', -0.35, 0.4),
  ElectrodeLocation2D('Pz', 0.0, 0.4),
  ElectrodeLocation2D('P4', 0.35, 0.4),
  ElectrodeLocation2D('T6', 0.65, 0.4),
  // bottom Row
  ElectrodeLocation2D('O1', -0.35, 0.8),
  ElectrodeLocation2D('O2', 0.35, 0.8),
];

class ElectrodePainter2D extends CustomPainter {
  final String? activeLabel;
  final Montage activeMontage;

  ElectrodePainter2D(this.activeLabel, this.activeMontage);

  Offset _getElectrodePosition(String label, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Modified: Reduce scaling factors to make the head smaller
    final double headRadiusX = size.width * 0.30;
    final double headRadiusY = size.height * 0.42;
    final loc = _electrodeLayout.firstWhere((e) => e.label == label, orElse: () => const ElectrodeLocation2D('', 0.0, 0.0));
    if (loc.label.isEmpty) return Offset.zero;

    return Offset(
      center.dx + loc.x * headRadiusX,
      center.dy + loc.y * headRadiusY,
    );
  }

  void _drawMontageLines(Canvas canvas, Size size, Paint paint) {
    const List<List<String>> bipolarChains = [
      ['Fp1', 'F7', 'T3', 'T5', 'O1'], // left temporal chain
      ['Fp1', 'F3', 'C3', 'P3', 'O1'], // left parasagittal chain
      ['Fp2', 'F4', 'C4', 'P4', 'O2'], // right parasagittal chain
      ['Fp2', 'F8', 'T4', 'T6', 'O2'], // right temporal chain
    ];

    for (final chain in bipolarChains) {
      for (int i = 0; i < chain.length - 1; i++) {
        final p1 = _getElectrodePosition(chain[i], size);
        final p2 = _getElectrodePosition(chain[i + 1], size);
        // only draw if points are valid
        if (p1 != Offset.zero && p2 != Offset.zero) {
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Modified: Reduce scaling factors to make the head smaller
    final double headRadiusX = size.width * 0.30;
    final double headRadiusY = size.height * 0.42;

    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final externalPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0;

    final headRect = Rect.fromCenter(center: center, width: headRadiusX * 2, height: headRadiusY * 2);
    canvas.drawOval(headRect, headPaint);

    // nose and nasion
    final Offset nasionPoint = Offset(center.dx, center.dy - headRadiusY);
    final Offset noseTip = Offset(center.dx, nasionPoint.dy + 20);
    canvas.drawLine(nasionPoint, Offset(center.dx - 10, noseTip.dy), externalPaint);
    canvas.drawLine(nasionPoint, Offset(center.dx + 10, noseTip.dy), externalPaint);

    // ears
    final double earY = center.dy;
    final double earOffsetX = headRadiusX;
    canvas.drawArc(Rect.fromLTWH(center.dx - earOffsetX - 15, earY - 20, 15, 40), -pi / 2, pi, false, externalPaint);
    canvas.drawArc(Rect.fromLTWH(center.dx + earOffsetX, earY - 20, 15, 40), pi / 2, pi, false, externalPaint);

    final nasionLabel = 'Nasion';
    final inionLabel = 'Inion';
    final nasionLineLength = 10.0;
    final inionLineLength = 10.0;

    final Offset nasionMark = Offset(center.dx, nasionPoint.dy);
    canvas.drawLine(nasionMark, Offset(nasionMark.dx, nasionMark.dy - nasionLineLength), externalPaint);

    final Offset inionMark = Offset(center.dx, center.dy + headRadiusY);
    canvas.drawLine(inionMark, Offset(inionMark.dx, inionMark.dy + inionLineLength), externalPaint);

    final nasionStyle = TextStyle(color: Colors.white, fontSize: 14);
    final nasionPainter = TextPainter(
      text: TextSpan(text: nasionLabel, style: nasionStyle),
      textDirection: TextDirection.ltr,
    );
    nasionPainter.layout();
    nasionPainter.paint(canvas, Offset(nasionMark.dx + 5, nasionMark.dy - nasionPainter.height - 15));

    final inionStyle = TextStyle(color: Colors.white, fontSize: 14);
    final inionPainter = TextPainter(
      text: TextSpan(text: inionLabel, style: inionStyle),
      textDirection: TextDirection.ltr,
    );
    inionPainter.layout();
    inionPainter.paint(canvas, Offset(inionMark.dx + 5, inionMark.dy + 5));

    if (activeMontage == Montage.bipolar) {
      final linePaint = Paint()
        ..color = Colors.blue.shade300
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      _drawMontageLines(canvas, size, linePaint);
    }

    for (final loc in _electrodeLayout) {
      final p = _getElectrodePosition(loc.label, size);
      if (p == Offset.zero) continue;

      final bool isActive = loc.label == activeLabel;
      final bool isReference = activeMontage == Montage.referential && (loc.label == 'A1' || loc.label == 'A2' || loc.label == 'Cz');

      Color dotColor = Colors.white;
      Color ringColor = Colors.white;
      double radius = 18;

      if (isActive) {
        dotColor = Colors.yellowAccent;
        radius = 20;
      } else if (isReference) {
        dotColor = Colors.red.shade600;
        ringColor = Colors.red.shade600;
      }

      canvas.drawCircle(p, radius, Paint()..color = ringColor);

      canvas.drawCircle(p, radius - 2, Paint()..color = Colors.black);
      canvas.drawCircle(p, radius - 4, Paint()..color = dotColor);

      final labelStyle = TextStyle(
        color: Colors.black,
        fontSize: isActive ? 16 : 14,
        fontWeight: FontWeight.bold,
      );

      final textSpan = TextSpan(text: loc.label, style: labelStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(canvas, p.translate(-textPainter.width/2, -textPainter.height/2));
    }
  }

  @override
  bool shouldRepaint(covariant ElectrodePainter2D oldDelegate) {
    return oldDelegate.activeLabel != activeLabel || oldDelegate.activeMontage != activeMontage;
  }
}

class BrainDemoPage extends StatefulWidget {
  const BrainDemoPage({super.key});
  @override
  State<BrainDemoPage> createState() => _BrainDemoPageState();
}

class _BrainDemoPageState extends State<BrainDemoPage> {
  Montage _activeMontage = Montage.system;
  String? _activeLabel;

  final Map<Montage, Map<String, Object?>> _montageDescriptions = {
    Montage.system: {
      'title': '10-20 Electrode System',
      'desc': 'This display shows the standard International 10-20 system electrodes, which use fixed anatomical landmarks (nasion, inion, preauricular points) to ensure consistent placement across subjects.',
      'color': Colors.grey,
    },
    Montage.referential: {
      'title': 'Referential (Monopolar) Montage',
      'desc': 'Each active electrode (e.g., Fp1, C3) is referenced to a common, relatively inactive site (e.g., A1/A2 (ears) or Cz). This displays the absolute amplitude at each location, making it excellent for identifying the focus of a discharge (where the peak of the spike is largest).',
      'color': Colors.red,
    },
    Montage.bipolar: {
      'title': 'Bipolar (Derivational) Montage',
      'desc': 'Adjacent electrodes are connected in chains (e.g., Fp1-F7, F7-T3). The EEG trace represents the difference in potential between the two electrodes. This is ideal for determining the spread of activity and localizing a discharge through phase reversal.',
      'color': Colors.blue,
    },
  };

  final Map<String, String> _labelToTopic = const {
    'Fp1': 'Fp1/Fp2', 'Fp2': 'Fp1/Fp2', 'F7': 'Frontal', 'F3': 'Frontal', 'Fz': 'Frontal', 'F4': 'Frontal', 'F8': 'Frontal',
    'C3': 'Central', 'Cz': 'Central', 'C4': 'Central', 'A1': 'Aural', 'A2': 'Aural',
    'T3': 'Temporal', 'T4': 'Temporal', 'T5': 'Parietal/Temporal', 'T6': 'Parietal/Temporal',
    'P3': 'Parietal', 'Pz': 'Parietal', 'P4': 'Parietal',
    'O1': 'Occipital', 'O2': 'Occipital',
  };

  final Map<String, Map<String, String>> _topicMap = const {
    'Fp1/Fp2': {'title': 'Frontopolar', 'desc': 'Executive functions, decision-making.'},
    'Frontal': {'title': 'Frontal Lobe', 'desc': 'Planning, emotion, motor control.'},
    'Central': {'title': 'Central Region', 'desc': 'Motor and somatosensory cortices.'},
    'Temporal': {'title': 'Temporal Lobe', 'desc': 'Auditory processing, memory, language.'},
    'Parietal': {'title': 'Parietal Lobe', 'desc': 'Spatial awareness, integration of senses.'},
    'Parietal/Temporal': {'title': 'Parietal/Temporal', 'desc': 'Overlap region critical for complex language processing, memory recall, and visual-spatial tasks.'},
    'Occipital': {'title': 'Occipital Lobe', 'desc': 'Primary visual processing.'},
    'Aural': {'title': 'Reference Points', 'desc': 'External points (e.g., ear/mastoid) often used as common references for monopolar montages (e.g., A1/A2).'},
  };

  void _handleTapDown(TapDownDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Modified: Use the smaller scaling factors for accurate hit testing
    final double headRadiusX = size.width * 0.30;
    final double headRadiusY = size.height * 0.42;
    // Modified: Calculate a dynamic hit radius that is larger than the dot radius for easy clicking
    final hitRadius = min(size.width, size.height) * 0.04;

    for (final loc in _electrodeLayout) {
      final p = Offset(
        center.dx + loc.x * headRadiusX,
        center.dy + loc.y * headRadiusY,
      );

      if ((details.localPosition - p).distance < hitRadius) {
        final topicKey = _labelToTopic[loc.label];
        if (topicKey != null) {
          _openTopic(topicKey, loc.label);
          setState(() {
            _activeLabel = loc.label;
          });
        }
        return;
      }
    }

    setState(() {
      _activeLabel = null;
    });
  }

  void _openTopic(String topicKey, String electrodeLabel) {
    final topic = _topicMap[topicKey]!;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          color: Colors.black,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Electrode: $electrodeLabel (${topic['title']!})',
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.yellowAccent),
              ),
              const Divider(color: Colors.grey),
              Text(
                topic['desc']!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMontageSelector() {
    return Card(
      color: Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: Montage.values.map((montage) {
            final color = _montageDescriptions[montage]?['color'] as Color? ?? Colors.white;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<Montage>(
                  value: montage,
                  groupValue: _activeMontage,
                  onChanged: (Montage? value) {
                    setState(() {
                      _activeMontage = value!;
                      _activeLabel = null;
                    });
                  },
                  activeColor: color,
                ),
                Text(
                  montage.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: _activeMontage == montage ? color : Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMontageInfoPanel() {
    final info = _montageDescriptions[_activeMontage]!;
    final color = info['color'] as Color? ?? Colors.grey;

    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info['title']! as String,
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Colors.grey),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  info['desc']! as String,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(height: 1.5, color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EEG Montages & Electrode Functions'),
        backgroundColor: Colors.black,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMontageSelector(),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          return GestureDetector(
                            onTapDown: (details) => _handleTapDown(details, size),
                            child: CustomPaint(
                              painter: ElectrodePainter2D(_activeLabel, _activeMontage),
                              size: size,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 10.0),
                    width: double.infinity,
                    child: Text(
                      'tap an electrode to see its function',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(color: Colors.grey),
                    ),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildMontageInfoPanel(),
            ),
          ),
        ],
      ),
    );
  }
}