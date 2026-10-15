import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/fuel_service.dart';
import 'data/van_profile.dart';
import 'data/session_store.dart';
import 'ui/components.dart';
import 'ui/screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  RangeBuddyApi? api;
  String? configurationError;
  try {
    api = RangeBuddyApi.configured();
  } on ApiException catch (error) {
    configurationError = error.message;
  }
  runApp(
    RangeBuddyApp(
      store: SecureSessionStore(),
      api: api,
      configurationError: configurationError,
    ),
  );
}

class RangeBuddyApp extends StatefulWidget {
  const RangeBuddyApp({
    super.key,
    required this.store,
    required this.api,
    this.configurationError,
  });
  final SessionStore store;
  final RangeBuddyApi? api;
  final String? configurationError;
  @override
  State<RangeBuddyApp> createState() => _RangeBuddyAppState();
}

class _RangeBuddyAppState extends State<RangeBuddyApp> {
  final _navigator = GlobalKey<NavigatorState>();
  DeviceSession? _session;
  Van? _van;
  bool _loading = true;
  bool _needsSave = false;
  bool _invalidPending = false;
  String? _error;
  String? _activationNotice;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    if (widget.api == null) {
      setState(() {
        _loading = false;
        _error = widget.configurationError;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _session = await widget.store.load();
      if (_session != null) {
        _van = await _authorized((s) => widget.api!.getVan(s));
      }
    } on ApiException catch (error) {
      if (mounted && _session != null) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Sesiunea nu a putut fi citită. Datele locale nu au fost șterse.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<T> _authorized<T>(
    Future<T> Function(DeviceSession session) action,
  ) async {
    try {
      return await action(_session!);
    } on ApiException catch (error) {
      if (error.invalidDeviceToken) {
        _invalidPending = true;
        await _clearInvalid();
      }
      rethrow;
    }
  }

  Future<void> _clearInvalid() async {
    try {
      await widget.store.clear();
      if (!mounted) return;
      setState(() {
        _session = null;
        _van = null;
        _invalidPending = false;
        _error = null;
        _activationNotice =
            'Sesiunea dispozitivului nu mai este validă. Activează din nou.';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Sesiunea este invalidă, dar ștergerea locală nu a reușit. Reîncearcă ștergerea.',
        );
      }
    }
  }

  Future<void> _persistSession() async {
    try {
      await widget.store.save(_session!);
      if (mounted) {
        setState(() {
          _needsSave = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _needsSave = true;
          _error = 'Operația a reușit pe server, dar sesiunea nu a putut fi salvată local. Reîncearcă doar salvarea locală.';
        });
      }
    }
  }

  Future<void> _activate(String plate, int km, String password) async {
    final result = await widget.api!.activate(plate, km, password);
    if (!mounted) return;
    _session = DeviceSession(
      token: result.token,
      plate: result.van.licensePlate,
      baseUrl: widget.api!.baseUrl,
    );
    _van = result.van;
    await _persistSession();
  }

  Future<Van> _refreshVan() async {
    final van = await _authorized((s) => widget.api!.getVan(s));
    if (mounted) setState(() => _van = van);
    return van;
  }

  Future<void> _changePlate(String plate, String password) async {
    final van = await _authorized(
      (s) => widget.api!.changePlate(s, plate, password),
    );
    if (!mounted) return;
    _van = van;
    _session = _session!.withPlate(van.licensePlate);
    await _persistSession();
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    try {
      await widget.store.clear();
    } catch (_) {
      throw const ApiException(
        'Deconectarea locală nu a reușit. Sesiunea a fost păstrată.',
      );
    }
    if (mounted) {
      setState(() {
        _session = null;
        _van = null;
        _error = null;
        _needsSave = false;
        _invalidPending = false;
        _activationNotice = null;
      });
    }
  }

  Future<void> _retryRecovery() async {
    setState(() => _loading = true);
    if (_invalidPending) {
      await _clearInvalid();
    } else if (_needsSave) {
      await _persistSession();
    } else {
      await _restore();
    }
    if (mounted) setState(() => _loading = false);
  }

  Widget _content() {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_invalidPending || _needsSave || _error != null || widget.api == null) {
      return RecoveryPage(
        message: _error ?? widget.configurationError ?? 'API indisponibil.',
        onRetry: widget.api == null ? null : _retryRecovery,
        onSignOut: widget.api == null ? null : _signOut,
      );
    }
    if (_session == null) {
      return ActivationPage(onActivate: _activate, notice: _activationNotice);
    }
    return HomePage(
      van: _van!,
      onRefreshVan: _refreshVan,
      onHistory: (month, year) => _authorized(
        (s) => widget.api!.getEntries(s, month: month, year: year),
      ),
      onSubmit: (draft) => _authorized(
        (s) => widget.api!.addEntry(s, draft, lastKms: _van!.lastKms),
      ),
      onChangePlate: _changePlate,
      onSignOut: _signOut,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DENICAR',
    navigatorKey: _navigator,
    locale: const Locale('ro', 'RO'),
    supportedLocales: const [Locale('ro', 'RO')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(seedColor: teal)
          .copyWith(primary: teal, secondary: ink, surface: Colors.white),
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 76,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF6F8FA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDFE6EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDFE6EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: teal, width: 2),
        ),
        prefixIconColor: muted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    home: _content(),
  );
}
