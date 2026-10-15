import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/fuel_service.dart';
import 'data/van_profile.dart';
import 'ui/components.dart';
import 'ui/screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    RangeBuddyApp(
      store: LocalProfileStore(),
      fuelService: configuredFuelService(),
    ),
  );
}

class RangeBuddyApp extends StatefulWidget {
  const RangeBuddyApp({
    super.key,
    required this.store,
    required this.fuelService,
    this.passwords,
  });
  final ProfileStore store;
  final FuelService fuelService;
  final AdminPasswords? passwords;

  @override
  State<RangeBuddyApp> createState() => _RangeBuddyAppState();
}

class _RangeBuddyAppState extends State<RangeBuddyApp> {
  VanProfile? _profile;
  bool _loading = true;
  bool _loadFailed = false;
  late final _passwords = widget.passwords ?? AdminPasswords();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final profile = await widget.store.load();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadFailed = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _save(VanProfile profile) async {
    await widget.store.save(profile);
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _signOut() async {
    if (!kDebugMode) return;
    await widget.store.clear();
    if (mounted) setState(() => _profile = null);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'DENICAR',
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
    home: _loading
        ? const Scaffold(body: Center(child: CircularProgressIndicator()))
        : _loadFailed
        ? PageFrame(
            child: SectionCard(
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 36, color: muted),
                  const SizedBox(height: 16),
                  const Text(
                    'Configurarea autoutilitarei nu a putut fi încărcată.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Datele salvate au fost păstrate. Încearcă din nou.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ActionButton(
                    label: 'Încearcă din nou',
                    onPressed: _load,
                    icon: Icons.refresh,
                  ),
                ],
              ),
            ),
          )
        : _profile == null
        ? SetupPage(passwords: _passwords, onSave: _save)
        : HomePage(
            profile: _profile!,
            passwords: _passwords,
            service: widget.fuelService,
            onSave: _save,
            onSignOut: kDebugMode ? _signOut : null,
          ),
  );
}
