import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/api_exception.dart';
import '../../core/formatters.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_image.dart';
import '../../widgets/common.dart';
import '../home/home_screen.dart' show BulletText;

/// Payment page: admin QR + UPI ID + locked fee, then payment-proof upload.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Future<PaymentPage> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<Session>().api.paymentPage();
  }

  Future<void> _reload() async {
    final f = context.read<Session>().api.paymentPage();
    setState(() => _future = f);
    await f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration payment')),
      body: FutureBuilder<PaymentPage>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(snap.error.toString(), textAlign: TextAlign.center),
                  const Gap(12),
                  OutlinedButton(onPressed: _reload, child: const Text('Retry')),
                ]),
              ),
            );
          }
          final p = snap.data!;
          final latest = p.history.isNotEmpty ? p.history.first : null;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              _Summary(p: p),
              if (p.paymentStatus == 'payment_approved')
                const Banner2(title: 'Payment approved', message: 'Your payment is verified and your registration is confirmed.', color: AppColors.success, icon: Icons.verified),
              if (p.paymentStatus == 'proof_submitted' || p.paymentStatus == 'under_verification')
                const Banner2(
                    title: 'Waiting for admin verification',
                    message: 'Payment proof received. Submitting proof does not mean payment is successful — the organiser will verify it with the bank. You will be notified.',
                    color: AppColors.info,
                    icon: Icons.hourglass_top),
              if (p.paymentStatus == 'payment_rejected' && latest != null)
                Banner2(title: 'Payment proof rejected', message: '${latest.adminRemarks ?? ''}\nPlease check and submit the payment proof again.'),
              if (p.canSubmit) ...[
                if (p.onlineEnabled) _PayCard(p: p) else Banner2(title: 'Online payment not available', message: p.instructions ?? 'Please pay the fee to the organiser directly.', color: AppColors.warning, icon: Icons.info_outline),
                if (p.onlineEnabled) _ProofForm(fee: p.fee, onSubmitted: () async {
                  await context.read<Session>().refresh();
                  await _reload();
                }),
              ],
              if (p.history.isNotEmpty) _History(history: p.history),
            ]),
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.p});
  final PaymentPage p;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Payment summary',
      trailing: StatusChip(p.paymentStatus, label: p.paymentStatusLabel),
      child: Column(children: [
        InfoRow('Tournament', p.tournamentName),
        InfoRow('Player', p.playerName),
        const Divider(),
        Row(children: [
          const Expanded(child: Text('Registration fee', style: TextStyle(fontWeight: FontWeight.w600))),
          Text(rupees(p.fee), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.pitch)),
        ]),
      ]),
    );
  }
}

class _PayCard extends StatelessWidget {
  const _PayCard({required this.p});
  final PaymentPage p;

  /// upi://pay deep link so the player can pay with one tap on Android/iOS.
  Uri? get _upiUri {
    if (p.upiId == null) return null;
    final note = 'Registration ${p.playerName}';
    final tn = note.length > 50 ? note.substring(0, 50) : note;
    return Uri.parse('upi://pay?pa=${p.upiId}'
        '&pn=${Uri.encodeComponent(p.payeeName ?? 'Tournament')}'
        '&am=${p.fee.toStringAsFixed(2)}&cu=INR'
        '&tn=${Uri.encodeComponent(tn)}');
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '1 · Scan & pay',
      child: Column(children: [
        if (p.qrCodeUrl != null)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(16)),
            child: Image.network(p.qrCodeUrl!, width: 230, height: 230, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(width: 230, height: 120, child: Center(child: Text('QR could not be loaded')))),
          )
        else
          const Text('QR code not uploaded yet — use the UPI ID below.', style: TextStyle(color: AppColors.muted)),
        const Gap(12),
        if (p.upiId != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.pitch),
              const Gap(8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('UPI ID', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  SelectableText(p.upiId!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  if (p.payeeName != null) Text(p.payeeName!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ]),
              ),
              IconButton(
                tooltip: 'Copy UPI ID',
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: p.upiId!));
                  showSnack(context, 'UPI ID copied');
                },
              ),
            ]),
          ),
        if (_upiUri != null && !kIsWeb) ...[
          const Gap(12),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new),
            label: Text('Pay ${rupees(p.fee)} with UPI app'),
            onPressed: () async {
              final ok = await launchUrl(_upiUri!, mode: LaunchMode.externalApplication);
              if (!ok && context.mounted) showSnack(context, 'No UPI app found. Please scan the QR from another phone or pay to the UPI ID.', error: true);
            },
          ),
        ],
        if ((p.instructions ?? '').isNotEmpty) ...[
          const Gap(12),
          Align(alignment: Alignment.centerLeft, child: BulletText(p.instructions!)),
        ],
      ]),
    );
  }
}

