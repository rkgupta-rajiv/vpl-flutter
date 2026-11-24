import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/models.dart';
import '../../models/options.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_image.dart';
import '../../widgets/common.dart';

/// Upload profile photo + Aadhaar front/back with preview and status.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  static const _hints = {
    'photo': 'Clear, recent passport-style photo. Face visible, no sunglasses.',
    'aadhaar_front': 'Front side with name, photo and Aadhaar number clearly readable.',
    'aadhaar_back': 'Back side with address clearly readable.',
  };

  Future<void> _pick(BuildContext context, String type) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Take photo'), onTap: () => Navigator.pop(c, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Choose from gallery'), onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;

    final XFile? file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 82, // keeps uploads small (< 2 MB) while readable
      preferredCameraDevice: type == 'photo' ? CameraDevice.front : CameraDevice.rear,
    );
    if (file == null || !context.mounted) return;

    final bytes = await file.readAsBytes();
    if (bytes.lengthInBytes > (type == 'photo' ? 2 : 5) * 1024 * 1024) {
      if (context.mounted) showSnack(context, 'Image is too large. Please choose a smaller image.', error: true);
      return;
    }
    if (!context.mounted) return;
    final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
    final session = context.read<Session>();
    final ok = await runWithProgress(
      context,
      () => session.api.uploadDocument(type, UploadFile(bytes: bytes, filename: name)),
      success: '${Options.documents[type]} uploaded.',
    );
    if (ok != null) await session.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final player = session.player;
    final locked = session.registration?.isCompleted ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('My documents')),
      body: player == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Banner2(
                icon: Icons.lock_outline,
                color: AppColors.info,
                message: 'Your documents are stored securely and are visible only to you and the tournament admin. JPG/PNG, photo up to 2 MB, Aadhaar up to 5 MB.',
              ),
              for (final type in Options.documents.keys)
                _DocTile(
                  type: type,
                  hint: _hints[type]!,
                  doc: player.document(type),
                  locked: locked,
                  onPick: () => _pick(context, type),
                ),
              const Gap(8),
              if (player.documentsComplete)
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
            ]),
    );
  }
}

class _DocTile extends StatelessWidget {
  const _DocTile({required this.type, required this.hint, required this.doc, required this.locked, required this.onPick});

  final String type, hint;
  final PlayerDocument? doc;
  final bool locked;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: Options.documents[type],
      trailing: doc == null ? const StatusChip('incomplete', label: 'Required') : StatusChip(doc!.status),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const Gap(10),
        InkWell(
          onTap: locked ? null : onPick,
          borderRadius: BorderRadius.circular(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 180,
              child: doc != null
                  ? AuthImage(doc!.url, fit: BoxFit.contain)
                  : Container(
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(14)),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.pitch),
                        Gap(6),
                        Text('Tap to upload', style: TextStyle(color: AppColors.pitch, fontWeight: FontWeight.w700)),
                      ]),
                    ),
            ),
          ),
        ),
        if (doc?.status == 'rejected' && doc?.remarks != null) ...[
          const Gap(8),
          Text('Rejected: ${doc!.remarks}', style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
        ],
        if (doc != null && !locked) ...[
          const Gap(10),
          OutlinedButton.icon(onPressed: onPick, icon: const Icon(Icons.refresh), label: const Text('Replace')),
        ],
      ]),
    );
  }
}
