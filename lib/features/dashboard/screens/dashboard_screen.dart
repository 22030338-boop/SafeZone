import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../../incidents/screens/create_incident_screen.dart';
import '../../incidents/screens/incidents_screen.dart';
import '../providers/emergency_provider.dart';
import '../providers/motion_provider.dart';
import '../../map/screens/map_screen.dart';
import '../../store/screens/store_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _confirmEmergency(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.sos,
          color: Colors.red,
          size: 40,
        ),
        title: const Text('¿Enviar alerta SOS?'),
        content: const Text(
          'Se registrará una alerta de emergencia '
          'junto con tu ubicación GPS actual. '
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enviar alerta'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text('Registrando emergencia...'),
            ),
          ],
        ),
      ),
    );

    try {
      final alertId = await ref
          .read(emergencyServiceProvider)
          .sendEmergencyAlert();

      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alerta registrada correctamente: $alertId'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar la alerta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = ref.watch(themeProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('No hay una sesión activa.'),
        ),
      );
    }

    // Escuchar movimientos bruscos del dispositivo.
    ref.listen(suddenMovementProvider, (previous, next) {
      next.whenData((_) {
        // Evitar mostrar avisos si otra pantalla o diálogo está abierto.
        if (!context.mounted ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }

        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 42,
            ),
            title: const Text('¿Estás bien?'),
            content: const Text(
              'SafeZone detectó un movimiento brusco en tu dispositivo. '
              'Si sufriste una caída o necesitas ayuda, puedes enviar '
              'una alerta SOS.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Estoy bien'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _confirmEmergency(context, ref);
                },
                child: const Text('Necesito ayuda'),
              ),
            ],
          ),
        );
      });
    });

    final profileAsync = ref.watch(profileDataProvider(user.uid));

    final displayName = profileAsync.maybeWhen(
      data: (profile) =>
          profile?['name'] as String? ??
          user.displayName ??
          'Usuario SafeZone',
      orElse: () => user.displayName ?? 'Usuario SafeZone',
    );

    final photoUrl = profileAsync.maybeWhen(
      data: (profile) => profile?['photoUrl'] as String?,
      orElse: () => user.photoURL,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_outlined),
            SizedBox(width: 8),
            Text(
              'SafeZone',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Tema claro' : 'Tema oscuro',
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).logout();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de bienvenida.
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundImage:
                        photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                    child: photoUrl == null || photoUrl.isEmpty
                        ? const Icon(Icons.person, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, bienvenido/a',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Centro de seguridad.
              Text(
                'Centro de seguridad',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                'Accede rápidamente a las herramientas de protección.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 16),

              // Tarjeta principal SOS.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 30,
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '¿Necesitas ayuda?',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Envía una alerta SOS con tu ubicación actual.',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer,
                      ),
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _confirmEmergency(context, ref);
                        },
                        icon: const Icon(Icons.sos),
                        label: const Text(
                          'ENVIAR ALERTA SOS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Herramientas comunitarias.
              Text(
                'Herramientas comunitarias',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                'Mantente informado y participa en la seguridad '
                'de tu comunidad.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 18),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  _DashboardActionCard(
                    icon: Icons.add_alert_outlined,
                    title: 'Reportar incidente',
                    description: 'Informa sobre una situación de riesgo.',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateIncidentScreen(),
                        ),
                      );
                    },
                  ),

                  _DashboardActionCard(
                    icon: Icons.list_alt,
                    title: 'Incidentes reportados',
                    description: 'Consulta los reportes de la comunidad.',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IncidentsScreen(),
                        ),
                      );
                    },
                  ),

                  _DashboardActionCard(
                    icon: Icons.map_outlined,
                    title: 'Mapa de seguridad',
                    description: 'Explora las zonas de tu comunidad.',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    },
                    comingSoon: false,
                  ),

                  _DashboardActionCard(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Planes de protección',
                    description: 'Conoce nuestros planes y beneficios.',
                    color: Colors.amber,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreScreen(),
                        ),
                      );
                    },
                  ),

                ],
              ),

              const SizedBox(height: 28),

              Center(
                child: Text(
                  'SafeZone · Seguridad comunitaria',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback? onTap;
  final bool comingSoon;

  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.onTap,
    this.comingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const Spacer(),

              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 5),

              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),

              if (comingSoon) ...[
                const SizedBox(height: 6),
                Text(
                  'Próximamente',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
