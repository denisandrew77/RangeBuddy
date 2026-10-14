import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VanProfile {
  const VanProfile({
    required this.plate,
    required this.startingKm,
    required this.passwordSalt,
    required this.passwordHash,
    this.lastOdometerKm,
  });

  final String plate;
  final double startingKm;
  final double? lastOdometerKm;
  double get currentKm => lastOdometerKm ?? startingKm;
  final String passwordSalt;
  final String passwordHash;

  VanProfile copyWith({
    String? plate,
    double? startingKm,
    double? lastOdometerKm,
  }) => VanProfile(
    plate: plate ?? this.plate,
    startingKm: startingKm ?? this.startingKm,
    lastOdometerKm: lastOdometerKm ?? this.lastOdometerKm,
    passwordSalt: passwordSalt,
    passwordHash: passwordHash,
  );

  Map<String, dynamic> toJson() => {
    'plate': plate,
    'startingKm': startingKm,
    if (lastOdometerKm != null) 'lastOdometerKm': lastOdometerKm,
    'passwordSalt': passwordSalt,
    'passwordHash': passwordHash,
  };

  factory VanProfile.fromJson(Map<String, dynamic> json) {
    final profile = VanProfile(
      plate: json['plate'] as String,
      lastOdometerKm: (json['lastOdometerKm'] as num?)?.toDouble(),
      startingKm: (json['startingKm'] as num).toDouble(),
      passwordSalt: json['passwordSalt'] as String,
      passwordHash: json['passwordHash'] as String,
    );
    if (profile.plate.trim().isEmpty ||
        !profile.startingKm.isFinite ||
        profile.startingKm < 0 ||
        !profile.currentKm.isFinite ||
        profile.currentKm < 0 ||
        base64Decode(profile.passwordSalt).length != 16 ||
        base64Decode(profile.passwordHash).length != 32) {
      throw const FormatException('Invalid saved van profile');
    }
    return profile;
  }
}

abstract interface class ProfileStore {
  Future<VanProfile?> load();
  Future<void> save(VanProfile profile);
  Future<void> clear();
}

class LocalProfileStore implements ProfileStore {
  static const storageKey = 'rangebuddy.van.v1';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<VanProfile?> load() async {
    final value = await _preferences.getString(storageKey);
    return value == null
        ? null
        : VanProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  @override
  Future<void> save(VanProfile profile) =>
      _preferences.setString(storageKey, jsonEncode(profile.toJson()));

  @override
  Future<void> clear() => _preferences.remove(storageKey);
}

class AdminPasswords {
  final _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 100000,
    bits: 256,
  );

  Future<VanProfile> create(String plate, double km, String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    return VanProfile(
      plate: plate.trim().toUpperCase(),
      startingKm: km,
      passwordSalt: base64Encode(salt),
      passwordHash: base64Encode(await _derive(password, salt)),
    );
  }

  Future<bool> verify(VanProfile profile, String password) async {
    final actual = await _derive(password, base64Decode(profile.passwordSalt));
    final expected = base64Decode(profile.passwordHash);
    if (actual.length != expected.length) return false;
    var difference = 0;
    for (var i = 0; i < actual.length; i++) {
      difference |= actual[i] ^ expected[i];
    }
    return difference == 0;
  }

  Future<List<int>> _derive(String password, List<int> salt) async {
    final key = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return key.extractBytes();
  }
}
