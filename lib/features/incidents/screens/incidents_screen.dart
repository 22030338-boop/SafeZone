import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/incident_provider.dart';

class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incidentes reportados'),
      ),
      body: incidentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudieron cargar los incidentes.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (snapshot) {
          final incidents = snapshot.docs;

          if (incidents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.report_gmailerrorred_outlined,
                    size: 65,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No hay incidentes registrados.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(incidentsStreamProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final incident = incidents[index].data();

                return _IncidentCard(incident: incident);
              },
            ),
          );
        },
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;

  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    final photoUrl = incident['photoUrl'] as String?;
    final title = incident['title'] ?? 'Sin título';
    final category = incident['category'] ?? 'Sin categoría';
    final description = incident['description'] ?? '';
    final status = incident['status'] ?? 'pending';

    final timestamp = incident['createdAt'] as Timestamp?;
    final date = timestamp?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photoUrl != null && photoUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: photoUrl,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => const SizedBox(
                height: 190,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => const SizedBox(
                height: 120,
                child: Center(
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium,
                      ),
                    ),
                    _StatusChip(status: status),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  category,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                Text(description),

                const SizedBox(height: 14),

                if (date != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${date.day}/${date.month}/${date.year} '
                        '${date.hour.toString().padLeft(2, '0')}:'
                        '${date.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        incident['userName'] ?? 'Usuario SafeZone',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isResolved = status == 'resolved';

    return Chip(
      avatar: Icon(
        isResolved ? Icons.check_circle : Icons.pending,
        size: 16,
        color: isResolved ? Colors.green : Colors.orange,
      ),
      label: Text(
        isResolved ? 'Resuelto' : 'Pendiente',
        style: const TextStyle(fontSize: 11),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
