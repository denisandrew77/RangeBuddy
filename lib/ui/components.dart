import 'package:flutter/material.dart';

const ink = Color(0xFF142C3C);
const teal = Color(0xFF087F75);
const muted = Color(0xFF667887);
const canvas = Color(0xFFF3F6F8);

String numberLabel(double value) => value == value.truncateToDouble()
    ? value.toStringAsFixed(0)
    : value.toString().replaceAll('.', ',');

double? parseNumber(String value) {
  final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
  return parsed != null && parsed.isFinite ? parsed : null;
}

String? numericError(String? value, {bool allowZero = false, double? minimum}) {
  final parsed = parseNumber(value ?? '');
  if (parsed == null) return 'Introdu un număr valid';
  if (allowZero ? parsed < 0 : parsed <= 0) {
    return allowZero
        ? 'Introdu o valoare de cel puțin 0'
        : 'Introdu o valoare mai mare decât 0';
  }
  if (minimum != null && parsed < minimum) {
    return 'Valoarea minimă este ${numberLabel(minimum)} km';
  }
  return null;
}

String? requiredText(String? value) => value == null || value.trim().isEmpty
    ? 'Acest câmp este obligatoriu'
    : null;

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.child,
    this.actions,
    this.back = false,
  });
  final Widget child;
  final List<Widget>? actions;
  final bool back;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: back,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: teal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'RangeBuddy',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ),
        ],
      ),
      actions: actions,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E9ED)),
    ),
    child: child,
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: teal,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      const SizedBox(height: 12),
      Text(
        title,
        style: const TextStyle(
          color: ink,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        subtitle,
        style: const TextStyle(color: muted, fontSize: 15, height: 1.5),
      ),
      const SizedBox(height: 28),
    ],
  );
}

class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.unit,
    required this.icon,
    this.allowZero = false,
    this.minimum,
    this.hint,
  });
  final TextEditingController controller;
  final String label;
  final String unit;
  final IconData icon;
  final bool allowZero;
  final double? minimum;
  final String? hint;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixText: unit.isEmpty ? null : unit,
    ),
    validator: (value) =>
        numericError(value, allowZero: allowZero, minimum: minimum),
  );
}

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, this.onSubmitted});
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: _hidden,
    enableSuggestions: false,
    autocorrect: false,
    validator: requiredText,
    onFieldSubmitted: widget.onSubmitted,
    decoration: InputDecoration(
      labelText: 'Parolă administrator',
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: _hidden ? 'Arată parola' : 'Ascunde parola',
        onPressed: () => setState(() => _hidden = !_hidden),
        icon: Icon(
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon = Icons.arrow_forward,
  });
  final String label;
  final VoidCallback onPressed;
  final bool busy;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 20),
      label: Text(busy ? 'Se procesează…' : label),
    ),
  );
}

class ErrorNote extends StatelessWidget {
  const ErrorNote(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            message!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              height: 1.4,
            ),
          ),
        );
}
