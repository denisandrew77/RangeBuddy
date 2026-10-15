import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:range_buddy/data/fuel_service.dart';
import 'package:range_buddy/data/session_store.dart';

const testBase = 'https://example.test/api/rangebuddy';
const testToken = 'opaque.test-device-token';
const savedSession = DeviceSession(
  token: testToken,
  plate: 'B123ABC',
  baseUrl: testBase,
);
Map<String, dynamic> vanJson({String plate = 'B123ABC', int km = 100000}) => {
  'id': 1,
  'license_plate': plate,
  'activation_date': '2026-10-15',
  'initial_kms': 100000,
  'last_kms': km,
};
Map<String, dynamic> entryJson({
  int km = 100500,
  int litres = 45,
  String date = '2026-10-15T10:00:00Z',
}) => {
  'id': 1,
  'van_id': 1,
  'current_kms': km,
  'litres': litres,
  'price_per_litre': 7.25,
  'fuel_date': date,
};
http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

class MemorySecrets implements SecretStorage {
  final values = <String, String>{};
  bool failRead = false, failWrite = false, failDelete = false;
  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('read');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (failWrite) throw StateError('write');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (failDelete) throw StateError('delete');
    values.remove(key);
  }

  SecureSessionStore get store =>
      SecureSessionStore(storage: this, removeLegacyProfile: () async {});
  void seed([DeviceSession session = savedSession]) =>
      values[SecureSessionStore.storageKey] = jsonEncode(session.toJson());
}

class TestServer {
  TestServer() {
    api = RangeBuddyApi(testBase, client: MockClient(handle));
  }
  late final RangeBuddyApi api;
  final requests = <http.Request>[];
  String plate = 'B123ABC';
  int km = 100000;
  List<Map<String, dynamic>> entries = [];
  Future<http.Response?> Function(http.Request)? intercept;
  Future<http.Response> handle(http.Request request) async {
    requests.add(request);
    final response = await intercept?.call(request);
    if (response != null) return response;
    final path = request.url.path;
    if (path.endsWith('/activate')) {
      return jsonResponse({
        'token': testToken,
        'van': vanJson(plate: plate, km: km),
      }, 201);
    }
    if (path.endsWith('/vans/license-plate')) {
      plate = (jsonDecode(request.body) as Map)['new_license_plate'] as String;
      return jsonResponse(vanJson(plate: plate, km: km));
    }
    if (path.contains('/vans/')) {
      return jsonResponse(vanJson(plate: plate, km: km));
    }
    if (request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      km = body['current_kms'] as int;
      final entry = {...body, 'id': 1, 'van_id': 1};
      entries = [
        {...entry, 'van': vanJson(plate: plate, km: km)},
      ];
      return jsonResponse(entry, 201);
    }
    return jsonResponse(entries);
  }

  int count(String method) => requests.where((r) => r.method == method).length;
}