class _ProofForm extends StatefulWidget {
  const _ProofForm({required this.fee, required this.onSubmitted});
  final double fee;
  final Future<void> Function() onSubmitted;

  @override
  State<_ProofForm> createState() => _ProofFormState();
}

class _ProofFormState extends State<_ProofForm> {
  final _form = GlobalKey<FormState>();
  final _utr = TextEditingController();
  DateTime _date = DateTime.now();
  UploadFile? _shot;
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    _utr.dispose();
    super.dispose();
  }

  Future<void> _pickShot() async {
    final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() => _shot = UploadFile(bytes: bytes, filename: f.name.contains('.') ? f.name : '${f.name}.jpg'));
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (_shot == null) {
      setState(() => _error = ApiException('Please attach the payment screenshot.'));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Submit payment proof?'),
        content: Text('Amount: ${rupees(widget.fee)}\nUTR: ${_utr.text.trim().toUpperCase()}\nDate: ${fmtDate(_date)}\n\nPlease make sure the UTR is correct.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Edit')),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(0, 40)), onPressed: () => Navigator.pop(c, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final msg = await context.read<Session>().api.submitPayment(amount: widget.fee, transactionId: _utr.text, paymentDate: _date, screenshot: _shot!);
      if (!mounted) return;
      showSnack(context, msg);
      await widget.onSubmitted();
    } on ApiException catch (e) {
      setState(() => _error = e);
      _form.currentState!.validate();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '2 · Upload payment proof',
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_error != null) Banner2(message: _error!.message),
          TextFormField(
            initialValue: widget.fee.toStringAsFixed(2),
            enabled: false, // players cannot change the amount
            decoration: const InputDecoration(labelText: 'Payment amount (₹)', prefixIcon: Icon(Icons.currency_rupee)),
          ),
          const Gap(12),
          TextFormField(
            controller: _utr,
            textCapitalization: TextCapitalization.characters,
            maxLength: 35,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))],
            decoration: const InputDecoration(labelText: 'UPI Transaction ID / UTR number', helperText: 'Usually a 12-digit number shown in your UPI app', prefixIcon: Icon(Icons.tag)),
            validator: (v) => (v ?? '').trim().length < 6 ? 'Enter the transaction ID / UTR' : _error?.fieldError('transaction_id'),
          ),
          const Gap(4),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now().subtract(const Duration(days: 60)), lastDate: DateTime.now());
              if (d != null) setState(() => _date = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Payment date', prefixIcon: Icon(Icons.event)),
              child: Text(fmtDate(_date)),
            ),
          ),
          const Gap(12),
          InkWell(
            onTap: _pickShot,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: _shot == null ? 110 : 260,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: _shot == null
                  ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.pitch),
                      Gap(4),
                      Text('Attach payment screenshot', style: TextStyle(color: AppColors.pitch, fontWeight: FontWeight.w700)),
                    ])
                  : Image.memory(_shot!.bytes, fit: BoxFit.contain),
            ),
          ),
          if (_error?.fieldError('screenshot') != null) Text(_error!.fieldError('screenshot')!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          const Gap(16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Submit for verification'),
          ),
        ]),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History({required this.history});
  final List<Payment> history;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Payment history',
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        children: history
            .map((pay) => ExpansionTile(
                  title: Text('${rupees(pay.amount)} · ${pay.transactionId ?? pay.method.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Submitted ${fmtDateTime(pay.submittedAt)}'),
                  trailing: StatusChip(pay.status, label: pay.statusLabel),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    InfoRow('Payment date', fmtDate(pay.paymentDate)),
                    if (pay.adminRemarks != null) InfoRow('Admin remarks', pay.adminRemarks),
                    if (pay.screenshotUrl != null)
                      ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(height: 220, child: AuthImage(pay.screenshotUrl!, fit: BoxFit.contain))),
                  ],
                ))
            .toList(),
      ),
    );
  }
}
