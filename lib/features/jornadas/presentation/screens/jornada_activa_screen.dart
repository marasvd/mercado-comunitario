import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/jornada_model.dart';
import '../providers/jornadas_provider.dart';

class JornadaActivaScreen extends ConsumerWidget {
  const JornadaActivaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasAsync = ref.watch(jornadasActivasProvider);
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Jornada'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
          ),
        ],
      ),
      body: jornadasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          message: error is AppException
              ? error.message
              : 'Error al cargar las jornadas.',
          onRetry: () =>
              ref.read(jornadasActivasProvider.notifier).refresh(),
        ),
        data: (jornadas) {
          if (jornadas.isEmpty) {
            return _EmptyView(userName: user?.fullName);
          }
          return _JornadasListRefreshable(jornadas: jornadas);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de jornadas con pull-to-refresh
// ---------------------------------------------------------------------------

class _JornadasListRefreshable extends ConsumerWidget {
  final List<JornadaModel> jornadas;
  const _JornadasListRefreshable({required this.jornadas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(jornadasActivasProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: jornadas.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _JornadaCard(jornada: jornadas[i]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tarjeta de jornada
// ---------------------------------------------------------------------------

class _JornadaCard extends StatelessWidget {
  final JornadaModel jornada;
  const _JornadaCard({required this.jornada});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'es');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    jornada.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(status: jornada.status),
              ],
            ),
            if (jornada.opensAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(jornada.opensAt!.toLocal()),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go(
                  '/beneficiario/jornada/${jornada.id}'
                  '?nombre=${Uri.encodeComponent(jornada.name)}',
                ),
                child: const Text('Ver jornada'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip de estado
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final JornadaStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      JornadaStatus.activa => Colors.green,
      JornadaStatus.borrador => Colors.orange,
      JornadaStatus.cerrada => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado vacío
// ---------------------------------------------------------------------------

class _EmptyView extends StatelessWidget {
  final String? userName;
  const _EmptyView({this.userName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.store_mall_directory_outlined,
                size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              userName != null ? 'Hola, $userName' : 'Hola',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'No tienes jornadas activas asignadas por el momento.',
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
