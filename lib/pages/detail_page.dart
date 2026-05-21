import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/wallpaper_service.dart';

class DetailPage extends StatelessWidget {
  final Wallpaper wallpaper;
  const DetailPage({super.key, required this.wallpaper});

  String _fmt(int b) {
    if (b <= 0) return 'Unknown';
    if (b < 1048576) return '${(b/1024).toStringAsFixed(1)} KB';
    if (b < 1073741824) return '${(b/1048576).toStringAsFixed(1)} MB';
    return '${(b/1073741824).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dir = '$kWorkshopPath/${wallpaper.id}';
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(backgroundColor: cs.surface, title: Text(wallpaper.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (wallpaper.previewPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(wallpaper.previewPath!), width: double.infinity, height: 500, fit: BoxFit.contain),
            ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _row(cs, 'Name', wallpaper.name),
              _row(cs, 'ID', wallpaper.id, mono: true, copy: true),
              _row(cs, 'Size', _fmt(wallpaper.sizeBytes)),
              _row(cs, 'Path', dir, mono: true),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Open in File Manager'),
            onPressed: () => Process.run('xdg-open', [dir]),
          )),
        ]),
      ),
    );
  }

  Widget _row(ColorScheme cs, String label, String value, {bool mono = false, bool copy = false}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 50, child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontFamily: mono ? 'monospace' : null))),
        if (copy) GestureDetector(
          onTap: () => Clipboard.setData(ClipboardData(text: value)),
          child: Icon(Icons.copy, size: 14, color: cs.onSurfaceVariant),
        ),
      ]),
    );
}
