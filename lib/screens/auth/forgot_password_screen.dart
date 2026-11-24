import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../state/session.dart';
import '../../widgets/common.dart';

/// Forgot password → 6-digit OTP by email → reset password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_form.currentState!.validate()) return;
    final api = context.read<Session>().api;
    final msg = await runWithProgress(context, () => api.forgotPassword(_email.text.trim()));
    if (msg != null && mounted) {
      setState(() => _codeSent = true);
      showSnack(context, msg);
    }
  }

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    final api = context.read<Session>().api;
    final msg = await runWithProgress(context, () => api.resetPassword(_email.text.trim(), _otp.text.trim(), _password.text));
    if (msg != null && mounted) {
      showSnack(context, msg);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(_codeSent ? 'Enter the 6-digit code sent to your email and choose a new password.' : 'Enter your registered email. We will send you a 6-digit reset code.'),
          const Gap(16),
          TextFormField(
            controller: _email,
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Registered email', prefixIcon: Icon(Icons.alternate_email)),
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          if (_codeSent) ...[
            const Gap(14),
            TextFormField(
              controller: _otp,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: '6-digit code', prefixIcon: Icon(Icons.pin_outlined), counterText: ''),
              validator: (v) => (v == null || v.length != 6) ? 'Enter the 6-digit code' : null,
            ),
            const Gap(14),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password', prefixIcon: Icon(Icons.lock_outline)),
              validator: (v) => (v == null || v.length < 8 || !RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) ? 'Min 8 chars with letters and numbers' : null,
            ),
          ],
          const Gap(20),
          FilledButton(onPressed: _codeSent ? _reset : _sendCode, child: Text(_codeSent ? 'Reset password' : 'Send code')),
          if (_codeSent) TextButton(onPressed: () => setState(() => _codeSent = false), child: const Text('Use a different email / resend code')),
        ]),
      ),
    );
  }
}
