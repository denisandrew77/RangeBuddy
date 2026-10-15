String normalizePlate(String plate) => plate.trim().toUpperCase();
String? plateError(String? value) {
  final plate = normalizePlate(value ?? '');
  if (plate.isEmpty) return 'Introdu numărul de înmatriculare';
  if (plate.length > 20) return 'Maximum 20 de caractere';
  if (!RegExp(r'^[A-Z0-9]+(?:[ -][A-Z0-9]+)*$').hasMatch(plate)) {
    return 'Folosește litere, cifre și separatoare simple (spațiu sau -)';
  }
  return null;
}

int? parseMileage(String value) =>
    RegExp(r'^\d+$').hasMatch(value.trim()) ? int.tryParse(value.trim()) : null;
String? mileageError(String? value, {int? lastKms}) {
  final km = parseMileage(value ?? '');
  if (km == null || km < 0 || km > 2147483647) {
    return 'Introdu kilometri întregi între 0 și 2147483647';
  }
  if (lastKms != null && km <= lastKms) {
    return 'Kilometrajul trebuie să fie mai mare decât $lastKms km';
  }
  return null;
}

double? parseDecimal(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));
String? decimalError(String? value, {required double maximum}) {
  final text = (value ?? '').trim().replaceAll(',', '.');
  if (!RegExp(r'^\d+(?:\.\d{1,3})?$').hasMatch(text)) {
    return 'Introdu un număr cu maximum 3 zecimale';
  }
  final number = double.tryParse(text);
  if (number == null || !number.isFinite || number <= 0 || number > maximum) {
    return 'Introdu o valoare mai mare decât 0 și de cel mult ${maximum.toString().replaceAll('.', ',')}';
  }
  return null;
}
