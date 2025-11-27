import 'package:flutter/material.dart';

const int sampleRate = 256;
const int durationSec = 4;
const int bufferLength = sampleRate * durationSec; // 1024 samples for 4 seconds

const Color primaryColor = Color(0xFF00FFFF);
const Color secondaryColor = Color(0xFFFF00FF);
const Color cardColor = Color(0xFF101018);

const double deltaLow = 0.5;
const double deltaHigh = 4.0;
const double thetaLow = 4.0;
const double thetaHigh = 8.0;
const double alphaLow = 8.0;
const double alphaHigh = 13.0;
const double betaLow = 13.0;
const double betaHigh = 30.0;

const Map<String, Color> bandColors = {
  'Delta': Color(0xFF00BFFF),
  'Theta': Color(0xFF32CD32),
  'Alpha': Color(0xFFFFD700),
  'Beta': Color(0xFFFF0000),
};