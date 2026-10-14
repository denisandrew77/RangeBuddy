import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:range_buddy/data/fuel_service.dart';
import 'package:range_buddy/data/van_profile.dart';
import 'package:range_buddy/main.dart';
import 'package:range_buddy/ui/screens.dart';

final profile = VanProfile(
  plate: 'B 123 ABC',
  startingKm: 0,
  passwordSalt: base64Encode(List.filled(16, 1)),
  passwordHash: base64Encode(List.filled(32, 2)),
);

class MemoryStore implements ProfileStore {
  MemoryStore([this.profile]);
  VanProfile? profile;
  bool failSave = false;
  bool failClear = false;
  @override
  Future<VanProfile?> load() async => profile;
  @override
  Future<void> save(VanProfile value) async {
    if (failSave) throw StateError('Storage unavailable');
    profile = value;
  }

  @override
  Future<void> clear() async {
    if (failClear) throw StateError('Storage unavailable');
    profile = null;
  }
}

// Crypto itself is exercised in data_test; deterministic UI verification avoids
// mixing CPU-intensive derivation with Flutter's simulated widget-test clock.
class TestPasswords extends AdminPasswords {
  @override
  Future<VanProfile> create(String plate, double km, String password) async =>
      profile.copyWith(plate: plate.trim().toUpperCase(), startingKm: km);
  @override
  Future<bool> verify(VanProfile profile, String password) async =>
      password == 'secret';
}

class PendingService implements FuelService {
  final response = Completer<SubmissionResult>();
  int calls = 0;
  @override
  bool get isPreview => false;
  @override
  Future<SubmissionResult> submit(FuelEntry entry) {
    calls++;
    return response.future;
  }
}

