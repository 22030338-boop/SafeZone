import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/emergency_service.dart';

final emergencyServiceProvider = Provider<EmergencyService>((ref) {
  return EmergencyService();
});
