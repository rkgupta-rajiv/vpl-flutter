import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/models.dart';
import '../../models/options.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_image.dart';
import '../../widgets/common.dart';
import '../confirmation/confirmation_screen.dart';
import '../documents/documents_screen.dart';
import '../notifications/notifications_screen.dart';
import '../payment/payment_screen.dart';
import '../profile/change_password_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../registration/join_tournament_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _open(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (context.mounted) context.read<Session>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final d = session.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _open(context, const NotificationsScreen()),
            icon: Badge(
              isLabelVisible: (d?.unreadNotifications ?? 0) > 0,
              label: Text('${d?.unreadNotifications ?? 0}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'profile') _open(context, const EditProfileScreen());
              if (v == 'password') _open(context, const ChangePasswordScreen());
              if (v == 'logout') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Log out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Log out')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  AuthImage.clearCache();
                  await context.read<Session>().logout();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit profile'))),
              PopupMenuItem(value: 'password', child: ListTile(leading: Icon(Icons.key_outlined), title: Text('Change password'))),
              PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Log out'))),
            ],
          ),
        ],
      ),
      body: d == null
          ? _ErrorState(message: session.loadError ?? 'Loading…', onRetry: session.refresh)
          : RefreshIndicator(
              onRefresh: session.refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (session.loadError != null) Banner2(message: session.loadError!, icon: Icons.wifi_off, color: AppColors.warning),
                  _ProfileHeader(d: d),
                  const Gap(14),
                  _NextStep(d: d, open: (w) => _open(context, w)),
                  _StatusTiles(d: d),
                  const Gap(14),
                  _Progress(d: d, open: (w) => _open(context, w)),
                  SectionCard(
                    title: 'Personal information',
                    trailing: TextButton(onPressed: () => _open(context, const EditProfileScreen()), child: const Text('Edit')),
                    child: Column(children: [
                      InfoRow('Name', d.player.fullName),
                      InfoRow('Age', d.player.age?.toString()),
                      InfoRow('Gender', Options.label(Options.genders, d.player.gender)),
                      InfoRow('Mobile', d.player.mobile),
                      InfoRow('Email', d.player.email),
                      InfoRow('Village', d.player.village),
                    ]),
                  ),
                  SectionCard(
                    title: 'Cricket information',
                    trailing: TextButton(onPressed: () => _open(context, const EditProfileScreen()), child: const Text('Edit')),
                    child: Column(children: [
                      InfoRow('Playing role', Options.label(Options.roles, d.player.playingRole)),
                      InfoRow('Batting style', Options.label(Options.batting, d.player.battingStyle)),
                      InfoRow('Bowling style', Options.label(Options.bowling, d.player.bowlingStyle)),
                      InfoRow('T-shirt size', d.player.tshirtSize),
                      InfoRow('Jersey number', d.registration?.jerseyNumber),
                      InfoRow('Jersey name', d.registration?.jerseyName),
                    ]),
                  ),
                  if (d.tournament != null) _TournamentCard(t: d.tournament!),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.d});
  final Dashboard d;

  @override
  Widget build(BuildContext context) {
    final photo = d.player.document('photo');
    final reg = d.registration;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.pitchDeep, AppColors.pitch]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 72,
            height: 72,
            child: photo != null
                ? AuthImage(photo.url)
                : Container(
                    color: Colors.white24,
                    alignment: Alignment.center,
                    child: Text(
                      (d.player.firstName.isNotEmpty ? d.player.firstName[0] : '') + (d.player.surname.isNotEmpty ? d.player.surname[0] : ''),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                  ),
          ),
        ),
        const Gap(14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.player.fullName, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            Text('${Options.label(Options.roles, d.player.playingRole)} · ${d.player.village ?? ''}', style: const TextStyle(color: Colors.white70)),
            if (reg?.registrationNo != null) ...[
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                child: Text('ID: ${reg!.registrationNo}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          ]),
        ),
        if (reg?.jerseyNumber != null)
          Column(children: [
            const Icon(Icons.checkroom, color: Colors.white54),
            Text('#${reg!.jerseyNumber}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ]),
      ]),
    );
  }
}

