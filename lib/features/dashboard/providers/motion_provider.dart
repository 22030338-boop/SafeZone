import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/motion_detection_service.dart';

final motionDetectionServiceProvider =
    Provider<MotionDetectionService>((ref) {
  return MotionDetectionService();
});

final suddenMovementProvider =
    StreamProvider<AccelerometerEvent>((ref) {
  return ref
      .watch(motionDetectionServiceProvider)
      .detectSuddenMovements();
});
