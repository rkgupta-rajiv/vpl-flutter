import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  Future<Tournament?>? _tournament;

  @override
  void initState() {
    super.initState();
    _tournament = context.read<Session>().api.tournament().catchError((_) => null);
  }

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<Session>().login(_login.text.trim(), _password.text);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(children: [
          _Hero(future: _tournament),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('Player Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const Text('Use your email, mobile number or full name.', style: TextStyle(color: AppColors.muted)),
                  const Gap(18),
                  if (_error != null) Banner2(message: _error!),
                  TextFormField(
                    controller: _login,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Email / Mobile / Name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const Gap(14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Log in'),
                  ),
                  const Gap(14),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    icon: const Icon(Icons.how_to_reg_outlined),
                    label: const Text('New player? Create account'),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.future});

  final Future<Tournament?>? future;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 28, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.pitchDeep, AppColors.pitch], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: FutureBuilder<Tournament?>(
        future: future,
        builder: (context, snap) {
          final t = snap.data;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Image(image: AssetImage('assets/images/logo.png'), width: 88, height: 88),
            const Gap(16),
            Text(t?.season.toUpperCase() ?? 'CRICKET TOURNAMENT', style: const TextStyle(color: AppColors.gold, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.w700)),
            const Gap(4),
            Text(t?.name ?? 'Player Registration', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            if (t != null) ...[
              const Gap(10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _pill(t.isOpen ? 'Registration open' : (t.closedReason ?? 'Registration closed'), t.isOpen ? AppColors.gold : Colors.white24, t.isOpen ? Colors.black : Colors.white),
                if (t.endDate != null) _pill('Last date ${fmtDate(t.endDate)}', Colors.white12, Colors.white),
                if (t.fee > 0) _pill('Fee ${rupees(t.fee)}', Colors.white12, Colors.white),
              ]),
            ],
          ]);
        },
      ),
    );
  }

  Widget _pill(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}
