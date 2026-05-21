import 'dart:io';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _open(String url) => Process.run('xdg-open', [url]);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(backgroundColor: cs.surface, title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundImage: const AssetImage('assets/pfp.gif'),
          ),
          const SizedBox(height: 12),
          const Text('DarkKyoka', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Developer', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),

          // App info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoRow(cs, 'App', 'Simplicity'),
              _infoRow(cs, 'Version', '1.0.0'),
              _infoRow(cs, 'Platform', 'Linux (KDE Plasma 6)'),
              _infoRow(cs, 'Engine', 'linux-wallpaperengine'),
            ]),
          ),
          const SizedBox(height: 20),

          // Buttons
          _LinkButton(
            icon: Icons.coffee,
            label: 'Support on Ko-fi',
            color: const Color(0xFFFF5E5B),
            onTap: () => _open('https://ko-fi.com/darkkyoka'),
          ),
          const SizedBox(height: 10),
          _LinkButton(
            icon: Icons.code,
            label: 'GitHub',
            color: const Color(0xFF534AB7),
            onTap: () => _open('https://github.com/DarkKyoka'),
          ),
          const SizedBox(height: 10),
          _LinkButton(
            icon: Icons.bug_report,
            label: 'Report an Issue',
            color: cs.outline,
            onTap: () => _open('https://github.com/DarkKyoka/simplicity/issues'),
          ),
        ]),
      ),
    );
  }

  Widget _infoRow(ColorScheme cs, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 70, child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant))),
      Text(value, style: const TextStyle(fontSize: 13)),
    ]),
  );
}

class _LinkButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _LinkButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onTap,
    ),
  );
}
