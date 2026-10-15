class Van {
  const Van({
    required this.id,
    required this.licensePlate,
    required this.activationDate,
    required this.initialKms,
    required this.lastKms,
  });
  final int id;
  final String licensePlate;
  final String activationDate;
  final int initialKms;
  final int lastKms;

  factory Van.fromJson(Map<String, dynamic> json) => Van(
    id: (json['id'] as num).toInt(),
    licensePlate: json['license_plate'] as String,
    activationDate: json['activation_date'] as String,
    initialKms: _integer(json['initial_kms']),
    lastKms: _integer(json['last_kms']),
  );

  static int _integer(dynamic value) {
    if (value is! num ||
        !value.isFinite ||
        value != value.toInt() ||
        value < 0 ||
        value > 2147483647) {
      throw const FormatException('Invalid mileage response');
    }
    return value.toInt();
  }
}

class FuelDraft {
  const FuelDraft({
    required this.currentKms,
    required this.litres,
    required this.pricePerLitre,
    required this.fuelDate,
  });
  final int currentKms;
  final double litres;
  final double pricePerLitre;
  final DateTime fuelDate;
  Map<String, dynamic> toJson() => {
    'current_kms': currentKms,
    'litres': litres,
    'price_per_litre': pricePerLitre,
    'fuel_date': fuelDate.toUtc().toIso8601String(),
  };
}

class FuelEntry extends FuelDraft {
  const FuelEntry({
    required this.id,
    required this.vanId,
    required super.currentKms,
    required super.litres,
    required super.pricePerLitre,
    required super.fuelDate,
    this.van,
  });
  final int id;
  final int vanId;
  final Van? van;
  factory FuelEntry.fromJson(Map<String, dynamic> json) => FuelEntry(
    id: (json['id'] as num).toInt(),
    vanId: (json['van_id'] as num).toInt(),
    currentKms: Van._integer(json['current_kms']),
    litres: (json['litres'] as num).toDouble(),
    pricePerLitre: (json['price_per_litre'] as num).toDouble(),
    fuelDate: DateTime.parse(json['fuel_date'] as String),
    van: json['van'] == null
        ? null
        : Van.fromJson(json['van'] as Map<String, dynamic>),
  );
}
