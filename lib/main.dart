import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

import 'features/authentication/providers/auth_provider.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/email_verification_screen.dart';

import 'features/profile/screens/profile_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

import 'features/notifications/data/notification_service.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'core/router/app_navigator.dart';

// Manejador de notificaciones recibidas en segundo plano.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Notificación recibida en segundo plano: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('1. Inicializando Firebase...');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('2. Firebase inicializado correctamente.');

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  debugPrint('3. Creando servicio de notificaciones...');

  final notificationService = NotificationService();

  try {
    debugPrint('4. Inicializando FCM...');

    await notificationService.initialize();

    debugPrint('5. FCM inicializado correctamente.');
  } catch (error, stackTrace) {
    debugPrint('ERROR AL INICIALIZAR FCM: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  debugPrint('6. Iniciando aplicación SafeZone...');

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(
          notificationService,
        ),
      ],
      child: const SafeZoneApp(),
    ),
  );
}


class SafeZoneApp extends ConsumerStatefulWidget {
  const SafeZoneApp({super.key});

  @override
  ConsumerState<SafeZoneApp> createState() => _SafeZoneAppState();
}

class _SafeZoneAppState extends ConsumerState<SafeZoneApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).handleInitialMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SafeZone',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const AuthGate(),
    );
  }
}


// Controla qué pantalla debe mostrarse según la sesión del usuario.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (User? user) {
        if (user == null) {
          return const LoginScreen();
        }

        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        return const DashboardScreen();
      },
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error de autenticación:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Pantalla principal temporal de SafeZone.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeZone'),
        actions: [
          IconButton(
            tooltip: isDark
                ? 'Activar tema claro'
                : 'Activar tema oscuro',
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
            },
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'SafeZone - Seguridad comunitaria',
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
