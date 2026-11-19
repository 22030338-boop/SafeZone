import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileDataProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, uid) {
  return ref.watch(profileServiceProvider).getProfile(uid);
});
