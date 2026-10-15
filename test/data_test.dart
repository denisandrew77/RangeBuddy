import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:range_buddy/data/bucharest_time.dart';
import 'package:range_buddy/data/fuel_service.dart';
import 'package:range_buddy/data/session_store.dart';
import 'package:range_buddy/data/validation.dart';
import 'package:range_buddy/data/van_profile.dart';

import 'support.dart';

void main() {
  test('request validation: plate syntax, integer mileage and exact decimal bounds', () {
    expect(normalizePlate(' b-123 abc '), 'B-123 ABC');
    expect(plateError('B-123 ABC'), isNull);
    for (final value in ['', 'B  ABC', 'B--ABC', 'B/ABC', 'ĂBC', 'A' * 21]) {
      expect(plateError(value), isNotNull);
    }
    for (final value in ['1.2', '1e3', '-1', '2147483648', 'NaN']) {
      expect(mileageError(value), isNotNull);
    }
    expect(mileageError('0'), isNull);
    expect(mileageError('2147483647'), isNull);
    expect(mileageError('100', lastKms: 100), isNotNull);
    expect(mileageError('101', lastKms: 100), isNull);
    expect(decimalError('9999999,999', maximum: 9999999.999), isNull);
    expect(decimalError('99999.999', maximum: 99999.999), isNull);
    for (final value in [
      '0',
      '-1',
      '1.0001',
      'NaN',
      'Infinity',
      '1e2',
      '100000',
    ]) {
      expect(decimalError(value, maximum: 99999.999), isNotNull, reason: value);
    }
  });
  test(
    'typed models decode num decimals and serialize exact UTC device fields',
    () {
      final entry = FuelEntry.fromJson({...entryJson(), 'van': vanJson()});
      expect(entry.litres, 45.0);
      expect(entry.pricePerLitre, 7.25);
      expect(entry.van!.lastKms, 100000);
      final draft = FuelDraft(
        currentKms: 100500,
        litres: 45.5,
        pricePerLitre: 7.25,
        fuelDate: DateTime.parse('2026-10-15T13:00:00+03:00'),
      );
      expect(draft.toJson(), {
        'current_kms': 100500,
        'litres': 45.5,
        'price_per_litre': 7.25,
        'fuel_date': '2026-10-15T10:00:00.000Z',
      });
      expect(
        () => Van.fromJson({...vanJson(), 'last_kms': 1.5}),
        throwsFormatException,
      );
    },
  );
  test('Bucharest calendar handles UTC month boundaries and DST', () {
    expect(bucharestTime(DateTime.utc(2026, 9, 30, 22)).month, 10);
    expect(bucharestTime(DateTime.utc(2026, 1, 31, 22)).month, 2);
    expect(
      bucharestTime(DateTime.utc(2026, 7, 1)).timeZoneOffset,
      const Duration(hours: 3),
    );
    expect(
      bucharestTime(DateTime.utc(2026, 12, 1)).timeZoneOffset,
      const Duration(hours: 2),
    );
  });
  for (final status in [200, 201]) {
    test(
      'activation $status uses exact body, no auth and exact returned token',
      () async {
        final api = RangeBuddyApi(
          testBase,
          client: MockClient((r) async {
            expect(r.method, 'POST');
            expect(r.url.toString(), '$testBase/activate');
            expect(
              r.headers.keys.map((k) => k.toLowerCase()),
              isNot(contains('authorization')),
            );
            expect(r.headers['content-type'], 'application/json');
            expect(r.followRedirects, isFalse);
            expect(jsonDecode(r.body), {
              'license_plate': 'B123ABC',
              'initial_kms': 0,
              'password': 'entered password',
            });
            return jsonResponse({
              'token': 'exact+opaque/token=',
              'van': vanJson(km: 180000),
            }, status);
          }),
        );
        final result = await api.activate(' b123abc ', 0, 'entered password');
        expect(result.token, 'exact+opaque/token=');
        expect(result.van.lastKms, 180000);
      },
    );
  }
  test('every protected route uses RangeBuddy authorization; no extra request fields', () async {
    final server = TestServer();
    await server.api.getVan(savedSession.withPlate('B 123 ABC'));
    expect(server.requests.last.url.toString(), '$testBase/vans/B%20123%20ABC');
    await server.api.getEntries(savedSession, month: 10, year: 2026);
    expect(server.requests.last.url.queryParameters, {
      'month': '10',
      'year': '2026',
    });
    await server.api.addEntry(
      savedSession,
      FuelDraft(
        currentKms: 100500,
        litres: 45.5,
        pricePerLitre: 7.25,
        fuelDate: DateTime.utc(2026, 10, 15, 10),
      ),
      lastKms: 100000,
    );
    expect(jsonDecode(server.requests.last.body), {
      'current_kms': 100500,
      'litres': 45.5,
      'price_per_litre': 7.25,
      'fuel_date': '2026-10-15T10:00:00.000Z',
    });
    await server.api.changePlate(savedSession, ' b456xyz ', 'entered password');
    expect(jsonDecode(server.requests.last.body), {
      'new_license_plate': 'B456XYZ',
      'password': 'entered password',
    });
    expect(server.requests.last.method, 'PUT');
    for (final r in server.requests) {
      expect(r.headers['authorization'], 'RangeBuddy $testToken');
      expect(r.followRedirects, isFalse);
      if (r.method != 'GET') {
        expect(r.headers['content-type'], 'application/json');
      }
    }
  });
  test('monthly query defaults independently, validates bounds and sorts newest first', () async {
    final server = TestServer()
      ..entries = [
        entryJson(date: '2026-10-01T10:00:00Z'),
        entryJson(date: '2026-10-15T10:00:00Z'),
      ];
    final entries = await server.api.getEntries(savedSession, year: 2026);
    expect(server.requests.last.url.queryParameters, {'year': '2026'});
    expect(entries.first.fuelDate.day, 15);
    await server.api.getEntries(savedSession, month: 2);
    expect(server.requests.last.url.queryParameters, {'month': '2'});
    await server.api.getEntries(savedSession);
    expect(server.requests.last.url.hasQuery, isFalse);
    await expectLater(
      server.api.getEntries(savedSession, month: 13),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      server.api.getEntries(savedSession, year: 1999),
      throwsA(isA<ApiException>()),
    );
    expect(server.requests.length, 3);
  });
  test('secure session round trip stores exact token and plate with no credential fields', () async {
    final secrets = MemorySecrets();
    var cleaned = false;
    final store = SecureSessionStore(
      storage: secrets,
      removeLegacyProfile: () async => cleaned = true,
    );
    await store.save(savedSession);
    expect(
      jsonDecode(secrets.values.values.single).keys,
      unorderedEquals(['token', 'plate', 'baseUrl']),
    );
    final loaded = await store.load();
    expect(loaded!.token, testToken);
    expect(loaded.plate, savedSession.plate);
    expect(cleaned, isTrue);
    await store.clear();
    expect(secrets.values, isEmpty);
  });
  test('secure storage failures and malformed records propagate, never silently activate', () async {
    final secrets = MemorySecrets()..seed();
    secrets.failRead = true;
    await expectLater(secrets.store.load(), throwsStateError);
    secrets.failRead = false;
    secrets.failWrite = true;
    await expectLater(secrets.store.save(savedSession), throwsStateError);
    secrets.failDelete = true;
    await expectLater(secrets.store.clear(), throwsStateError);
    expect(secrets.values, isNotEmpty);
    secrets.values[SecureSessionStore.storageKey] = '{}';
    await expectLater(secrets.store.load(), throwsA(anything));
  });
  test('configuration enforces base path/HTTPS and prevents cross-server token use', () async {
    for (final value in [
      'https://example.test',
      'http://example.test/api/rangebuddy',
      '$testBase?secret=x',
      'https://user:pass@example.test/api/rangebuddy',
    ]) {
      expect(() => RangeBuddyApi(value), throwsA(isA<ApiException>()));
    }
    expect(RangeBuddyApi('$testBase/').baseUrl, testBase);
    expect(
      RangeBuddyApi(
        'http://localhost:3000/api/rangebuddy',
        allowInsecure: true,
      ).baseUrl,
      startsWith('http:'),
    );
    final server = TestServer();
    await expectLater(
      server.api.getVan(
        const DeviceSession(
          token: testToken,
          plate: 'B123ABC',
          baseUrl: 'https://other.test/api/rangebuddy',
        ),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(server.requests, isEmpty);
  });
  for (final status in [400, 401, 404, 409, 429, 500, 503]) {
    test(
      'HTTP $status keeps structured field errors and never retries writes',
      () async {
        var calls = 0;
        final api = RangeBuddyApi(
          testBase,
          client: MockClient((r) async {
            calls++;
            return jsonResponse({
              'error': 'Invalid request',
              'fields': [
                {'field': 'litres', 'message': 'Invalid litres'},
              ],
            }, status);
          }),
        );
        await expectLater(
          api.changePlate(savedSession, 'B456XYZ', 'wrong'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.status, 'status', status)
                .having((e) => e.invalidDeviceToken, 'session retained', false)
                .having(
                  (e) => e.fields['litres'],
                  'field error',
                  'Invalid litres',
                ),
          ),
        );
        expect(calls, 1);
      },
    );
  }
  test('only explicit token 401 errors invalidate; activation password 401 never does', () async {
    for (final body in [
      {'error': 'Invalid device token'},
      {'code': 'invalid_device_token'},
      {'error': 'invalid_device_token'},
    ]) {
      final api = RangeBuddyApi(
        testBase,
        client: MockClient((r) async => jsonResponse(body, 401)),
      );
      await expectLater(
        api.getVan(savedSession),
        throwsA(
          isA<ApiException>().having(
            (e) => e.invalidDeviceToken,
            'invalid',
            true,
          ),
        ),
      );
      await expectLater(
        api.activate('B123ABC', 0, 'wrong'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.invalidDeviceToken,
            'activation',
            false,
          ),
        ),
      );
    }
  });
  test(
    'offline, timeout, malformed response and redirect do not leak or retry',
    () async {
      var calls = 0;
      final api = RangeBuddyApi(
        testBase,
        client: MockClient((r) async {
          calls++;
          throw http.ClientException('sensitive body should never display');
        }),
      );
      await expectLater(
        api.activate('B123ABC', 0, 'entered password'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'safe message',
            isNot(contains('sensitive')),
          ),
        ),
      );
      expect(calls, 1);
      final slow = RangeBuddyApi(
        testBase,
        timeout: const Duration(milliseconds: 1),
        client: MockClient((r) => Completer<http.Response>().future),
      );
      await expectLater(
        slow.getVan(savedSession),
        throwsA(isA<ApiException>()),
      );
      final malformed = RangeBuddyApi(
        testBase,
        client: MockClient((r) async => http.Response('not-json', 200)),
      );
      await expectLater(
        malformed.getVan(savedSession),
        throwsA(isA<ApiException>()),
      );
      final redirect = RangeBuddyApi(
        testBase,
        client: MockClient(
          (r) async => http.Response(
            '',
            302,
            headers: {'location': 'https://other.test'},
          ),
        ),
      );
      await expectLater(
        redirect.getVan(savedSession),
        throwsA(isA<ApiException>().having((e) => e.status, 'redirect', 302)),
      );
    },
  );
}
