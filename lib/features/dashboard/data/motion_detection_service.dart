import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class MotionDetectionService {
  // Umbral de aceleración para considerar un movimiento brusco.
  static const double _threshold = 22.0;

  // Tiempo mínimo entre detecciones para evitar alertas repetidas.
  static const Duration _cooldown = Duration(seconds: 5);

  Stream<AccelerometerEvent> detectSuddenMovements() async* {
    DateTime? lastDetection;

    await for (final event in accelerometerEventStream()) {
      final acceleration = sqrt(
        event.x * event.x +
        event.y * event.y +
        event.z * event.z,
      );

      final now = DateTime.now();

      final canDetect = lastDetection == null ||
          now.difference(lastDetection) >= _cooldown;

      if (acceleration >= _threshold && canDetect) {
        lastDetection = now;
        yield event;
      }
    }
  }
}
