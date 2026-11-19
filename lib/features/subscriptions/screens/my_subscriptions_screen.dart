import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/subscription_service.dart';

class MySubscriptionsScreen extends StatelessWidget {
  const MySubscriptionsScreen({super.key});

  String _formatearFecha(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;

      return '$day/$month/$year';
    }

    return 'Fecha pendiente';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final service = SubscriptionService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis suscripciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: service.obtenerSuscripcionesUsuario(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('No se pudieron cargar tus suscripciones.'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final subscriptions = snapshot.data?.docs.toList() ?? [];

            subscriptions.sort((a, b) {
              final dateA = a.data()['createdAt'];
              final dateB = b.data()['createdAt'];

              final timeA = dateA is Timestamp
                  ? dateA.millisecondsSinceEpoch
                  : 0;

              final timeB = dateB is Timestamp
                  ? dateB.millisecondsSinceEpoch
                  : 0;

              return timeB.compareTo(timeA);
            });

            if (subscriptions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_membership_outlined,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aún no tienes suscripciones',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cuando selecciones un plan, aparecerá '
                        'aquí su información.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final activeSubscriptions = subscriptions.where(
              (doc) => doc.data()['status'] == 'active',
            ).toList();

            final activeSubscription = activeSubscriptions.isNotEmpty
                ? activeSubscriptions.first
                : null;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (activeSubscription != null) ...[
                  Text(
                    'Plan actual',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSubscriptionCard(
                    context,
                    activeSubscription.data(),
                    isActive: true,
                  ),
                  const SizedBox(height: 28),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No tienes un plan activo actualmente.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  'Historial de suscripciones',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                ...subscriptions.map((doc) {
                  final data = doc.data();

                  return _buildSubscriptionCard(
                    context,
                    data,
                    isActive: data['status'] == 'active',
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    Map<String, dynamic> data, {
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final planName = data['planName'] as String? ?? 'Plan desconocido';
    final price = (data['price'] as num?)?.toInt() ?? 0;
    final status = data['status'] as String? ?? 'unknown';
    final paymentStatus =
        data['paymentStatus'] as String? ?? 'unknown';

    final statusText = status == 'active'
    ? 'Activa'
    : status == 'replaced'
        ? 'Reemplazada'
        : status == 'cancelled'
            ? 'Cancelada'
            : status;

    final statusColor = status == 'active'
        ? Colors.green
        : colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  planName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            price == 0 ? 'Gratis' : '\$$price MXN / mes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fecha de registro'),
              Text(_formatearFecha(data['createdAt'])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tipo de operación'),
              Text(
                paymentStatus == 'simulated'
                    ? 'Pago simulado'
                    : paymentStatus == 'not_required'
                        ? 'Sin costo'
                        : paymentStatus,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
