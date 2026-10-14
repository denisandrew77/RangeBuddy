import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class FuelEntry {
  const FuelEntry({
    required this.plate,
    required this.odometerKm,
    required this.litres,
    required this.pricePerLitre,
    required this.recordedAt,
  });

  final String plate;
  final double odometerKm;
  final double litres;
  final double pricePerLitre;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() => {
    'licencePlate': plate,
    'odometerKm': odometerKm,
    'fuelLitres': litres,
    'pricePerLitre': pricePerLitre,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };
}

enum SubmissionResult { preview, sent }

abstract interface class FuelService {
  bool get isPreview;
  Future<SubmissionResult> submit(FuelEntry entry);
}

class PreviewFuelService implements FuelService {
  @override
  bool get isPreview => true;

  @override
  Future<SubmissionResult> submit(FuelEntry entry) async =>
      SubmissionResult.preview;
}

class SubmissionException implements Exception {
  const SubmissionException(this.message);
  final String message;
}

class HttpFuelService implements FuelService {
  HttpFuelService(this.endpoint, {http.Client? client})
    : _client = client ?? http.Client();

  final Uri endpoint;
  final http.Client _client;

  @override
  bool get isPreview => false;

  @override
  Future<SubmissionResult> submit(FuelEntry entry) async {
    if (!['http', 'https'].contains(endpoint.scheme) || endpoint.host.isEmpty) {
      throw const SubmissionException('Adresa serverului nu este validă.');
    }
    try {
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(entry.toJson()),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SubmissionException(
          'Serverul nu a acceptat datele (${response.statusCode}). '
          'Datele introduse au fost păstrate.',
        );
      }
      return SubmissionResult.sent;
    } on TimeoutException {
      throw const SubmissionException(
        'Nu s-a primit confirmarea. Verifică serverul înainte de a reîncerca. '
        'Datele introduse au fost păstrate.',
      );
    } on http.ClientException {
      throw const SubmissionException(
        'Trimiterea nu a putut fi confirmată. Verifică conexiunea și serverul '
        'înainte de a reîncerca. Datele introduse au fost păstrate.',
      );
    }
  }
}

FuelService configuredFuelService() {
  const url = String.fromEnvironment('FUEL_API_URL');
  if (url.isEmpty) return PreviewFuelService();
  final endpoint = Uri.tryParse(url);
  return HttpFuelService(endpoint ?? Uri());
}