/// The single most important call-to-action for the player right now.
class _NextStep extends StatelessWidget {
  const _NextStep({required this.d, required this.open});
  final Dashboard d;
  final void Function(Widget) open;

  @override
  Widget build(BuildContext context) {
    final p = d.player;
    final r = d.registration;
    final t = d.tournament;

    if (t == null) {
      return const Banner2(title: 'No active tournament', message: 'Registration is not open right now. Please check back later.', color: AppColors.info, icon: Icons.info_outline);
    }
    if (r != null && r.isCompleted) {
      return _cta(context, Icons.verified, AppColors.success, 'Registration confirmed 🎉',
          'Your payment is verified. Registration ID ${r.registrationNo}.', 'View confirmation', () => open(const ConfirmationScreen()));
    }
    if (r != null && r.isRejected) {
      return Banner2(
        title: 'Registration rejected',
        message: '${r.rejectionRemarks ?? 'Please correct your details.'}\nFix the issue (details or documents) and resubmit.',
        action: Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)), onPressed: () => open(const EditProfileScreen()), child: const Text('Edit details')),
          OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)), onPressed: () => open(const DocumentsScreen()), child: const Text('Documents')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () async {
              final session = context.read<Session>();
              final ok = await runWithProgress(context, () => session.api.resubmit(), success: 'Resubmitted for review.');
              if (ok != null) session.refresh();
            },
            child: const Text('Resubmit'),
          ),
        ]),
      );
    }
    if (!p.profileComplete) {
      return _cta(context, Icons.sports_cricket, AppColors.pitch, 'Step 2 · Cricket details', 'Tell us your playing role, batting & bowling style and T-shirt size.',
          'Add cricket details', () => open(const EditProfileScreen()));
    }
    if (!p.documentsComplete) {
      return _cta(context, Icons.upload_file, AppColors.pitch, 'Step 3 · Upload documents', 'Profile photo and both sides of your Aadhaar card are required.',
          'Upload documents', () => open(const DocumentsScreen()));
    }
    if (r == null) {
      if (!t.isOpen) {
        return Banner2(title: 'Registration closed', message: t.closedReason ?? 'Registration is closed.', color: AppColors.warning, icon: Icons.lock_clock);
      }
      return _cta(context, Icons.emoji_events_outlined, AppColors.pitch, 'Step 4 · Register for ${t.season}', 'Choose your jersey number & name and accept the rules.',
          'Register for tournament', () => open(const JoinTournamentScreen()));
    }
    if (r.canSubmitPayment) {
      final rejected = r.paymentStatus == 'payment_rejected';
      return _cta(
        context,
        rejected ? Icons.error_outline : Icons.qr_code_2,
        rejected ? AppColors.danger : AppColors.gold,
        rejected ? 'Payment proof rejected' : 'Step 5 · Pay registration fee',
        rejected ? (r.latestPayment?.adminRemarks ?? 'Please submit the payment proof again.') : 'Scan the QR code, pay ${rupees(r.feeAmount)} and upload the payment screenshot.',
        rejected ? 'Submit payment proof again' : 'Pay ${rupees(r.feeAmount)} now',
        () => open(const PaymentScreen()),
      );
    }
    if (r.paymentInReview) {
      return _cta(context, Icons.hourglass_top, AppColors.info, 'Payment under verification',
          'We received your payment proof. The organiser will verify it soon — your registration is not confirmed until then.', 'View payment', () => open(const PaymentScreen()));
    }
    return const SizedBox.shrink();
  }

  Widget _cta(BuildContext context, IconData icon, Color color, String title, String text, String button, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(.5), width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)),
          const Gap(12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
        ]),
        const Gap(8),
        Text(text, style: const TextStyle(color: AppColors.muted)),
        const Gap(12),
        FilledButton(onPressed: onTap, child: Text(button)),
      ]),
    );
  }
}

