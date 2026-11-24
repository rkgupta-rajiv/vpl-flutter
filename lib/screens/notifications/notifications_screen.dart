import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/models.dart';
import '../../state/session.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    final api = context.read<Session>().api;
    _future = api.notifications();
    _future.then((_) => api.markNotificationsRead()).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          final items = snap.data!;
          if (items.isEmpty) return const Center(child: Text('No notifications yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = items[i];
              final color = switch (n.kind) { 'success' => AppColors.success, 'danger' => AppColors.danger, 'warning' => AppColors.warning, _ => AppColors.info };
              return Container(
                decoration: BoxDecoration(
                  color: n.read ? Colors.white : color.withOpacity(.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(n.kind == 'danger' ? Icons.error_outline : Icons.notifications_active_outlined, color: color)),
                  title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${n.message}\n${fmtDateTime(n.createdAt)}'),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
