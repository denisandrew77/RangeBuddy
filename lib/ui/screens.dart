import 'package:flutter/material.dart';

import '../data/bucharest_time.dart';
import '../data/fuel_service.dart';
import '../data/validation.dart';
import '../data/van_profile.dart';
import 'components.dart';

String errorMessage(Object error) => error is ApiException
    ? [
        error.message,
        ...error.fields.entries.map((e) => '${fieldLabel(e.key)}: ${e.value}'),
      ].join('\n')
    : 'Operația nu a putut fi finalizată. Încearcă din nou.';
String fieldLabel(String field) => switch (field) {
  'license_plate' || 'new_license_plate' => 'Număr de înmatriculare',
  'initial_kms' => 'Kilometraj inițial',
  'current_kms' => 'Kilometraj actual',
  'litres' => 'Litri',
  'price_per_litre' => 'Preț pe litru',
  'password' => 'Parolă',
  'fuel_date' => 'Data alimentării',
  _ => 'Câmp',
};
String dateLabel(BuildContext context, DateTime date) {
  final local = date.toLocal();
  final material = MaterialLocalizations.of(context);
  return '${material.formatShortDate(local)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
}

class ActivationPage extends StatefulWidget {
  const ActivationPage({super.key, required this.onActivate, this.notice});
  final Future<void> Function(String, int, String) onActivate;
  final String? notice;
  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _form = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _km = TextEditingController(text: '0');
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _plate.dispose();
    _km.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onActivate(
        normalizePlate(_plate.text),
        parseMileage(_km.text)!,
        _password.text,
      );
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          eyebrow: 'ACTIVARE VEHICUL',
          title: 'Gata de drum.',
          subtitle: 'Activează acest dispozitiv pentru autoutilitara ta.',
        ),
        if (widget.notice != null) ErrorNote(widget.notice),
        SectionCard(
          child: Form(
            key: _form,
            child: Column(
              children: [
                AbsorbPointer(
                  absorbing: _busy,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _plate,
                        validator: plateError,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Număr de înmatriculare',
                          prefixIcon: Icon(Icons.directions_car_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      NumberField(
                        controller: _km,
                        label: 'Kilometraj inițial',
                        unit: 'km',
                        icon: Icons.speed_outlined,
                        validator: (v) => mileageError(v),
                      ),
                      const SizedBox(height: 20),
                      PasswordField(
                        controller: _password,
                        onSubmitted: (_) => _activate(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Parola este verificată de server și nu este salvată pe dispozitiv. Reactivarea păstrează kilometrajul și istoricul, dar înlocuiește tokenul anterior.',
                  style: TextStyle(color: muted, height: 1.5),
                ),
                const SizedBox(height: 20),
                ErrorNote(_error),
                ActionButton(
                  label: 'Activează',
                  onPressed: _activate,
                  busy: _busy,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({
    super.key,
    required this.message,
    this.onRetry,
    this.onSignOut,
  });
  final String message;
  final Future<void> Function()? onRetry;
  final Future<void> Function()? onSignOut;
  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  bool _busy = false;
  String? _error;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    child: SectionCard(
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: muted, size: 36),
          const SizedBox(height: 20),
          Text(widget.message),
          const SizedBox(height: 20),
          ErrorNote(_error),
          if (widget.onRetry != null)
            ActionButton(
              label: 'Reîncearcă',
              onPressed: () => _run(widget.onRetry!),
              busy: _busy,
            ),
          if (widget.onSignOut != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Deconectarea șterge doar sesiunea locală. Tokenul de pe server nu este revocat.',
              style: TextStyle(color: muted),
            ),
            TextButton(
              onPressed: _busy ? null : () => _run(widget.onSignOut!),
              child: const Text('Deconectare locală'),
            ),
          ],
        ],
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.van,
    required this.onRefreshVan,
    required this.onHistory,
    required this.onSubmit,
    required this.onChangePlate,
    required this.onSignOut,
  });
  final Van van;
  final Future<Van> Function() onRefreshVan;
  final Future<List<FuelEntry>> Function(int month, int year) onHistory;
  final Future<FuelEntry> Function(FuelDraft) onSubmit;
  final Future<void> Function(String, String) onChangePlate;
  final Future<void> Function() onSignOut;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _form = GlobalKey<FormState>();
  final _km = TextEditingController();
  final _litres = TextEditingController();
  final _price = TextEditingController();
  DateTime _date = DateTime.now();
  late int _month;
  late int _year;
  bool _busy = false;
  bool _refreshing = false;
  bool _mustRefresh = false;
  List<FuelEntry>? _entries;
  String? _error;
  String? _historyError;
  String? _refreshError;
  String? _notice;
  bool get _locked => _busy || _refreshing;
  @override
  void initState() {
    super.initState();
    final now = bucharestTime(DateTime.now());
    _month = now.month;
    _year = now.year.clamp(2000, 2100);
    _history();
  }

  @override
  void dispose() {
    _km.dispose();
    _litres.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _history() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _historyError = null;
      _entries = null;
    });
    try {
      final entries = await widget.onHistory(_month, _year);
      if (mounted) setState(() => _entries = entries);
    } catch (error) {
      if (mounted) setState(() => _historyError = errorMessage(error));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _refreshAll() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _refreshError = null;
      _historyError = null;
    });
    // Refresh both independently: one failed read must not suppress the other.
    Object? failure;
    try {
      await widget.onRefreshVan();
    } catch (error) {
      failure = error;
    }
    if (!mounted) return;
    try {
      final entries = await widget.onHistory(_month, _year);
      if (mounted) setState(() => _entries = entries);
    } catch (error) {
      failure ??= error;
      if (mounted) setState(() => _historyError = errorMessage(error));
    }
    if (mounted) {
      setState(() {
        _refreshing = false;
        if (failure == null) {
          _mustRefresh = false;
        } else {
          _refreshError =
              'Datele nu au putut fi actualizate. ${errorMessage(failure)}';
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_locked || _mustRefresh || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final draft = FuelDraft(
      currentKms: parseMileage(_km.text)!,
      litres: parseDecimal(_litres.text)!,
      pricePerLitre: parseDecimal(_price.text)!,
      fuelDate: _date,
    );
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await widget.onSubmit(draft);
      if (!mounted) return;
      _form.currentState!.reset();
      _km.clear();
      _litres.clear();
      _price.clear();
      setState(() {
        _date = DateTime.now();
        _mustRefresh = true;
        _notice = 'Alimentarea a fost salvată pe server.';
      });
      await _refreshAll();
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    if (_locked) return;
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time != null && mounted) {
      setState(
        () => _date = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _plate() async {
    if (_locked) return;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PlateChangeDialog(
        plate: widget.van.licensePlate,
        onSave: widget.onChangePlate,
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      setState(() => _busy = true);
      await _refreshAll();
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _signOut() async {
    if (_locked) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deconectare locală'),
        content: const Text(
          'Sesiunea va fi ștearsă de pe acest dispozitiv. Tokenul de pe server nu este revocat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deconectează'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onSignOut();
    } catch (error) {
      if (mounted) setState(() => _error = errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    actions: [
      IconButton(
        tooltip: 'Modifică numărul de înmatriculare',
        onPressed: _locked ? null : _plate,
        icon: const Icon(Icons.edit_outlined),
      ),
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
              const Text(
                'AUTOUTILITARA TA',
                style: TextStyle(color: Color(0xFFB7C9D4), letterSpacing: 1.6),
              ),
              const SizedBox(height: 16),
              Text(
                widget.van.licensePlate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kilometraj actual  ·  ${widget.van.lastKms} km',
                style: const TextStyle(color: Color(0xFFB7C9D4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(_notice!, style: const TextStyle(color: teal)),
          ),
        ErrorNote(_refreshError),
        if (_mustRefresh)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ActionButton(
              label: 'Reîmprospătează datele',
              onPressed: _refreshAll,
              busy: _locked,
              icon: Icons.refresh,
            ),
          ),
        SectionCard(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Înregistrează o alimentare',
                  style: TextStyle(
                    color: ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                AbsorbPointer(
                  absorbing: _locked || _mustRefresh,
                  child: Column(
                    children: [
                      NumberField(
                        controller: _km,
                        label: 'Kilometraj actual',
                        unit: 'km',
                        icon: Icons.speed_outlined,
                        validator: (v) =>
                            mileageError(v, lastKms: widget.van.lastKms),
                      ),
                      const SizedBox(height: 20),
                      NumberField(
                        controller: _litres,
                        label: 'Combustibil alimentat',
                        unit: 'L',
                        icon: Icons.local_gas_station_outlined,
                        validator: (v) => decimalError(v, maximum: 9999999.999),
                      ),
                      const SizedBox(height: 20),
                      NumberField(
                        controller: _price,
                        label: 'Preț pe litru',
                        unit: '',
                        icon: Icons.payments_outlined,
                        validator: (v) => decimalError(v, maximum: 99999.999),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined, color: teal),
                        title: const Text('Data și ora alimentării'),
                        subtitle: Text(
                          '${dateLabel(context, _date)} (ora dispozitivului)',
                        ),
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ErrorNote(_error),
                ActionButton(
                  label: 'Trimite datele',
                  onPressed: _submit,
                  busy: _locked,
                  enabled: !_mustRefresh,
                  icon: Icons.send_outlined,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Istoric alimentări',
                style: TextStyle(
                  fontSize: 21,
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lunile sunt grupate după ora Europe/Bucharest. Datele sunt afișate în ora dispozitivului.',
                style: TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('month-$_month'),
                      initialValue: _month,
                      decoration: const InputDecoration(labelText: 'Lună'),
                      isExpanded: true,
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(value: m, child: Text('$m')),
                      ],
                      onChanged: _locked
                          ? null
                          : (m) {
                              setState(() => _month = m!);
                              _history();
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('year-$_year'),
                      initialValue: _year,
                      decoration: const InputDecoration(labelText: 'An'),
                      isExpanded: true,
                      items: [
                        for (var y = 2000; y <= 2100; y++)
                          DropdownMenuItem(value: y, child: Text('$y')),
                      ],
                      onChanged: _locked
                          ? null
                          : (y) {
                              setState(() => _year = y!);
                              _history();
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _locked ? null : _refreshAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Reîmprospătează istoricul'),
              ),
              if (_refreshing)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ErrorNote(_historyError),
              if (!_refreshing &&
                  _historyError == null &&
                  _entries?.isEmpty == true)
                const Text('Nu există alimentări în luna selectată.'),
              if (!_refreshing && _historyError == null && _entries != null)
                for (final entry in _entries!)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel(context, entry.fuelDate),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${entry.currentKms} km · ${numberLabel(entry.litres)} L · ${numberLabel(entry.pricePerLitre)} / L',
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: _locked ? null : _signOut,
            icon: const Icon(Icons.logout),
            label: const Text('Deconectare locală'),
          ),
        ),
      ],
    ),
  );
}

class PlateChangeDialog extends StatefulWidget {
  const PlateChangeDialog({
    super.key,
    required this.plate,
    required this.onSave,
  });
  final String plate;
  final Future<void> Function(String, String) onSave;
  @override
  State<PlateChangeDialog> createState() => _PlateChangeDialogState();
}

class _PlateChangeDialogState extends State<PlateChangeDialog> {
  final _form = GlobalKey<FormState>();
  late final _plate = TextEditingController(text: widget.plate);
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _plate.dispose();
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
      await widget.onSave(normalizePlate(_plate.text), _password.text);
      await _close(true);
    } catch (error) {
      if (error is ApiException && error.invalidDeviceToken) {
        await _close(false);
      } else if (mounted) {
        setState(() => _error = errorMessage(error));
      }
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _close(bool result) async {
    if (!mounted) return;
    setState(() => _busy = false);
    // Rebuild the back-navigation guard before closing an accepted operation.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Modifică numărul de înmatriculare'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AbsorbPointer(
                  absorbing: _busy,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _plate,
                        validator: plateError,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Număr nou',
                        ),
                      ),
                      const SizedBox(height: 20),
                      PasswordField(
                        controller: _password,
                        onSubmitted: (_) => _save(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ErrorNote(_error),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Anulează'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Se salvează…' : 'Salvează numărul'),
        ),
      ],
    ),
  );
}