class _StatusTiles extends StatelessWidget {
  const _StatusTiles({required this.d});
  final Dashboard d;

  @override
  Widget build(BuildContext context) {
    final r = d.registration;
    Widget tile(String label, String status, String text) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
              const Gap(6),
              StatusChip(status, label: text),
            ]),
          ),
        );
    return Row(children: [
      tile('Registration', r == null ? 'not_started' : (r.isCompleted ? 'completed' : r.status), r == null ? 'Not started' : (r.isCompleted ? 'Completed' : r.statusLabel)),
      const Gap(8),
      tile('Documents', d.player.documentStatus, humanize(d.player.documentStatus)),
      const Gap(8),
      tile('Payment', r?.paymentStatus ?? 'payment_pending', r?.paymentStatusLabel ?? 'Pending'),
    ]);
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.d, required this.open});
  final Dashboard d;
  final void Function(Widget) open;

  @override
  Widget build(BuildContext context) {
    final p = d.player;
    final r = d.registration;
    final steps = <(String, bool, Widget?)>[
      ('Account created', true, null),
      ('Cricket details', p.profileComplete, const EditProfileScreen()),
      ('Documents uploaded', p.documentsComplete, const DocumentsScreen()),
      ('Tournament registration', r != null, r != null || (d.tournament?.isOpen ?? false) ? const JoinTournamentScreen() : null),
      ('Payment proof submitted', r != null && r.paymentStatus != 'payment_pending' && r.paymentStatus != 'payment_rejected', r != null ? const PaymentScreen() : null),
      ('Payment verified & registration completed', r?.isCompleted ?? false, (r?.isCompleted ?? false) ? const ConfirmationScreen() : null),
    ];
    return SectionCard(
      title: 'Registration progress',
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: steps[i].$2 ? AppColors.success : const Color(0xFFE2E8F0),
                child: steps[i].$2 ? const Icon(Icons.check, size: 16, color: Colors.white) : Text('${i + 1}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ),
              title: Text(steps[i].$1, style: TextStyle(fontWeight: FontWeight.w600, color: steps[i].$2 ? AppColors.text : AppColors.muted)),
              trailing: steps[i].$3 == null ? null : const Icon(Icons.chevron_right),
              onTap: steps[i].$3 == null ? null : () => open(steps[i].$3!),
            ),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  const _TournamentCard({required this.t});
  final Tournament t;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: t.title,
      trailing: StatusChip(t.isOpen ? 'approved' : 'rejected', label: t.isOpen ? 'Open' : 'Closed'),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if ((t.description ?? '').isNotEmpty) Text(t.description!),
        const Gap(8),
        InfoRow('Registration', '${fmtDate(t.startDate)} → ${fmtDate(t.endDate)}'),
        InfoRow('Fee', rupees(t.fee)),
        if ((t.rules ?? '').isNotEmpty)
          ExpansionTile(tilePadding: EdgeInsets.zero, title: const Text('Tournament rules', style: TextStyle(fontWeight: FontWeight.w700)), children: [BulletText(t.rules!)]),
        if ((t.instructions ?? '').isNotEmpty)
          ExpansionTile(tilePadding: EdgeInsets.zero, title: const Text('Registration instructions', style: TextStyle(fontWeight: FontWeight.w700)), children: [BulletText(t.instructions!)]),
      ]),
    );
  }
}

/// Renders multi-line admin text as bullet points.
class BulletText extends StatelessWidget {
  const BulletText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
          .map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(top: 7, right: 8), child: CircleAvatar(radius: 3, backgroundColor: AppColors.pitch)),
                  Expanded(child: Text(l)),
                ]),
              ))
          .toList(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off, size: 48, color: AppColors.muted),
          const Gap(12),
          Text(message, textAlign: TextAlign.center),
          const Gap(12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      ),
    );
  }
}
