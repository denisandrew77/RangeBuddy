import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'session_store.dart';
import 'validation.dart';
import 'van_profile.dart';

const defaultApiBaseUrl =
    'https://emailplatformbackend.onrender.com/api/rangebuddy';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.status,
    this.fields = const {},
    this.invalidDeviceToken = false,
  });
  final String message;
  final int? status;
  final Map<String, String> fields;
  final bool invalidDeviceToken;
  // Deliberately exclude server bodies, credentials and request headers.
  @override
  String toString() => message;
}

class Activation {
  const Activation(this.token, this.van);
  final String token;
  final Van van;
}

class RangeBuddyApi {
  RangeBuddyApi(
    String baseUrl, {
    http.Client? client,
    bool allowInsecure = false,
    this.timeout = const Duration(seconds: 25),
  }) : _client = client ?? http.Client(),
       baseUrl = normalizeBaseUrl(baseUrl, allowInsecure: allowInsecure);
  factory RangeBuddyApi.configured() => RangeBuddyApi(
    const String.fromEnvironment(
      'RANGEBUDDY_API_BASE_URL',
      defaultValue: defaultApiBaseUrl,
    ),
    allowInsecure: kDebugMode,
  );
  final String baseUrl;
  final http.Client _client;
  final Duration timeout;
  void close() => _client.close();

