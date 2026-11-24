import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/options.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';

/// Step 1 — create account with personal information.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _c = {for (final k in ['first_name', 'surname', 'age', 'mobile', 'email', 'village', 'password', 'password_confirmation']) k: TextEditingController()};
  String? _gender;
  bool _busy = false;
  bool _obscure = true;
  ApiException? _error;

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _server(String f) => _error?.fieldError(f);

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate() || _gender == null) {
      if (_gender == null) setState(() => _error = ApiException('Please select gender.', errors: {'gender': ['Please select gender.']}));
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<Session>().register({
        for (final e in _c.entries) e.key: e.value.text.trim(),
        'age': int.tryParse(_c['age']!.text.trim()),
        'gender': _gender,
      });
      // _Root switches to HomeScreen and pops this route.
    } on ApiException catch (e) {
      setState(() => _error = e);
      _form.currentState!.validate();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String key, String label, {TextInputType? type, List<TextInputFormatter>? fmt, String? Function(String)? validate, bool password = false, IconData? icon, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _c[key],
        keyboardType: type,
        inputFormatters: fmt,
        obscureText: password && _obscure,
        maxLength: maxLength,
        textCapitalization: (type == null && !password) ? TextCapitalization.words : TextCapitalization.none,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: label, prefixIcon: icon == null ? null : Icon(icon), counterText: ''),
        validator: (v) {
          final value = (v ?? '').trim();
          if (value.isEmpty) return 'Required';
          final local = validate?.call(value);
          return local ?? _server(key);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create player account')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null && _error!.errors.isEmpty) Banner2(message: _error!.message),
            SectionCard(
              title: 'Personal information',
              child: Column(children: [
                Row(children: [
                  Expanded(child: _field('first_name', 'First name', icon: Icons.badge_outlined)),
                  const Gap(10),
                  Expanded(child: _field('surname', 'Surname')),
                ]),
                Row(children: [
                  SizedBox(
                    width: 110,
                    child: _field('age', 'Age', type: TextInputType.number, fmt: [FilteringTextInputFormatter.digitsOnly], maxLength: 2, validate: (v) {
                      final a = int.tryParse(v) ?? 0;
                      return (a < 10 || a > 80) ? '10–80' : null;
                    }),
                  ),
                  const Gap(10),
                  Expanded(
                    child: _field('mobile', 'Mobile number', type: TextInputType.phone, icon: Icons.phone_android, maxLength: 10, fmt: [FilteringTextInputFormatter.digitsOnly],
                        validate: (v) => RegExp(r'^[6-9]\d{9}$').hasMatch(v) ? null : 'Enter valid 10-digit mobile'),
                  ),
                ]),
                _field('email', 'Email address', type: TextInputType.emailAddress, icon: Icons.alternate_email,
                    validate: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v) ? null : 'Enter a valid email'),
                _field('village', 'Village name', icon: Icons.location_on_outlined),
                ChoiceField(label: 'Gender', options: Options.genders, value: _gender, onChanged: (v) => setState(() => _gender = v), errorText: _server('gender')),
              ]),
            ),
            SectionCard(
              title: 'Password',
              trailing: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure)),
              child: Column(children: [
                _field('password', 'Password (min 8, letters + numbers)', password: true, type: TextInputType.visiblePassword, icon: Icons.lock_outline,
                    validate: (v) => (v.length < 8 || !RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) ? 'Min 8 chars with letters and numbers' : null),
                _field('password_confirmation', 'Confirm password', password: true, type: TextInputType.visiblePassword, icon: Icons.lock_outline,
                    validate: (v) => v != _c['password']!.text ? 'Passwords do not match' : null),
              ]),
            ),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Create account'),
            ),
            const Gap(8),
            const Text('Next: cricket details → documents → payment', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const Gap(24),
          ],
        ),
      ),
    );
  }
}
