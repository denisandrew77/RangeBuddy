import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:range_buddy/data/session_store.dart';
import 'package:range_buddy/main.dart';

import 'support.dart';

Future<void> start(
  WidgetTester tester,
  MemorySecrets secrets,
  TestServer server,
) async {
  await tester.pumpWidget(RangeBuddyApp(store: secrets.store, api: server.api));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fillActivation(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), ' b123abc ');
  await tester.enterText(fields.at(1), '100000');
  await tester.enterText(fields.at(2), 'entered password');
}

Future<void> fillFuel(
  WidgetTester tester, {
  String km = '100500',
  String litres = '45,5',
  String price = '7,25',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), km);
  await tester.enterText(fields.at(1), litres);
  await tester.enterText(fields.at(2), price);
}

Future<void> openPlate(WidgetTester tester) =>
    tapVisible(tester, find.byTooltip('Modifică numărul de înmatriculare'));
Future<void> fillPlate(WidgetTester tester) async {
  final dialog = find.byType(AlertDialog);
  final fields = find.descendant(
    of: dialog,
    matching: find.byType(TextFormField),
  );
  await tester.enterText(fields.at(0), ' b456xyz ');
  await tester.enterText(fields.at(1), 'entered password');
}

void main() {
  testWidgets(
    'activation validates, obscures transient password and securely restores session',
    (tester) async {
      final secrets = MemorySecrets();
      final server = TestServer()..km = 180000;
      await start(tester, secrets, server);
      expect(
        Localizations.localeOf(tester.element(find.text('Gata de drum.'))),
        const Locale('ro', 'RO'),
      );
      await tapVisible(tester, find.text('Activează'));
      expect(server.requests, isEmpty);
      await fillActivation(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField).at(2)).obscureText,
        isTrue,
      );
      await tapVisible(tester, find.text('Activează'));
      expect(find.text('Kilometraj actual  ·  180000 km'), findsOneWidget);
      final stored = secrets.values.values.single;
      expect(stored, isNot(contains('entered password')));
      expect(stored, isNot(contains('passwordHash')));
      expect((await secrets.store.load())!.token, testToken);
      await tester.pumpWidget(const SizedBox());
      await start(tester, secrets, server);
      expect(find.text('B123ABC'), findsOneWidget);
      expect(server.count('POST'), 1);
    },
  );
  testWidgets(
    'wrong activation password stays a form error and clears only password input',
    (tester) async {
      final secrets = MemorySecrets();
      final server = TestServer()
        ..intercept = (r) async => r.method == 'POST'
            ? jsonResponse({'error': 'Wrong password'}, 401)
            : null;
      await start(tester, secrets, server);
      await fillActivation(tester);
      await tapVisible(tester, find.text('Activează'));
      expect(find.textContaining('Verifică parola'), findsOneWidget);
      expect(secrets.values, isEmpty);
      final fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(0)).controller!.text,
        ' b123abc ',
      );
      expect(tester.widget<TextFormField>(fields.at(2)).controller!.text, '');
    },
  );
  testWidgets('activation disables duplicate writes while pending', (
    tester,
  ) async {
    final secrets = MemorySecrets();
    final pending = Completer<http.Response>();
    final server = TestServer()
      ..intercept = (r) async => r.method == 'POST' ? pending.future : null;
    await start(tester, secrets, server);
    await fillActivation(tester);
    await tester.ensureVisible(find.text('Activează'));
    await tester.tap(find.text('Activează'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(server.count('POST'), 1);
    pending.complete(jsonResponse({'token': testToken, 'van': vanJson()}, 201));
    await tester.pumpAndSettle();
    expect(find.text('B123ABC'), findsOneWidget);
  });
  testWidgets(
    'activation storage failure retries only local persistence, not activation',
    (tester) async {
      final secrets = MemorySecrets()..failWrite = true;
      final server = TestServer();
      await start(tester, secrets, server);
      await fillActivation(tester);
      await tapVisible(tester, find.text('Activează'));
      expect(find.textContaining('doar salvarea locală'), findsOneWidget);
      secrets.failWrite = false;
      await tapVisible(tester, find.text('Reîncearcă'));
      expect(find.text('B123ABC'), findsOneWidget);
      expect(server.count('POST'), 1);
    },
  );
  for (final status in [401, 404, 503]) {
    testWidgets(
      'restore HTTP $status retains secure session and offers recovery',
      (tester) async {
        final secrets = MemorySecrets()..seed();
        final server = TestServer()
          ..intercept = (r) async => jsonResponse({
            'error': 'Unspecified authorization or lookup error',
          }, status);
        await start(tester, secrets, server);
        expect(find.text('Reîncearcă'), findsOneWidget);
        expect(secrets.values, isNotEmpty);
        server.intercept = null;
        await tapVisible(tester, find.text('Reîncearcă'));
        expect(find.text('B123ABC'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'offline restore and malformed/read-failed storage retain records',
    (tester) async {
      final secrets = MemorySecrets()..seed();
      final server = TestServer()
        ..intercept = (r) async => throw http.ClientException('offline');
      await start(tester, secrets, server);
      expect(
        find.textContaining('Conexiunea nu este disponibilă'),
        findsOneWidget,
      );
      expect(secrets.values, isNotEmpty);
      await tester.pumpWidget(const SizedBox());
      secrets.failRead = true;
      await start(tester, secrets, server);
      expect(
        find.textContaining('Sesiunea nu a putut fi citită'),
        findsOneWidget,
      );
      expect(secrets.values, isNotEmpty);
      await tester.pumpWidget(const SizedBox());
      secrets.failRead = false;
      secrets.values[SecureSessionStore.storageKey] = '{}';
      await start(tester, secrets, server);
      expect(find.text('Reîncearcă'), findsOneWidget);
    },
  );
  testWidgets(
    'invalid-device-token clears session; failed clear is recoverable',
    (tester) async {
      final secrets = MemorySecrets()
        ..seed()
        ..failDelete = true;
      final server = TestServer()
        ..intercept = (r) async =>
            jsonResponse({'error': 'Invalid device token'}, 401);
      await start(tester, secrets, server);
      expect(find.text('Reîncearcă'), findsOneWidget);
      expect(secrets.values, isNotEmpty);
      secrets.failDelete = false;
      await tapVisible(tester, find.text('Reîncearcă'));
      expect(find.text('Activează'), findsOneWidget);
      expect(secrets.values, isEmpty);
      expect(find.textContaining('Activează din nou'), findsOneWidget);
    },
  );
  testWidgets(
    'fuel validation blocks invalid integers and precision, date/time pickers are available',
    (tester) async {
      final secrets = MemorySecrets()..seed();
      final server = TestServer();
      await start(tester, secrets, server);
      await fillFuel(tester, km: '100000', litres: '45.1234', price: '0');
      await tapVisible(tester, find.text('Trimite datele'));
      expect(find.textContaining('mai mare decât 100000'), findsOneWidget);
      expect(find.textContaining('maximum 3 zecimale'), findsOneWidget);
      expect(server.count('POST'), 0);
      await tapVisible(tester, find.text('Data și ora alimentării'));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tapVisible(tester, find.text('OK'));
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tapVisible(tester, find.text('OK'));
    },
  );
  testWidgets(
    'fuel POST prevents duplicates, refreshes van/history, and clears submitted fields',
    (tester) async {
      final secrets = MemorySecrets()..seed();
      final server = TestServer();
      final pending = Completer<http.Response>();
      await start(tester, secrets, server);
      server.intercept = (r) async =>
          r.method == 'POST' ? pending.future : null;
      await fillFuel(tester);
      await tester.ensureVisible(find.text('Trimite datele'));
      await tester.tap(find.text('Trimite datele'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(server.count('POST'), 1);
      server.km = 100500;
      server.entries = [
        {...entryJson(), 'van': vanJson(km: 100500)},
      ];
      pending.complete(jsonResponse(entryJson(), 201));
      await tester.pumpAndSettle();
      expect(find.text('Kilometraj actual  ·  100500 km'), findsOneWidget);
      expect(
        find.text('Alimentarea a fost salvată pe server.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        '',
      );
      expect(server.requests.where((r) => r.method == 'GET').length, 4);
      await tester.ensureVisible(find.text('Istoric alimentări'));
      expect(find.textContaining('45 L'), findsOneWidget);
    },
  );
  testWidgets(
    'failed writes keep inputs, accepted entry with failed refresh offers read-only retry',
    (tester) async {
      final secrets = MemorySecrets()..seed();
      final server = TestServer();
      await start(tester, secrets, server);
      await fillFuel(tester);
      server.intercept = (r) async => r.method == 'POST'
          ? jsonResponse({
              'error': 'Invalid request',
              'fields': [
                {'field': 'litres', 'message': 'Server field detail'},
              ],
            }, 400)
          : null;
      await tapVisible(tester, find.text('Trimite datele'));
      expect(find.textContaining('Server field detail'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        '45,5',
      );
      server.intercept = (r) async => r.method == 'GET'
          ? jsonResponse({'error': 'Unavailable'}, 503)
          : null;
      await tapVisible(tester, find.text('Trimite datele'));
      expect(
        find.text('Alimentarea a fost salvată pe server.'),
        findsOneWidget,
      );
      expect(find.text('Reîmprospătează datele'), findsOneWidget);
      expect(find.text('Kilometraj actual  ·  100000 km'), findsOneWidget);
      server.intercept = null;
      await tapVisible(tester, find.text('Reîmprospătează datele'));
      expect(find.text('Kilometraj actual  ·  100500 km'), findsOneWidget);
      expect(server.count('POST'), 2);
    },
  );
  testWidgets('monthly selectors query exact month/year and show empty state', (
    tester,
  ) async {
    final secrets = MemorySecrets()..seed();
    final server = TestServer();
    await start(tester, secrets, server);
    expect(
      find.text('Nu există alimentări în luna selectată.'),
      findsOneWidget,
    );
    final month = find.byWidgetPredicate(
      (w) =>
          w is DropdownButtonFormField<int> && w.decoration.labelText == 'Lună',
    );
    await tester.ensureVisible(month);
    await tester.tap(month);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();
    expect(server.requests.last.url.queryParameters['month'], '2');
    final year = find.byWidgetPredicate(
      (w) =>
          w is DropdownButtonFormField<int> && w.decoration.labelText == 'An',
    );
    await tester.tap(year);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('2025').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025').last);
    await tester.pumpAndSettle();
    expect(server.requests.last.url.queryParameters, {
      'month': '2',
      'year': '2025',
    });
  });
  testWidgets(
    'wrong plate password keeps session; success saves returned plate without token rotation',
    (tester) async {
      final secrets = MemorySecrets()..seed();
      final server = TestServer();
      await start(tester, secrets, server);
      await openPlate(tester);
      await fillPlate(tester);
      server.intercept = (r) async => r.method == 'PUT'
          ? jsonResponse({'error': 'Wrong admin password'}, 401)
          : null;
      await tapVisible(tester, find.text('Salvează numărul'));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(secrets.values, isNotEmpty);
      final password = find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextFormField),
          )
          .last;
      expect(tester.widget<TextFormField>(password).controller!.text, '');
      server.intercept = null;
      await tester.enterText(password, 'entered password');
      await tapVisible(tester, find.text('Salvează numărul'));
      expect(find.text('B456XYZ'), findsOneWidget);
      final session = await secrets.store.load();
      expect(session!.plate, 'B456XYZ');
      expect(session.token, testToken);
      expect(
        server.requests.any((r) => r.url.path.endsWith('/vans/B456XYZ')),
        isTrue,
      );
    },
  );
  testWidgets(
    'plate-change persistence failure retries storage without repeating PUT',
    (tester) async {
      final secrets = MemorySecrets()..seed();
      final server = TestServer();
      await start(tester, secrets, server);
      await openPlate(tester);
      await fillPlate(tester);
      secrets.failWrite = true;
      await tapVisible(tester, find.text('Salvează numărul'));
      expect(find.textContaining('doar salvarea locală'), findsOneWidget);
      secrets.failWrite = false;
      await tapVisible(tester, find.text('Reîncearcă'));
      expect(find.text('B456XYZ'), findsOneWidget);
      expect(server.count('PUT'), 1);
    },
  );
  testWidgets(
    'invalid token in plate dialog closes dialog and returns to activation',
    (tester) async {
      final secrets = MemorySecrets()..seed();
      final server = TestServer();
      await start(tester, secrets, server);
      await openPlate(tester);
      await fillPlate(tester);
      server.intercept = (r) async =>
          jsonResponse({'error': 'Invalid device token'}, 401);
      await tapVisible(tester, find.text('Salvează numărul'));
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Activează'), findsOneWidget);
      expect(secrets.values, isEmpty);
    },
  );
  testWidgets(
    'local sign-out explains token remains valid and clears secure session',
    (tester) async {
      final secrets = MemorySecrets()..seed();
      final server = TestServer();
      await start(tester, secrets, server);
      await tapVisible(tester, find.text('Deconectare locală'));
      expect(find.textContaining('nu este revocat'), findsOneWidget);
      secrets.failDelete = true;
      await tapVisible(tester, find.text('Deconectează'));
      expect(
        find.textContaining('Deconectarea locală nu a reușit'),
        findsOneWidget,
      );
      expect(secrets.values, isNotEmpty);
      secrets.failDelete = false;
      await tapVisible(tester, find.text('Deconectare locală'));
      await tapVisible(tester, find.text('Deconectează'));
      expect(find.text('Activează'), findsOneWidget);
      expect(secrets.values, isEmpty);
      expect(server.count('POST'), 0);
      await tester.pumpWidget(const SizedBox());
      await start(tester, secrets, server);
      expect(find.text('Activează'), findsOneWidget);
    },
  );
  for (final width in [320.0, 1440.0]) {
    testWidgets('activation/home/plate dialog fit $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final secrets = MemorySecrets();
      final server = TestServer();
      await start(tester, secrets, server);
      expect(tester.takeException(), isNull);
      await fillActivation(tester);
      await tapVisible(tester, find.text('Activează'));
      expect(tester.takeException(), isNull);
      await openPlate(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
