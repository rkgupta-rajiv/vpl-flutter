import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/models.dart';
import '../../models/options.dart';
import '../../services/confirmation_pdf.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_image.dart';
import '../../widgets/common.dart';

/// Registration confirmation "pass" + download / share as PDF.
class ConfirmationScreen extends StatefulWidget {
  const ConfirmationScreen({super.key});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  late final Future<Confirmation> _future = context.read<Session>().api.confirmation();

  Future<void> _download(Confirmation c) async {
    final session = context.read<Session>();
    await runWithProgress(context, () async {
      Uint8List? photo;
      try {
        if (c.photoUrl != null) photo = await session.client.bytes(c.photoUrl!);
      } catch (_) {
        photo = null; // PDF still works without the photo
      }
      final bytes = await buildConfirmationPdf(c, photo: photo);
      await Printing.sharePdf(bytes: bytes, filename: 'registration-${c.registrationNo}.pdf');
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration confirmed')),
      body: FutureBuilder<Confirmation>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(snap.error.toString())));
          final c = snap.data!;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8))]),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.pitchDeep, AppColors.pitch])),
                  child: Column(children: [
                    const Icon(Icons.verified, color: AppColors.gold, size: 44),
                    const Gap(6),
                    Text(c.tournament, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const Text('Registration Completed', style: TextStyle(color: Colors.white70)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(children: [
                    if (c.photoUrl != null)
                      ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(width: 96, height: 110, child: AuthImage(c.photoUrl!))),
                    const Gap(10),
                    Text(c.playerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12)),
                      child: Text(c.registrationNo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                    const Gap(14),
                    InfoRow('Village', c.village),
                    InfoRow('Playing role', Options.label(Options.roles, c.playingRole)),
                    InfoRow('Jersey', '#${c.jerseyNumber ?? '-'} ${c.jerseyName ?? ''}'),
                    InfoRow('T-shirt size', c.tshirtSize),
                    InfoRow('Fee paid', rupees(c.feePaid)),
                    InfoRow('UTR', c.transactionId),
                    InfoRow('Confirmed on', fmtDateTime(c.confirmedAt)),
                  ]),
                ),
              ]),
            ),
            const Gap(18),
            FilledButton.icon(onPressed: () => _download(c), icon: const Icon(Icons.download), label: const Text('Download / share PDF')),
          ]);
        },
      ),
    );
  }
}
