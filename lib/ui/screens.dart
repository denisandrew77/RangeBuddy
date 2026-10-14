import 'package:flutter/material.dart';

import '../data/fuel_service.dart';
import '../data/van_profile.dart';
import 'components.dart';

typedef SaveProfile = Future<void> Function(VanProfile profile);

class SetupPage extends StatefulWidget {
  const SetupPage({super.key, required this.passwords, required this.onSave});
  final AdminPasswords passwords;
  final SaveProfile onSave;
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _form = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _password = TextEditingController();
  final _km = TextEditingController(text: '0');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _plate.dispose();
    _password.dispose();
    _km.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final profile = await widget.passwords.create(
        _plate.text,
        parseNumber(_km.text)!,
        _password.text,
      );
      await widget.onSave(profile);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Configurarea nu a putut fi salvată. Încearcă din nou.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          eyebrow: 'CONFIGURARE VEHICUL',
          title: 'Gata de drum.',
          subtitle: 'Configurează autoutilitara și înregistrează simplu fiecare alimentare.',
        ),
        SectionCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Autoutilitara ta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Câteva detalii pentru început.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _plate,
                  validator: requiredText,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Număr de înmatriculare',
                    hintText: 'de ex. B 123 ABC',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                NumberField(
                  controller: _km,
                  label: 'Kilometraj inițial',
                  unit: 'km',
                  icon: Icons.speed_outlined,
                  allowZero: true,
                ),
                const SizedBox(height: 20),
                PasswordField(
                  controller: _password,
                  onSubmitted: (_) => _create(),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Păstrează parola. Vei avea nevoie de ea pentru a schimba numărul de înmatriculare și kilometrajul inițial.',
                  style: TextStyle(color: muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 24),
                ErrorNote(_error),
                ActionButton(label: 'Creează', onPressed: _create, busy: _busy),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Configurarea se păstrează pe acest dispozitiv.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.profile,
    required this.passwords,
    required this.service,
    required this.onSave,
    this.onSignOut,
  });
  final VanProfile profile;
  final AdminPasswords passwords;
  final FuelService service;
  final SaveProfile onSave;
  final Future<void> Function()? onSignOut;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _form = GlobalKey<FormState>();
  final _km = TextEditingController();
  final _litres = TextEditingController();
  final _price = TextEditingController();
  bool _busy = false;
  bool _signingOut = false;
  String? _error;

  @override
  void dispose() {
    _km.dispose();
    _litres.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || _signingOut || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final entry = FuelEntry(
      plate: widget.profile.plate,
      odometerKm: parseNumber(_km.text)!,
      litres: parseNumber(_litres.text)!,
      pricePerLitre: parseNumber(_price.text)!,
      recordedAt: DateTime.now(),
    );
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.service.submit(entry);
      if (!mounted) return;
      if (result == SubmissionResult.sent) {
        try {
          await widget.onSave(
            widget.profile.copyWith(lastOdometerKm: entry.odometerKm),
          );
        } catch (_) {
          if (mounted) {
            setState(
              () => _error = 'Datele au fost trimise către server, dar kilometrajul nu a putut fi salvat pe dispozitiv. Nu retrimite alimentarea. Datele introduse au fost păstrate.',
            );
          }
          return;
        }
      }
      if (!mounted) return;
      if (result == SubmissionResult.preview) {
        setState(() => _busy = false);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.receipt_long_outlined, color: teal),
            title: const Text('Previzualizare alimentare'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Serverul nu este conectat. Datele nu au fost trimise.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                Text('Număr de înmatriculare: ${entry.plate}'),
                const SizedBox(height: 10),
                Text('Kilometraj: ${numberLabel(entry.odometerKm)} km'),
                const SizedBox(height: 10),
                Text('Combustibil alimentat: ${numberLabel(entry.litres)} L'),
                const SizedBox(height: 10),
                Text('Preț pe litru: ${numberLabel(entry.pricePerLitre)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Înapoi la formular'),
              ),
            ],
          ),
        );
      } else {
        _form.currentState!.reset();
        _km.clear();
        _litres.clear();
        _price.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datele au fost trimise către server.')),
        );
      }
    } on SubmissionException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Trimiterea nu a putut fi confirmată. Datele introduse au fost păstrate.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _settings(String value) {
    if (_busy || _signingOut) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => value == 'plate'
            ? PlatePage(
                profile: widget.profile,
                passwords: widget.passwords,
                onSave: widget.onSave,
              )
            : StartingKmPage(
                profile: widget.profile,
                passwords: widget.passwords,
                onSave: widget.onSave,
              ),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_busy || _signingOut || widget.onSignOut == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await widget.onSignOut!();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Deconectarea nu a reușit. Încearcă din nou.');
      }
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    actions: [
      PopupMenuButton<String>(
        tooltip: 'Setări autoutilitară',
        enabled: !_busy && !_signingOut,
        onSelected: _settings,
        icon: const Icon(Icons.tune_outlined),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'plate',
            child: Text('Modifică numărul de înmatriculare'),
          ),
          PopupMenuItem(value: 'km', child: Text('Kilometraj inițial')),
        ],
      ),
      const SizedBox(width: 8),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    color: Color(0xFF8CCAC2),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AUTOUTILITARA TA',
                      style: TextStyle(
                        color: Color(0xFFB7C9D4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.profile.plate,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Kilometraj actual  ·  ${numberLabel(widget.profile.currentKm)} km',
                style: const TextStyle(color: Color(0xFFB7C9D4), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SectionCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_gas_station_outlined, color: teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Înregistrează o alimentare',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completează detaliile alimentării.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                AbsorbPointer(
                  absorbing: _busy || _signingOut,
                  child: Column(
                    children: [
                      NumberField(
                        controller: _km,
                        label: 'Kilometraj actual',
                        unit: 'km',
                        icon: Icons.speed_outlined,
                        allowZero: true,
                        minimum: widget.profile.startingKm,
                        hint: 'Valoarea actuală a kilometrajului',
                      ),
                      const SizedBox(height: 20),
                      NumberField(
                        controller: _litres,
                        label: 'Combustibil alimentat',
                        unit: 'L',
                        icon: Icons.local_gas_station_outlined,
                        hint: 'Cantitatea alimentată în litri',
                      ),
                      const SizedBox(height: 20),
                      NumberField(
                        controller: _price,
                        label: 'Preț pe litru',
                        unit: '',
                        icon: Icons.payments_outlined,
                        hint: 'Prețul unui litru de combustibil',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ErrorNote(_error),
                ActionButton(
                  label: 'Trimite datele',
                  onPressed: _submit,
                  busy: _busy || _signingOut,
                  icon: Icons.send_outlined,
                ),
              ],
            ),
          ),
        ),
        if (widget.onSignOut != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _busy || _signingOut ? null : _signOut,
              icon: const Icon(Icons.logout_outlined, size: 20),
              label: Text(_signingOut ? 'Se deconectează…' : 'Deconectare'),
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (widget.service.isPreview)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF936521), size: 19),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mod previzualizare · Serverul nu este încă conectat. Alimentările nu sunt trimise sau salvate.',
                    style: TextStyle(
                      color: Color(0xFF79551E),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class PlatePage extends StatefulWidget {
  const PlatePage({
    super.key,
    required this.profile,
    required this.passwords,
    required this.onSave,
  });
  final VanProfile profile;
  final AdminPasswords passwords;
  final SaveProfile onSave;
  @override
  State<PlatePage> createState() => _PlatePageState();
}

class _PlatePageState extends State<PlatePage> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  late final _plate = TextEditingController(text: widget.profile.plate);
  bool _unlocked = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_unlocked) {
        final valid = await widget.passwords.verify(
          widget.profile,
          _password.text,
        );
        if (!mounted) return;
        if (valid) {
          _password.clear();
          setState(() => _unlocked = true);
        } else {
          setState(
            () => _error =
                'Parola de administrator este incorectă. Încearcă din nou.',
          );
        }
      } else {
        await widget.onSave(
          widget.profile.copyWith(plate: _plate.text.trim().toUpperCase()),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Numărul de înmatriculare nu a putut fi actualizat. Încearcă din nou.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    back: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          eyebrow: 'SETĂRI AUTOUTILITARĂ',
          title: 'Modifică numărul de înmatriculare',
          subtitle: _unlocked
              ? 'Actualizează numărul de înmatriculare folosit pentru alimentări.'
              : 'Introdu parola de administrator pentru a face modificări.',
        ),
        SectionCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _unlocked
                      ? Icons.directions_car_outlined
                      : Icons.lock_outline,
                  color: teal,
                  size: 32,
                ),
                const SizedBox(height: 24),
                if (_unlocked)
                  TextFormField(
                    key: const ValueKey('edit-plate'),
                    controller: _plate,
                    validator: requiredText,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Număr de înmatriculare',
                      prefixIcon: Icon(Icons.directions_car_outlined),
                    ),
                    onFieldSubmitted: (_) => _continue(),
                  )
                else
                  PasswordField(
                    controller: _password,
                    onSubmitted: (_) => _continue(),
                  ),
                const SizedBox(height: 24),
                ErrorNote(_error),
                ActionButton(
                  label: _unlocked
                      ? 'Salvează numărul'
                      : 'Deblochează editarea',
                  onPressed: _continue,
                  busy: _busy,
                  icon: _unlocked ? Icons.check : Icons.lock_open_outlined,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class StartingKmPage extends StatefulWidget {
  const StartingKmPage({
    super.key,
    required this.profile,
    required this.passwords,
    required this.onSave,
  });
  final VanProfile profile;
  final AdminPasswords passwords;
  final SaveProfile onSave;
  @override
  State<StartingKmPage> createState() => _StartingKmPageState();
}

class _StartingKmPageState extends State<StartingKmPage> {
  final _form = GlobalKey<FormState>();
  late final _km = TextEditingController(
    text: numberLabel(widget.profile.startingKm),
  );
  final _password = TextEditingController();
  bool _unlocked = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _km.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_unlocked) {
        final valid = await widget.passwords.verify(
          widget.profile,
          _password.text,
        );
        if (!mounted) return;
        if (valid) {
          _password.clear();
          setState(() => _unlocked = true);
        } else {
          setState(
            () => _error =
                'Parola de administrator este incorectă. Încearcă din nou.',
          );
        }
      } else {
        await widget.onSave(
          widget.profile.copyWith(startingKm: parseNumber(_km.text)!),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Kilometrajul inițial nu a putut fi salvat. Încearcă din nou.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    back: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeading(
          eyebrow: 'SETĂRI AUTOUTILITARĂ',
          title: 'Kilometraj inițial',
          subtitle: _unlocked
              ? 'Setează kilometrajul de pornire al autoutilitarei.'
              : 'Introdu parola de administrator pentru a face modificări.',
        ),
        SectionCard(
          child: Form(
            key: _form,
            child: Column(
              children: [
                if (_unlocked)
                  NumberField(
                    controller: _km,
                    label: 'Kilometraj inițial',
                    unit: 'km',
                    icon: Icons.speed_outlined,
                    allowZero: true,
                  )
                else
                  PasswordField(
                    controller: _password,
                    onSubmitted: (_) => _save(),
                  ),
                const SizedBox(height: 24),
                ErrorNote(_error),
                ActionButton(
                  label: _unlocked
                      ? 'Salvează kilometrajul'
                      : 'Deblochează editarea',
                  onPressed: _save,
                  busy: _busy,
                  icon: _unlocked ? Icons.check : Icons.lock_open_outlined,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
