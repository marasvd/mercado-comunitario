import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/jornadas_repository.dart';
import '../../domain/jornada_model.dart';
import '../../domain/kit_model.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final jornadasRepositoryProvider = Provider<JornadasRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return JornadasRepository(client);
});

// ---------------------------------------------------------------------------
// Jornadas activas — AsyncNotifier para permitir refresh manual
// ---------------------------------------------------------------------------

class JornadasActivasNotifier extends AsyncNotifier<List<JornadaModel>> {
  @override
  Future<List<JornadaModel>> build() async {
    return ref.read(jornadasRepositoryProvider).getJornadasActivas();
  }

  /// Recarga la lista desde Supabase.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(jornadasRepositoryProvider).getJornadasActivas(),
    );
  }
}

final jornadasActivasProvider =
    AsyncNotifierProvider<JornadasActivasNotifier, List<JornadaModel>>(
  JornadasActivasNotifier.new,
);

// ---------------------------------------------------------------------------
// Kits por jornada — FutureProvider.family
// ---------------------------------------------------------------------------

final kitsProvider =
    FutureProvider.family<List<KitModel>, String>((ref, jornadaId) {
  return ref.read(jornadasRepositoryProvider).getKits(jornadaId);
});

// ---------------------------------------------------------------------------
// Estado de selección de kit — por jornada
// ---------------------------------------------------------------------------

@immutable
class KitSeleccion {
  final KitModel? kit;
  final bool includesComplement;

  const KitSeleccion({this.kit, this.includesComplement = false});

  bool get isValid => kit != null;

  KitSeleccion copyWith({KitModel? kit, bool? includesComplement}) {
    return KitSeleccion(
      kit: kit ?? this.kit,
      includesComplement: includesComplement ?? this.includesComplement,
    );
  }

  /// Precio total según la selección actual.
  double get totalAmount {
    if (kit == null) return 0;
    if (includesComplement && kit!.hasComplement) {
      return kit!.totalWithComplement;
    }
    return kit!.price;
  }
}

class KitSeleccionNotifier extends StateNotifier<KitSeleccion> {
  KitSeleccionNotifier() : super(const KitSeleccion());

  void seleccionar(KitModel kit) {
    // Al cambiar de kit, el complemento se resetea
    state = KitSeleccion(kit: kit, includesComplement: false);
  }

  void toggleComplement() {
    if (state.kit == null || !state.kit!.hasComplement) return;
    state = state.copyWith(includesComplement: !state.includesComplement);
  }

  void limpiar() {
    state = const KitSeleccion();
  }
}

/// Scoped por jornadaId para que cada jornada tenga selección independiente.
final kitSeleccionProvider = StateNotifierProvider.family<KitSeleccionNotifier,
    KitSeleccion, String>(
  (ref, jornadaId) => KitSeleccionNotifier(),
);
