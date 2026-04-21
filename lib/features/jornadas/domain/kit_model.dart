import 'package:flutter/foundation.dart';

/// Representa un kit disponible en una jornada.
/// Tipo Dart puro — sin dependencias externas.
@immutable
class KitModel {
  final String id;
  final String jornadaId;
  final String name;
  final double price;
  final bool hasComplement;
  final String? complementName;
  final double? complementPrice;

  const KitModel({
    required this.id,
    required this.jornadaId,
    required this.name,
    required this.price,
    required this.hasComplement,
    this.complementName,
    this.complementPrice,
  });

  factory KitModel.fromJson(Map<String, dynamic> json) {
    return KitModel(
      id: json['id'] as String,
      jornadaId: json['jornada_id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      hasComplement: json['has_complement'] as bool,
      complementName: json['complement_name'] as String?,
      complementPrice: json['complement_price'] != null
          ? (json['complement_price'] as num).toDouble()
          : null,
    );
  }

  /// Precio total si incluye complemento.
  double get totalWithComplement => price + (complementPrice ?? 0);
}
