import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/auth_service.dart';
import '../../profile/providers/profile_provider.dart';

// Servicio de autenticación.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Estado de autenticación.
// Antes de entregar el usuario a la aplicación,
// garantiza que su perfil exista en Firestore.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final profileService = ref.watch(profileServiceProvider);

  return authService.authStateChanges.asyncMap((user) async {
    if (user != null) {
      await profileService.createOrUpdateProfile(user);
    }

    return user;
  });
});
