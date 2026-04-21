import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/kit_model.dart';
import '../providers/jornadas_provider.dart';

class JornadaDetalleScreen extends ConsumerWidget {
  final String jornadaId;
  final String jornadaNombre;

  const JornadaDetalleScreen({
    super.key,
    required this.jornadaId,
    required this.jornadaNombre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kitsAsync = ref.watch(kitsProvider(jornadaId));
    final seleccion = ref.watch(kitSeleccionProvider(jornadaId));

    return Scaffold(
      appBar: AppBar(
        title: Text(jornadaNombre),
      ),
      body: kitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is AppException
              ? error.message
              : 'Error al cargar los kits.',
          onRetry: () => ref.invalidate(kitsProvider(jornadaId)),
        ),
        data: (kits) {
          if (kits.isEmpty) {
            return const _SinKitsView();
          }
          return _KitSelectorBody(
            jornadaId: jornadaId,
            kits: kits,
            seleccion: seleccion,
          );
        },
      ),
      bottomNavigationBar: kitsAsync.hasValue && kitsAsync.value!.isNotEmpty
          ? _BottomBar(jornadaId: jornadaId, seleccion: seleccion)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Cuerpo principal — lista de kits + sección complemento
// ---------------------------------------------------------------------------

class _KitSelectorBody extends ConsumerWidget {
  final String jornadaId;
  final List<KitModel> kits;
  final KitSeleccion seleccion;

  const _KitSelectorBody({
    required this.jornadaId,
    required this.kits,
    required this.seleccion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Selecciona tu kit',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.separated(
            itemCount: kits.length,
            separatorBuilder: (context, i) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _KitCard(
              kit: kits[i],
              isSelected: seleccion.kit?.id == kits[i].id,
              onTap: () => ref
                  .read(kitSeleccionProvider(jornadaId).notifier)
                  .seleccionar(kits[i]),
            ),
          ),
        ),
        // Sección de complemento — solo visible si el kit seleccionado lo tiene
        if (seleccion.kit != null && seleccion.kit!.hasComplement)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _ComplementoSection(
                jornadaId: jornadaId,
                seleccion: seleccion,
              ),
            ),
          ),
        // Espacio inferior para que el contenido no quede bajo el botón
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de kit
// ---------------------------------------------------------------------------

class _KitCard extends StatelessWidget {
  final KitModel kit;
  final bool isSelected;
  final VoidCallback onTap;

  const _KitCard({
    required this.kit,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.inputBorder,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.surface,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Indicador de selección
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.inputBorder,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        size: 14, color: AppColors.onPrimary)
                    : null,
              ),
              const SizedBox(width: 14),
              // Nombre y complemento disponible
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kit.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (kit.hasComplement && kit.complementName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Incluye complemento opcional: ${kit.complementName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Precio
              Text(
                '\$${_formatPrice(kit.price)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sección de complemento
// ---------------------------------------------------------------------------

class _ComplementoSection extends ConsumerWidget {
  final String jornadaId;
  final KitSeleccion seleccion;

  const _ComplementoSection({
    required this.jornadaId,
    required this.seleccion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kit = seleccion.kit!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Complemento opcional',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: seleccion.includesComplement
                  ? AppColors.secondary
                  : AppColors.inputBorder,
              width: seleccion.includesComplement ? 2 : 1,
            ),
            color: seleccion.includesComplement
                ? AppColors.secondary.withValues(alpha: 0.06)
                : AppColors.surface,
          ),
          child: SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              kit.complementName ?? 'Complemento',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: kit.complementPrice != null
                ? Text(
                    '+\$${_formatPrice(kit.complementPrice!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                : null,
            value: seleccion.includesComplement,
            activeThumbColor: AppColors.secondary,
            activeTrackColor: AppColors.secondaryLight,
            onChanged: (_) => ref
                .read(kitSeleccionProvider(jornadaId).notifier)
                .toggleComplement(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Barra inferior con total y botón Continuar
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  final String jornadaId;
  final KitSeleccion seleccion;

  const _BottomBar({required this.jornadaId, required this.seleccion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = seleccion.isValid;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (seleccion.kit != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${_formatPrice(seleccion.totalAmount)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enabled
                    ? () {
                        // TODO: navegar a selección de adicionales
                      }
                    : null,
                child: Text(
                  enabled ? 'Continuar' : 'Selecciona un kit para continuar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatPrice(double price) {
  final intPart = price.truncate();
  if (price == intPart) {
    // Sin decimales: 15000 → "15.000"
    return intPart.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => '.',
        );
  }
  // Con decimales: 15000.50 → "15.000,50"
  final parts = price.toStringAsFixed(2).split('.');
  final formatted = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => '.',
  );
  return '$formatted,${parts[1]}';
}

// ---------------------------------------------------------------------------
// Estado vacío — sin kits configurados
// ---------------------------------------------------------------------------

class _SinKitsView extends StatelessWidget {
  const _SinKitsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Esta jornada aún no tiene kits configurados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado de error
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
