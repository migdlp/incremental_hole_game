import 'dart:convert';
import 'package:share_plus/share_plus.dart';

/// In-memory UTF-8 files; platform plugin writes only its local sharing cache.
/// Web falls back to downloads. No server or account is involved.
Future<void> shareBalanceFile(String name, String contents) async {
  final mime = name.endsWith('.json')
      ? 'application/json'
      : name.endsWith('.csv')
      ? 'text/csv'
      : 'text/plain';
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(utf8.encode(contents), mimeType: mime)],
      fileNameOverrides: ['feed-the-hole-$name'],
      title: 'Feed the Hole · laboratorio de balance',
    ),
  );
}
