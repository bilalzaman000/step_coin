import 'dart:math';

class StepCounter {
  static const double stepThreshold = 10.0;
  double _previousAccMagnitude = 0.0;
  bool _isPositivePeak = false;
  int _steps = 0;

  int get steps => _steps;

  void onAccelerometerEvent(double x, double y, double z) {
    double accMagnitude = sqrt(x * x + y * y + z * z);

    if (_isPositivePeak && accMagnitude < _previousAccMagnitude) {
      _steps++;
    }

    _isPositivePeak = accMagnitude > stepThreshold && accMagnitude > _previousAccMagnitude;
    _previousAccMagnitude = accMagnitude;
  }

  void reset() {
    _steps = 0;
  }
}
