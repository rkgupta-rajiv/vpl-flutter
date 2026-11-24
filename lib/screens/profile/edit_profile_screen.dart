import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../models/options.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';

/// Edit personal + cricket information (players can only edit their own profile).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  String? _gender, _role, _batting, _bowling, _tshirt;
  bool _busy = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final p = context.read<Session>().player!;
    _c = {
      'first_name': TextEditingController(text: p.firstName),
      'surname': TextEditingController(text: p.surname),
      'age': TextEditingController(text: p.age?.toString() ?? ''),
      'mobile': TextEditingController(text: p.mobile),
      'email': TextEditingController(text: p.email),
      'village': TextEditingController(text: p.village ?? ''),
    };
    _gender = p.gender;
    _role = p.playingRole;
    _batting = p.battingStyle;
    _bowling = p.bowlingStyle;
    _tshirt = p.tshirtSize;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final missing = [if (_gender == null) 'gender', if (_role == null) 'playing role', if (_batting == null) 'batting style', if (_bowling == null) 'bowling style', if (_tshirt == null) 'T-shirt size'];
    if (missing.isNotEmpty) {
      setState(() => _error = ApiException('Please select ${missing.join(', ')}.'));
      return;
    }
    setState(() => _busy = true);
    final session = context.read<Session>();
    try {
      await session.api.updateProfile({
        'first_name': _c['first_name']!.text.trim(),
        'surname': _c['surname']!.text.trim(),
        'age': int.tryParse(_c['age']!.text.trim()),
        'mobile': _c['mobile']!.text.trim(),
        'email': _c['email']!.text.trim(),
        'village': _c['village']!.text.trim(),
        'gender': _gender,
        'playing_role': _role,
        'batting_style': _batting,
        'bowling_style': _bowling,
        'tshirt_size': _tshirt,
      });
      await session.refresh();
      if (mounted) {
        showSnack(context, 'Profile saved.');
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      setState(() => _error = e);
      _form.currentState!.validate();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _text(String key, String label, {TextInputType? type, List<TextInputFormatter>? fmt, int? maxLength}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _c[key],
          keyboardType: type,
          inputFormatters: fmt,
          maxLength: maxLength,
          textCapitalization: type == null ? TextCapitalization.words : TextCapitalization.none,
          decoration: InputDecoration(labelText: label, counterText: ''),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : _error?.fieldError(key),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_error != null) Banner2(message: _error!.message),
          SectionCard(
            title: 'Personal information',
            child: Column(children: [
              Row(children: [Expanded(child: _text('first_name', 'First name')), const Gap(10), Expanded(child: _text('surname', 'Surname'))]),
              Row(children: [
                SizedBox(width: 100, child: _text('age', 'Age', type: TextInputType.number, fmt: [FilteringTextInputFormatter.digitsOnly], maxLength: 2)),
                const Gap(10),
                Expanded(child: _text('mobile', 'Mobile', type: TextInputType.phone, fmt: [FilteringTextInputFormatter.digitsOnly], maxLength: 10)),
              ]),
              _text('email', 'Email', type: TextInputType.emailAddress),
              _text('village', 'Village name'),
              ChoiceField(label: 'Gender', options: Options.genders, value: _gender, onChanged: (v) => setState(() => _gender = v)),
            ]),
          ),
          SectionCard(
            title: 'Cricket information',
            child: Column(children: [
              ChoiceField(label: 'Playing role', options: Options.roles, value: _role, onChanged: (v) => setState(() => _role = v)),
              ChoiceField(label: 'Batting style', options: Options.batting, value: _batting, onChanged: (v) => setState(() => _batting = v)),
              ChoiceField(label: 'Bowling style', options: Options.bowling, value: _bowling, onChanged: (v) => setState(() => _bowling = v)),
              ChoiceField(label: 'T-shirt size', options: Options.tshirt, value: _tshirt, onChanged: (v) => setState(() => _tshirt = v)),
            ]),
          ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Save profile'),
          ),
        ]),
      ),
    );
  }
}
