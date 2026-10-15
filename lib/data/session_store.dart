import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSession {
  const DeviceSession({
    required this.token,
    required this.plate,
    required this.baseUrl,
  });
  final String token;
  final String plate;
  final String baseUrl;
  DeviceSession withPlate(String plate) =>
      DeviceSession(token: token, plate: plate, baseUrl: baseUrl);
  Map<String, dynamic> toJson() => {
    'token': token,
    'plate': plate,
    'baseUrl': baseUrl,
  };
  factory DeviceSession.fromJson(Map<String, dynamic> json) {
    final session = DeviceSession(
      token: json['token'] as String,
      plate: json['plate'] as String,
      baseUrl: json['baseUrl'] as String,
    );
    if (session.token.trim().isEmpty ||
        session.token.contains(RegExp(r'[\r\n]')) ||
        session.plate.isEmpty ||
        session.baseUrl.isEmpty) {
      throw const FormatException('Invalid session record');
    }
    return session;
  }
}

abstract interface class SecretStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class PlatformSecretStorage implements SecretStorage {
  const PlatformSecretStorage();
  static const _storage = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

abstract interface class SessionStore {
  Future<DeviceSession?> load();
  Future<void> save(DeviceSession session);
  Future<void> clear();
}

class SecureSessionStore implements SessionStore {
  SecureSessionStore({
    SecretStorage? storage,
    Future<void> Function()? removeLegacyProfile,
  }) : _storage = storage ?? const PlatformSecretStorage(),
       _removeLegacyProfile = removeLegacyProfile ?? _removeLegacy;
  static const storageKey = 'rangebuddy.device.session.v1';
  final SecretStorage _storage;
  final Future<void> Function() _removeLegacyProfile;
  static Future<void> _removeLegacy() =>
      SharedPreferencesAsync().remove('rangebuddy.van.v1');
  @override
  Future<DeviceSession?> load() async {
    await _removeLegacyProfile();
    final value = await _storage.read(storageKey);
    return value == null
        ? null
        : DeviceSession.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Future<void> save(DeviceSession session) =>
      _storage.write(storageKey, jsonEncode(session.toJson()));
  @override
  Future<void> clear() async {
    await _storage.delete(storageKey);
    await _removeLegacyProfile();
  }
}
