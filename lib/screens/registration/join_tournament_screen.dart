import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../home/home_screen.dart' show BulletText;
import '../payment/payment_screen.dart';

/// Step 4 — register for the active tournament (jersey number & name, accept rules).
class JoinTournamentScreen extends StatefulWidget {
  const JoinTournamentScreen({super.key});

  @override
  State<JoinTournamentScreen> createState() => _JoinTournamentScreenState();
}

class _JoinTournamentScreenState extends State<JoinTournamentScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _number;
  late final TextEditingController _name;
  bool _agree = false;
  bool _busy = false;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    final r = context.read<Session>().registration;
    _number = TextEditingController(text: r?.jerseyNumber ?? '');
    _name = TextEditingController(text: r?.jerseyName ?? '');
    _agree = r != null;
  }

  @override
  void dispose() {
    _number.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = ApiException('Please accept the tournament rules.'));
      return;
    }
    final session = context.read<Session>();
    final existing = session.registration;
    setState(() => _busy = true);
    try {
      if (existing == null) {
        await session.api.joinTournament(_number.text.trim(), _name.text.trim());
      } else {
        await session.api.updateRegistration(_number.text.trim(), _name.text.trim());
      }
      await session.refresh();
      if (!mounted) return;
      showSnack(context, existing == null ? 'Registered! Now complete the payment.' : 'Jersey details updated.');
      final r = session.registration;
      if (existing == null && r != null && r.canSubmitPayment) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PaymentScreen()));
      } else {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      setState(() => _error = e);
      _form.currentState!.validate();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final t = session.tournament;
    final r = session.registration;
    final locked = r?.isCompleted ?? false;

    if (t == null) {
      return Scaffold(appBar: AppBar(title: const Text('Tournament')), body: const Center(child: Text('No active tournament.')));
    }
    return Scaffold(
      appBar: AppBar(title: Text(r == null ? 'Register for tournament' : 'My registration')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.pitchDeep, AppColors.pitch]), borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.season.toUpperCase(), style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 12)),
              Text(t.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const Gap(6),
              Text('Registration fee: ${rupees(r?.feeAmount ?? t.fee)}', style: const TextStyle(color: Colors.white)),
              if (t.endDate != null) Text('Last date: ${fmtDate(t.endDate)}', style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          if (_error != null && _error!.errors.keys.every((k) => k != 'jersey_number' && k != 'jersey_name')) Banner2(message: _error!.message),
          SectionCard(
            title: 'Jersey details',
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 110,
                child: TextFormField(
                  controller: _number,
                  enabled: !locked,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Number', counterText: '', prefixText: '#'),
                  validator: (v) => (v ?? '').isEmpty ? 'Required' : _error?.fieldError('jersey_number'),
                ),
              ),
              const Gap(10),
              Expanded(
                child: TextFormField(
                  controller: _name,
                  enabled: !locked,
                  maxLength: 15,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z .]'))],
                  decoration: const InputDecoration(labelText: 'Name on jersey', counterText: ''),
                  validator: (v) => (v ?? '').trim().length < 2 ? 'Min 2 letters' : _error?.fieldError('jersey_name'),
                ),
              ),
            ]),
          ),
          if ((t.rules ?? '').isNotEmpty) SectionCard(title: 'Tournament rules', child: BulletText(t.rules!)),
          if ((t.instructions ?? '').isNotEmpty) SectionCard(title: 'Registration instructions', child: BulletText(t.instructions!)),
          if (!locked) ...[
            CheckboxListTile(
              value: _agree,
              onChanged: r != null ? null : (v) => setState(() => _agree = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('I confirm my details are correct and I accept the tournament rules.'),
            ),
            FilledButton(
              onPressed: _busy || (r == null && !t.isOpen) ? null : _submit,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Text(r == null ? (t.isOpen ? 'Submit registration' : (t.closedReason ?? 'Registration closed')) : 'Save jersey details'),
            ),
          ],
        ]),
      ),
    );
  }
}
