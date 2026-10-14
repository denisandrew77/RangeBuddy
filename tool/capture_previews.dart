// Run: flutter test tool/capture_previews.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:range_buddy/data/fuel_service.dart';
import 'package:range_buddy/data/van_profile.dart';
import 'package:range_buddy/main.dart';

class PreviewStore implements ProfileStore {
  PreviewStore(this.profile);
  VanProfile? profile;
  @override
  Future<VanProfile?> load() async => profile;
  @override
  Future<void> save(VanProfile value) async {
    profile = value;
  }

  @override
  Future<void> clear() async {
    profile = null;
  }
}

void main() {
  testWidgets('capture setup and fuel entry previews', (tester) async {
    await tester.runAsync(() async {
      final loader = FontLoader('Roboto');
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        loader.addFont(rootBundle.load('assets/fonts/Roboto-$weight.ttf'));
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final key = GlobalKey();
    final profile = VanProfile(
      plate: 'B 123 ABC',
      startingKm: 125000,
      passwordSalt: base64Encode(List.filled(16, 1)),
      passwordHash: base64Encode(List.filled(32, 2)),
    );
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final page in ['setup', 'home']) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: RangeBuddyApp(
            store: PreviewStore(page == 'setup' ? null : profile),
            fuelService: PreviewFuelService(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final picture = await boundary.toImage();
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        final file = File('artifacts/previews/$page.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
      expect(tester.takeException(), isNull);
    }
  });
}
