import 'package:flutter/material.dart';
import 'cart_screen.dart';
import '../../subscriptions/screens/my_subscriptions_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int selectedPlan = 0;

  final List<_SubscriptionPlan> plans = [
    _SubscriptionPlan(
      id: 'free',
      name: 'Gratuito',
      description: 'Protección esencial para comenzar.',
      price: 0,
      icon: Icons.shield_outlined,
      color: const Color(0xFF64748B),
      features: [
        'Acceso al mapa de seguridad',
        'Consulta de incidentes',
        'Reporte de incidentes',
        'Alertas generales',
      ],
    ),
    _SubscriptionPlan(
      id: 'plus',
      name: 'Protección Plus',
      description: 'Mayor protección para tu día a día.',
      price: 49,
      icon: Icons.shield,
      color: const Color(0xFF2878D0),
      features: [
        'Todos los beneficios gratuitos',
        'Alertas prioritarias',
        'Notificaciones adicionales',
        'Funciones adicionales de protección',
      ],
    ),
    _SubscriptionPlan(
      id: 'premium',
      name: 'Protección Premium',
      description: 'La experiencia más completa de SafeZone.',
      price: 99,
      icon: Icons.workspace_premium,
      color: const Color(0xFFD69B25),
      features: [
        'Todos los beneficios Plus',
        'Gestión de contactos de emergencia',
        'Beneficios completos de protección',
        'Acceso a funciones Premium',
      ],
      recommended: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Planes de protección',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_moon_outlined,
                    size: 34,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Tu seguridad, a tu manera',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Conoce nuestros planes y encuentra la '
                    'protección que mejor se adapta a tus necesidades.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MySubscriptionsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Mis suscripciones'),
            ),

            const SizedBox(height: 28),

            Text(
              'Elige tu plan',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Selecciona un plan para conocer sus beneficios.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            ...List.generate(
              plans.length,
              (index) => _buildPlanCard(
                context,
                plans[index],
                index,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final plan = plans[selectedPlan];

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartScreen(
                        planId: plan.id,
                        planName: plan.name,
                        description: plan.description,
                        price: plan.price,
                        icon: plan.icon,
                        color: plan.color,
                        features: plan.features,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Continuar con el plan'),
              ),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Los pagos de esta aplicación son simulados '
                      'con fines académicos. No se realizarán cargos '
                      'reales ni se solicitarán datos bancarios.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    _SubscriptionPlan plan,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = selectedPlan == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? plan.color
              : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            selectedPlan = index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: plan.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      plan.icon,
                      color: plan.color,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          plan.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (plan.recommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: plan.color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'POPULAR',
                        style: TextStyle(
                          color: plan.color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.price == 0
                        ? 'Gratis'
                        : '\$${plan.price}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: plan.color,
                    ),
                  ),

                  if (plan.price > 0)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 5,
                        bottom: 5,
                      ),
                      child: Text(
                        'MXN / mes',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              Divider(color: colorScheme.outlineVariant),

              const SizedBox(height: 10),

              Text(
                'Beneficios incluidos',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...plan.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: plan.color,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          feature,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: isSelected
                    ? FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Plan seleccionado'),
                        style: FilledButton.styleFrom(
                          backgroundColor: plan.color,
                          foregroundColor: Colors.white,
                        ),
                      )
                    : OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedPlan = index;
                          });
                        },
                        child: const Text('Seleccionar plan'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final int price;
  final IconData icon;
  final Color color;
  final List<String> features;
  final bool recommended;

  const _SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.color,
    required this.features,
    this.recommended = false,
  });
}
