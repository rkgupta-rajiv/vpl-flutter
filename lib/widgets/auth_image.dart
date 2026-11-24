import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';

/// Loads a PRIVATE image (document / screenshot) with the player's bearer token.
/// Works on Android, iOS and Web (bytes are fetched via the API client).
class AuthImage extends StatefulWidget {
  const AuthImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height});

  final String url;
  final BoxFit fit;
  final double? width, height;

  static final Map<String, Uint8List> _cache = {};

  static void clearCache() => _cache.clear();

  @override
  State<AuthImage> createState() => _AuthImageState();
}

class _AuthImageState extends State<AuthImage> {
  Future<Uint8List>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void didUpdateWidget(covariant AuthImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _future = _load();
  }

  Future<Uint8List> _load() async {
    final cached = AuthImage._cache[widget.url];
    if (cached != null) return cached;
    final bytes = await context.read<Session>().client.bytes(widget.url);
    AuthImage._cache[widget.url] = bytes;
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasData) {
          return Image.memory(snap.data!, fit: widget.fit, width: widget.width, height: widget.height, gaplessPlayback: true);
        }
        return Container(
          width: widget.width,
          height: widget.height,
          color: const Color(0xFFE2E8F0),
          alignment: Alignment.center,
          child: snap.hasError
              ? const Icon(Icons.broken_image_outlined, color: Colors.grey)
              : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
