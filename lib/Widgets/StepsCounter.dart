import 'dart:math';

class StepCounter {
  static const double stepThreshold = 13.0;
  static const int minTimeBetweenSteps = 250;

  double _previousAccMagnitude = 0.0;
  bool _isPositivePeak = false;
  int _steps = 0;
  int _lastStepTime = 0;
  int get steps => _steps;
  void onAccelerometerEvent(double x, double y, double z) {
    double accMagnitude = sqrt(x * x + y * y + z * z);
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    if (accMagnitude > stepThreshold) {
      if (!_isPositivePeak) {
        // If it's a positive peak and there's been enough time since the last step
        if ((currentTime - _lastStepTime) > minTimeBetweenSteps) {
          _steps++;
          _lastStepTime = currentTime;
        }
      }
      _isPositivePeak = true;
    } else {
      _isPositivePeak = false;
    }

    _previousAccMagnitude = accMagnitude;
  }

  void reset() {
    _steps = 0;
    _lastStepTime = 0;
  }
}
