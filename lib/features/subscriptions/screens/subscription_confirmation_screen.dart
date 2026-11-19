import 'package:flutter/material.dart';

import '../data/subscription_service.dart';

class SubscriptionConfirmationScreen extends StatefulWidget {
  final String planId;
  final String planName;
  final int price;

  const SubscriptionConfirmationScreen({
    super.key,
    required this.planId,
    required this.planName,
    required this.price,
  });

  @override
  State<SubscriptionConfirmationScreen> createState() =>
      _SubscriptionConfirmationScreenState();
}

class _SubscriptionConfirmationScreenState
    extends State<SubscriptionConfirmationScreen> {
  final SubscriptionService _subscriptionService =
      SubscriptionService();

  bool _isLoading = false;

  Future<void> _confirmarSuscripcion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptionId =
          await _subscriptionService.crearSuscripcion(
        planId: widget.planId,
        planName: widget.planName,
        price: widget.price,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 52,
            ),
            title: const Text('¡Suscripción activada!'),
            content: Text(
              'Tu plan ${widget.planName} se ha registrado '
              'correctamente en SafeZone.\n\n'
              'Identificador: $subscriptionId\n\n'
              'Esta operación fue simulada con fines académicos.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Finalizar'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar la suscripción: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirmar suscripción',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 55,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '¡Ya casi terminamos!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confirma los detalles de tu plan para '
                    'activar tu suscripción.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Resumen de la suscripción',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.planName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Precio'),
                      Text(
                        widget.price == 0
                            ? 'Gratis'
                            : '\$${widget.price} MXN',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Periodicidad'),
                      Text(
                        widget.price == 0 ? 'Sin costo' : 'Mensual',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total simulado',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.price == 0
                            ? 'Gratis'
                            : '\$${widget.price} MXN',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Esta confirmación es una simulación '
                      'académica. No se realizará ningún cargo '
                      'real ni se solicitarán datos bancarios.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _isLoading ? null : _confirmarSuscripcion,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isLoading
                      ? 'Registrando...'
                      : 'Confirmar suscripción',
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pop(context),
                child: const Text('Volver al carrito'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
