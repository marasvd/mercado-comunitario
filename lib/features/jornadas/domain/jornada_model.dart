/// Representación de una jornada de mercado.
/// Solo contiene tipos Dart puros — sin dependencias externas.
class JornadaModel {
  final String id;
  final String orgId;
  final String name;
  final JornadaStatus status;
  final DateTime? opensAt;
  final DateTime? closesAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JornadaModel({
    required this.id,
    required this.orgId,
    required this.name,
    required this.status,
    this.opensAt,
    this.closesAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JornadaModel.fromJson(Map<String, dynamic> json) {
    return JornadaModel(
      id: json['id'] as String,
      orgId: json['org_id'] as String,
      name: json['name'] as String,
      status: JornadaStatus.fromString(json['status'] as String),
      opensAt: json['opens_at'] != null
          ? DateTime.parse(json['opens_at'] as String)
          : null,
      closesAt: json['closes_at'] != null
          ? DateTime.parse(json['closes_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

enum JornadaStatus {
  borrador,
  activa,
  cerrada;

  factory JornadaStatus.fromString(String value) {
    return switch (value) {
      'BORRADOR' => JornadaStatus.borrador,
      'ACTIVA' => JornadaStatus.activa,
      'CERRADA' => JornadaStatus.cerrada,
      _ => throw ArgumentError('Estado de jornada desconocido: $value'),
    };
  }

  String get label => switch (this) {
        JornadaStatus.borrador => 'Borrador',
        JornadaStatus.activa => 'Activa',
        JornadaStatus.cerrada => 'Cerrada',
      };
}
