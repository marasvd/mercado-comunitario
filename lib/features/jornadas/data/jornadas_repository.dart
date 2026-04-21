import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/jornada_model.dart';
import '../domain/kit_model.dart';

class JornadasRepository {
  final SupabaseClient _client;

  JornadasRepository(this._client);

  /// Retorna las jornadas ACTIVAS asignadas al beneficiario autenticado.
  ///
  /// La política RLS "jornadas_beneficiario_select" filtra automáticamente:
  ///   - solo jornadas con status = 'ACTIVA'
  ///   - solo jornadas donde el usuario aparece en jornada_beneficiarios
  ///
  /// Para ADMINISTRADOR y ASISTENTE, la política "jornadas_admin_asistente"
  /// permite acceso total; el filtro status = 'ACTIVA' lo aplica esta función.
  Future<List<JornadaModel>> getJornadasActivas() async {
    try {
      final data = await _client
          .from('jornadas')
          .select()
          .eq('status', 'ACTIVA')
          .order('opens_at', ascending: false);

      return (data as List)
          .map((row) => JornadaModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      throw const AppException('Error al cargar las jornadas. Intente de nuevo.');
    }
  }

  /// Retorna los kits disponibles para una jornada.
  /// RLS garantiza que el beneficiario solo accede a kits de jornadas
  /// en las que está asignado y que están ACTIVAS.
  Future<List<KitModel>> getKits(String jornadaId) async {
    try {
      final data = await _client
          .from('kits')
          .select()
          .eq('jornada_id', jornadaId)
          .order('price', ascending: true);

      return (data as List)
          .map((row) => KitModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw AppException(e.message, code: e.code);
    } catch (e) {
      throw const AppException('Error al cargar los kits. Intente de nuevo.');
    }
  }
}
