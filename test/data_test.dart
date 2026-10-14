import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:range_buddy/data/fuel_service.dart';
import 'package:range_buddy/data/van_profile.dart';
import 'package:range_buddy/ui/components.dart';

void main() {
  test('legacy profiles use baseline and current odometer survives serialization and settings edits', () {
    final legacy = {
      'plate': 'B 123 ABC',
      'startingKm': 100,
      'passwordSalt': base64Encode(List.filled(16, 1)),
      'passwordHash': base64Encode(List.filled(32, 2)),
    };
    final profile = VanProfile.fromJson(legacy);
    expect(profile.currentKm, 100);
    final updated = profile.copyWith(lastOdometerKm: 150);
    final restored = VanProfile.fromJson(
      jsonDecode(jsonEncode(updated.toJson())) as Map<String, dynamic>,
    );
    expect(restored.currentKm, 150);
    expect(
      restored.copyWith(startingKm: 110, plate: 'CJ 99 VAN').currentKm,
      150,
    );
    expect(
      () => VanProfile.fromJson({...legacy, 'lastOdometerKm': -1}),
      throwsFormatException,
    );
  });

  test('password verifier is salted, persisted, and verifies only the correct password', () async {
    final passwords = AdminPasswords();
    final first = await passwords.create(' b 123 abc ', 0, 'secret');
    final second = await passwords.create('B 123 ABC', 0, 'secret');
    expect(first.passwordHash, isNot(second.passwordHash));
    expect(first.passwordSalt, isNot(second.passwordSalt));
    expect(jsonEncode(first.toJson()), isNot(contains('secret')));
    final restored = VanProfile.fromJson(
      jsonDecode(jsonEncode(first.toJson())) as Map<String, dynamic>,
    );
    expect(restored.plate, 'B 123 ABC');
    expect(await passwords.verify(restored, 'secret'), isTrue);
    expect(await passwords.verify(restored, 'wrong'), isFalse);
  });

  test('numeric validation supports commas and rejects invalid or nonfinite values', () {
    expect(parseNumber('42,50'), 42.5);
    for (final value in [
      '',
      'abc',
      'NaN',
      'Infinity',
      '1e999',
      '1,2,3',
      '-1',
    ]) {
      expect(numericError(value), isNotNull, reason: value);
    }
    expect(numericError('0'), isNotNull);
    expect(numericError('0', allowZero: true), isNull);
    expect(numericError('99', allowZero: true, minimum: 100), isNotNull);
    expect(numericError('100', allowZero: true, minimum: 100), isNull);
  });

  const plate = 'B 123 ABC';
  final entry = FuelEntry(
    plate: plate,
    odometerKm: 12345,
    litres: 42.5,
    pricePerLitre: 7.25,
    recordedAt: DateTime.utc(2026, 10, 14),
  );

  test('preview explicitly returns no-send result', () async {
    expect(await PreviewFuelService().submit(entry), SubmissionResult.preview);
  });

  test('HTTP adapter posts numeric fuel data without credentials', () async {
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      expect(request.method, 'POST');
      expect(request.headers['content-type'], 'application/json');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['licencePlate'], plate);
      expect(body['odometerKm'], 12345);
      expect(body['fuelLitres'], 42.5);
      expect(body['pricePerLitre'], 7.25);
      expect(body['recordedAt'], '2026-10-14T00:00:00.000Z');
      expect(body.keys, isNot(contains('password')));
      expect(body.keys, isNot(contains('totalPaid')));
      return http.Response('', 201);
    });
    expect(
      await HttpFuelService(
        Uri.parse('https://example.test/fuel'),
        client: client,
      ).submit(entry),
      SubmissionResult.sent,
    );
    expect(requests, 1);
  });

  test('HTTP failure does not become a success', () async {
    final service = HttpFuelService(
      Uri.parse('https://example.test/fuel'),
      client: MockClient((_) async => http.Response('', 500)),
    );
    await expectLater(
      service.submit(entry),
      throwsA(isA<SubmissionException>()),
    );
  });

  test('invalid endpoint is rejected without making a request', () async {
    final service = HttpFuelService(
      Uri.parse('file:///tmp/fuel'),
      client: MockClient((_) async => throw StateError('Must not be called')),
    );
    await expectLater(
      service.submit(entry),
      throwsA(isA<SubmissionException>()),
    );
  });
}