Future<void> start(
  WidgetTester tester,
  MemoryStore store, {
  FuelService? service,
}) async {
  await tester.pumpWidget(
    RangeBuddyApp(
      store: store,
      fuelService: service ?? PreviewFuelService(),
      passwords: TestPasswords(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> fillFuel(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), '150');
  await tester.enterText(fields.at(1), '42,5');
  await tester.enterText(fields.at(2), '7,25');
}

void main() {
  testWidgets(
    'development sign out clears setup and reopening stays on setup',
    (tester) async {
      final store = MemoryStore(profile);
      await start(tester, store);
      await fillFuel(tester);
      await tapVisible(tester, find.text('Deconectare'));
      expect(store.profile, isNull);
      expect(find.text('Gata de drum.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        '0',
      );
      await tester.pumpWidget(const SizedBox());
      await start(tester, store);
      expect(find.text('Gata de drum.'), findsOneWidget);
      expect(find.text('B 123 ABC'), findsNothing);
    },
  );

  testWidgets('failed sign out preserves the profile and entry', (
    tester,
  ) async {
    final store = MemoryStore(profile)..failClear = true;
    await start(tester, store);
    await fillFuel(tester);
    await tapVisible(tester, find.text('Deconectare'));
    expect(
      find.text('Deconectarea nu a reușit. Încearcă din nou.'),
      findsOneWidget,
    );
    expect(store.profile, profile);
    expect(find.text('B 123 ABC'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(2))
          .controller!
          .text,
      '7,25',
    );
  });

  testWidgets('home without a development callback has no sign out button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          profile: profile,
          passwords: TestPasswords(),
          service: PreviewFuelService(),
          onSave: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Deconectare'), findsNothing);
  });
  testWidgets(
    'setup validates and creates a persistent van, then reopening skips setup',
    (tester) async {
      final store = MemoryStore();
      await start(tester, store);
      expect(find.text('Gata de drum.'), findsOneWidget);
      final context = tester.element(find.text('Gata de drum.'));
      expect(Localizations.localeOf(context), const Locale('ro', 'RO'));
      expect(MaterialLocalizations.of(context).backButtonTooltip, 'Înapoi');
      await tapVisible(tester, find.text('Creează'));
      expect(find.text('Acest câmp este obligatoriu'), findsNWidgets(2));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'b 123 abc');
      await tester.enterText(fields.at(1), '100');
      await tester.enterText(fields.at(2), 'secret');
      await tapVisible(tester, find.text('Creează'));
      expect(find.text('B 123 ABC'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(store.profile!.startingKm, 100);
      await tester.pumpWidget(const SizedBox());
      await start(tester, store);
      expect(find.text('B 123 ABC'), findsOneWidget);
      expect(find.text('Creează'), findsNothing);
    },
  );

  testWidgets('preview shows all values honestly and keeps the form', (
    tester,
  ) async {
    await start(tester, MemoryStore(profile));
    await fillFuel(tester);
    await tapVisible(tester, find.text('Trimite datele'));
    expect(
      find.text('Serverul nu este conectat. Datele nu au fost trimise.'),
      findsOneWidget,
    );
    expect(find.text('Combustibil alimentat: 42,5 L'), findsOneWidget);
    expect(find.text('Preț pe litru: 7,25'), findsOneWidget);
    expect(find.text('Kilometraj actual  ·  0 km'), findsOneWidget);
    await tapVisible(tester, find.text('Înapoi la formular'));
    final input = tester.widget<TextFormField>(
      find.byType(TextFormField).at(1),
    );
    expect(input.controller!.text, '42,5');
  });

  testWidgets(
    'plate editing rejects wrong password, saves after unlock, and relocks',
    (tester) async {
      final store = MemoryStore(profile);
      await start(tester, store);
      await tapVisible(tester, find.byTooltip('Setări autoutilitară'));
      await tapVisible(tester, find.text('Modifică numărul de înmatriculare'));
      expect(find.byKey(const ValueKey('edit-plate')), findsNothing);
      await tester.enterText(find.byType(TextFormField), 'wrong');
      await tapVisible(tester, find.text('Deblochează editarea'));
      expect(
        find.text('Parola de administrator este incorectă. Încearcă din nou.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField), 'secret');
      await tapVisible(tester, find.text('Deblochează editarea'));
      await tester.enterText(
        find.byKey(const ValueKey('edit-plate')),
        'cj 99 van',
      );
      await tapVisible(tester, find.text('Salvează numărul'));
      expect(find.text('CJ 99 VAN'), findsOneWidget);
      expect(store.profile!.plate, 'CJ 99 VAN');
      await tapVisible(tester, find.byTooltip('Setări autoutilitară'));
      await tapVisible(tester, find.text('Modifică numărul de înmatriculare'));
      expect(find.text('Deblochează editarea'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit-plate')), findsNothing);
    },
  );

  testWidgets('starting kilometres can be edited and persist', (tester) async {
    final store = MemoryStore(profile);
    await start(tester, store);
    await tapVisible(tester, find.byTooltip('Setări autoutilitară'));
    await tapVisible(tester, find.text('Kilometraj inițial'));
    expect(find.text('Salvează kilometrajul'), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'wrong');
    await tapVisible(tester, find.text('Deblochează editarea'));
    expect(
      find.text('Parola de administrator este incorectă. Încearcă din nou.'),
      findsOneWidget,
    );
    expect(find.text('Salvează kilometrajul'), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'secret');
    await tapVisible(tester, find.text('Deblochează editarea'));
    await tester.enterText(find.byType(TextFormField), '200');
    await tapVisible(tester, find.text('Salvează kilometrajul'));
    expect(find.text('Kilometraj actual  ·  200 km'), findsOneWidget);
    expect(store.profile!.startingKm, 200);
    await tester.pumpWidget(const SizedBox());
    await start(tester, store);
    expect(find.text('Kilometraj actual  ·  200 km'), findsOneWidget);
    await tapVisible(tester, find.byTooltip('Setări autoutilitară'));
    await tapVisible(tester, find.text('Kilometraj inițial'));
    expect(find.text('Deblochează editarea'), findsOneWidget);
    expect(find.text('Salvează kilometrajul'), findsNothing);
  });

  testWidgets('invalid fuel values prevent any submission', (tester) async {
    final service = PendingService();
    await start(
      tester,
      MemoryStore(profile.copyWith(startingKm: 100)),
      service: service,
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '99');
    await tester.enterText(fields.at(1), '0');
    await tester.enterText(fields.at(2), 'NaN');
    await tapVisible(tester, find.text('Trimite datele'));
    expect(find.text('Valoarea minimă este 100 km'), findsOneWidget);
    expect(find.text('Introdu o valoare mai mare decât 0'), findsOneWidget);
    expect(find.text('Introdu un număr valid'), findsOneWidget);
    expect(service.calls, 0);
  });

  testWidgets('setup storage failure stays on setup and preserves inputs', (
    tester,
  ) async {
    final store = MemoryStore()..failSave = true;
    await start(tester, store);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'B 123 ABC');
    await tester.enterText(fields.at(2), 'secret');
    await tapVisible(tester, find.text('Creează'));
    expect(
      find.text('Configurarea nu a putut fi salvată. Încearcă din nou.'),
      findsOneWidget,
    );
    expect(store.profile, isNull);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'B 123 ABC',
    );
  });

  testWidgets(
    'pending submission prevents duplicate requests and failed delivery keeps inputs',
    (tester) async {
      final service = PendingService();
      await start(tester, MemoryStore(profile), service: service);
      await fillFuel(tester);
      await tester.ensureVisible(find.text('Trimite datele'));
      await tester.tap(find.text('Trimite datele'));
      await tester.pump();
      expect(service.calls, 1);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Deconectare'))
            .onPressed,
        isNull,
      );
      service.response.completeError(
        const SubmissionException('Delivery failed'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delivery failed'), findsOneWidget);
      expect(find.text('Kilometraj actual  ·  0 km'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(2))
            .controller!
            .text,
        '7,25',
      );
    },
  );

  testWidgets(
    'confirmed submission saves current reading, clears fields and shows success',
    (tester) async {
      final service = PendingService();
      final store = MemoryStore(profile);
      await start(tester, store, service: service);
      await fillFuel(tester);
      await tester.ensureVisible(find.text('Trimite datele'));
      await tester.tap(find.text('Trimite datele'));
      await tester.pump();
      service.response.complete(SubmissionResult.sent);
      await tester.pumpAndSettle();
      expect(find.text('Datele au fost trimise către server.'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        '',
      );
      expect(find.text('Kilometraj actual  ·  150 km'), findsOneWidget);
      expect(store.profile!.currentKm, 150);
      await tester.pumpWidget(const SizedBox());
      await start(tester, store);
      expect(find.text('Kilometraj actual  ·  150 km'), findsOneWidget);
    },
  );

  testWidgets(
    'confirmed send with failed local save preserves old reading and warns against resending',
    (tester) async {
      final store = MemoryStore(profile)..failSave = true;
      final service = PendingService();
      await start(tester, store, service: service);
      await fillFuel(tester);
      await tester.ensureVisible(find.text('Trimite datele'));
      await tester.tap(find.text('Trimite datele'));
      await tester.pump();
      service.response.complete(SubmissionResult.sent);
      await tester.pumpAndSettle();
      expect(find.textContaining('Nu retrimite alimentarea.'), findsOneWidget);
      expect(find.text('Kilometraj actual  ·  0 km'), findsOneWidget);
      expect(store.profile!.currentKm, 0);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        '150',
      );
    },
  );

  testWidgets(
    'baseline correction failure preserves profile, successful correction preserves current reading',
    (tester) async {
      final store = MemoryStore(profile.copyWith(lastOdometerKm: 500));
      await start(tester, store);
      await tapVisible(tester, find.byTooltip('Setări autoutilitară'));
      await tapVisible(tester, find.text('Kilometraj inițial'));
      await tester.enterText(find.byType(TextFormField), 'secret');
      await tapVisible(tester, find.text('Deblochează editarea'));
      await tester.enterText(find.byType(TextFormField), '200');
      store.failSave = true;
      await tapVisible(tester, find.text('Salvează kilometrajul'));
      expect(
        find.text(
          'Kilometrajul inițial nu a putut fi salvat. Încearcă din nou.',
        ),
        findsOneWidget,
      );
      expect(store.profile!.startingKm, 0);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '200',
      );
      store.failSave = false;
      await tapVisible(tester, find.text('Salvează kilometrajul'));
      expect(store.profile!.startingKm, 200);
      expect(find.text('Kilometraj actual  ·  500 km'), findsOneWidget);
    },
  );

  for (final width in [320.0, 1440.0]) {
    testWidgets('setup and home fit width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await start(tester, MemoryStore());
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await start(tester, MemoryStore(profile));
      expect(tester.takeException(), isNull);
      await tapVisible(tester, find.byTooltip('Setări autoutilitară'));
      await tapVisible(tester, find.text('Modifică numărul de înmatriculare'));
      expect(tester.takeException(), isNull);
    });
  }
}
