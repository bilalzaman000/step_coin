import 'dart:math';

class StepCounter {
  static const double stepThreshold = 14.5;
  static const int minTimeBetweenSteps = 250;

  double _previousAccMagnitude = 0.0;
  bool _isPositivePeak = false;
  int _steps = 0;
  int _lastStepTime = 0;

  int get steps => _steps;
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;

  StepCounter([this._steps = 0]);

  void onAccelerometerEvent(double x, double y, double z) {
    this.x = x;
    this.y = y;
    this.z = z;

    double accMagnitude = sqrt(x * x + y * y + z * z);
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    if (accMagnitude > stepThreshold) {
      if (!_isPositivePeak) {
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

  void resetSteps() {
    _steps = 0;
    _lastStepTime = 0;
  }

  void setSteps(int steps) {
    _steps = steps;
  }
}