  static String normalizeBaseUrl(String value, {bool allowInsecure = false}) {
    final text = value.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !uri.path.endsWith('/api/rangebuddy') ||
        (uri.scheme != 'https' && !(allowInsecure && uri.scheme == 'http'))) {
      throw const ApiException(
        'Configurează o adresă API HTTPS care se termină în /api/rangebuddy.',
      );
    }
    return uri.toString();
  }

  Future<Activation> activate(
    String plate,
    int initialKms,
    String password,
  ) async {
    if (plateError(plate) != null ||
        mileageError('$initialKms') != null ||
        password.trim().isEmpty) {
      throw const ApiException(
        'Verifică numărul, kilometrajul și parola.',
        status: 400,
      );
    }
    final json = await _request(
      'POST',
      '/activate',
      success: const [200, 201],
      body: {
        'license_plate': normalizePlate(plate),
        'initial_kms': initialKms,
        'password': password,
      },
    );
    return _decode(() {
      final token = json['token'] as String;
      if (token.trim().isEmpty || token.contains(RegExp(r'[\r\n]'))) {
        throw const FormatException();
      }
      return Activation(
        token,
        Van.fromJson(json['van'] as Map<String, dynamic>),
      );
    });
  }

  Future<Van> getVan(DeviceSession session) async {
    final json = await _request(
      'GET',
      '/vans/${Uri.encodeComponent(session.plate)}',
      session: session,
    );
    return _decode(() => Van.fromJson(json as Map<String, dynamic>));
  }

  Future<FuelEntry> addEntry(
    DeviceSession session,
    FuelDraft entry, {
    required int lastKms,
  }) async {
    if (mileageError('${entry.currentKms}', lastKms: lastKms) != null ||
        decimalError('${entry.litres}', maximum: 9999999.999) != null ||
        decimalError('${entry.pricePerLitre}', maximum: 99999.999) != null) {
      throw const ApiException('Verifică valorile alimentării.', status: 400);
    }
    final json = await _request(
      'POST',
      '/entries',
      session: session,
      success: const [201],
      body: entry.toJson(),
    );
    return _decode(() => FuelEntry.fromJson(json as Map<String, dynamic>));
  }

  Future<List<FuelEntry>> getEntries(
    DeviceSession session, {
    int? month,
    int? year,
  }) async {
    if ((month != null && (month < 1 || month > 12)) ||
        (year != null && (year < 2000 || year > 2100))) {
      throw const ApiException(
        'Alege o lună între 1–12 și un an între 2000–2100.',
        status: 400,
      );
    }
    final query = <String, String>{
      if (month != null) 'month': '$month',
      if (year != null) 'year': '$year',
    };
    final json = await _request(
      'GET',
      '/entries',
      session: session,
      query: query,
    );
    return _decode(
      () =>
          (json as List)
              .map((e) => FuelEntry.fromJson(e as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.fuelDate.compareTo(a.fuelDate)),
    );
  }

  Future<Van> changePlate(
    DeviceSession session,
    String plate,
    String password,
  ) async {
    if (plateError(plate) != null || password.trim().isEmpty) {
      throw const ApiException('Verifică numărul și parola.', status: 400);
    }
    final json = await _request(
      'PUT',
      '/vans/license-plate',
      session: session,
      body: {'new_license_plate': normalizePlate(plate), 'password': password},
    );
    return _decode(() => Van.fromJson(json as Map<String, dynamic>));
  }

  T _decode<T>(T Function() parse) {
    try {
      return parse();
    } catch (_) {
      throw const ApiException(
        'Serverul a returnat date neașteptate. Reîmprospătează datele înainte de o nouă trimitere.',
      );
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    DeviceSession? session,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    List<int> success = const [200],
  }) async {
    if (session != null && session.baseUrl != baseUrl) {
      throw const ApiException(
        'Sesiunea aparține altui server. Deconectează-te local pentru a activa acest server.',
      );
    }
    if (session != null &&
        (session.token.trim().isEmpty ||
            session.token.contains(RegExp(r'[\r\n]')))) {
      throw const ApiException(
        'Sesiunea locală nu este validă. Deconectează-te local.',
      );
    }
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
    final request = http.Request(method, uri)..followRedirects = false;
    request.headers['Accept'] = 'application/json';
    if (session != null) {
      request.headers['Authorization'] = 'RangeBuddy ${session.token}';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    http.Response response;
    try {
      response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(timeout);
    } on TimeoutException {
      throw ApiException(
        method == 'GET' ? 'Serverul nu răspunde. Reîncearcă reîmprospătarea.' : 'Confirmarea nu a sosit. Verifică datele de pe server înainte de a retrimite.',
      );
    } catch (_) {
      throw ApiException(
        method == 'GET'
            ? 'Conexiunea nu este disponibilă. Sesiunea a fost păstrată.'
            : 'Trimiterea nu a putut fi confirmată. Verifică conexiunea și datele de pe server înainte de a retrimite.',
      );
    }
    dynamic json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      /* status still determines error handling */
    }
    if (!success.contains(response.statusCode)) {
      final status = response.statusCode;
      final error = json is Map ? json['error'] : null;
      final code = json is Map ? json['code'] : null;
      final explicitInvalid =
          status == 401 &&
          session != null &&
          (code == 'invalid_device_token' ||
              error == 'invalid_device_token' ||
              (error is String &&
                  error.trim().toLowerCase().replaceFirst(RegExp(r'\.$'), '') ==
                      'invalid device token'));
      final fields = <String, String>{};
      if (json is Map && json['fields'] is List) {
        for (final field in json['fields'] as List) {
          if (field is Map &&
              field['field'] is String &&
              field['message'] is String) {
            fields[field['field'] as String] = field['message'] as String;
          }
        }
      }
      throw ApiException(
        switch (status) {
          400 => 'Date invalide. Verifică valorile introduse.',
          401 when explicitInvalid =>
            'Sesiunea dispozitivului nu mai este validă. Activează din nou.',
          401 => 'Autorizarea nu a reușit. Verifică parola de administrator.',
          404 => 'Autoutilitara nu a fost găsită. Sesiunea a fost păstrată.',
          409 => 'Numărul de înmatriculare este deja folosit.',
          429 => 'Prea multe cereri. Activarea și schimbarea numărului permit împreună 5 cereri în 15 minute per IP. Așteaptă înainte de a reîncerca.',
          500 ||
          503 => 'Serverul este temporar indisponibil. Încearcă mai târziu.',
          _ => 'Cererea nu a fost acceptată de server ($status).',
        },
        status: status,
        fields: fields,
        invalidDeviceToken: explicitInvalid,
      );
    }
    if (json == null) {
      throw const ApiException(
        'Răspunsul serverului nu este valid. Verifică datele de pe server înainte de a retrimite.',
      );
    }
    return json;
  }
}
