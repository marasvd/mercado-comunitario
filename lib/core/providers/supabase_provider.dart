import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provee el [SupabaseClient] como provider global.
/// Requiere que [Supabase.initialize()] haya sido llamado en [main()] antes
/// de que cualquier widget lea este provider.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
