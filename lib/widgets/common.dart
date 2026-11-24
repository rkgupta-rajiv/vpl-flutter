import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/formatters.dart';
import '../theme/app_theme.dart';

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.danger : AppColors.pitchDark,
      behavior: SnackBarBehavior.floating,
    ));
}

/// Runs an async action with a blocking progress dialog and error snack.
Future<T?> runWithProgress<T>(BuildContext context, Future<T> Function() action, {String? success}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
  );
  try {
    final result = await action();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      if (success != null) showSnack(context, success);
    }
    return result;
  } on ApiException catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      showSnack(context, e.message, error: true);
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      showSnack(context, 'Something went wrong: $e', error: true);
    }
  }
  return null;
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.trailing, required this.child, this.padding = const EdgeInsets.all(16)});

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
              child: Row(children: [
                Expanded(child: Text(title!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text))),
                if (trailing != null) trailing!,
              ]),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.label});

  final String status;
  final String? label;

  static Color colorFor(String s) {
    if (s.contains('reject')) return AppColors.danger;
    if (s.contains('approv') || s == 'verified' || s == 'completed') return AppColors.success;
    if (s == 'under_verification' || s == 'proof_submitted') return AppColors.info;
    if (s == 'incomplete' || s == 'payment_pending' || s == 'not_started') return AppColors.muted;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final c = colorFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label ?? humanize(status), style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 13))),
        Expanded(child: Text((value == null || value!.isEmpty) ? '—' : value!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
      ]),
    );
  }
}

class Banner2 extends StatelessWidget {
  const Banner2({super.key, required this.message, this.title, this.color = AppColors.danger, this.icon = Icons.error_outline, this.action});

  final String message;
  final String? title;
  final Color color;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (title != null) Text(title!, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
            Text(message, style: const TextStyle(fontSize: 13.5, color: AppColors.text)),
            if (action != null) Padding(padding: const EdgeInsets.only(top: 8), child: action!),
          ]),
        ),
      ]),
    );
  }
}

/// Labelled single-choice chips (used for gender, role, sizes …).
class ChoiceField extends StatelessWidget {
  const ChoiceField({super.key, required this.label, required this.options, required this.value, required this.onChanged, this.errorText});

  final String label;
  final Map<String, String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.muted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries
              .map((e) => ChoiceChip(
                    label: Text(e.value),
                    selected: value == e.key,
                    showCheckmark: false,
                    labelStyle: TextStyle(color: value == e.key ? Colors.white : AppColors.text, fontWeight: FontWeight.w600),
                    onSelected: (_) => onChanged(e.key),
                  ))
              .toList(),
        ),
        if (errorText != null)
          Padding(padding: const EdgeInsets.only(top: 4), child: Text(errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12))),
      ]),
    );
  }
}

class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(height: size, width: size);
}
