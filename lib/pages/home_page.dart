import 'dart:io';
import 'package:flutter/material.dart';
import '../services/wallpaper_service.dart';
import '../services/monitor_service.dart';
import 'detail_page.dart';
import 'about_page.dart';

class HomePage extends StatefulWidget {
  final bool startMinimized;
  const HomePage({super.key, this.startMinimized = false});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _svc = WallpaperService();
  List<Wallpaper> _wallpapers = [];
  String? _selected;
  bool _loading = true, _autostart = false, _muted = false;
  int _fps = 30, _maxFps = 60, _volume = 15;
  String _status = 'No wallpaper running';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final results = await Future.wait([
      _svc.listWallpapers(),
      MonitorService.getMaxHz(kMonitor),
      _svc.detectRunningInstance(),
    ]);
    final wallpapers = results[0] as List<Wallpaper>;
    final hz = results[1] as int;
    final runningId = results[2] as String?;
    setState(() {
      _wallpapers = wallpapers;
      _maxFps = hz;
      _fps = _fps.clamp(0, hz);
      _loading = false;
      _autostart = _svc.autostartEnabled;
      if (runningId != null) { _selected = runningId; _status = 'Running: $runningId'; }
    });
  }

  Future<void> _apply() async {
    if (_selected == null) return;
    setState(() => _status = 'Starting...');
    await _svc.apply(_selected!, fps: _fps, volume: _volume, muted: _muted);
    setState(() => _status = 'Running: $_selected');
    _svc.watchForCrash(
      id: _selected!, fps: _fps, volume: _volume, muted: _muted,
      onCrash: () async {
        if (!mounted) return;
        setState(() => _status = 'Crashed — retrying without particles...');
        _snack('Wallpaper crashed, retrying without particles...');
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _status = 'Running (no particles): $_selected');
      },
    );
  }

  Future<void> _stop() async { await _svc.stop(); setState(() => _status = 'No wallpaper running'); }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  Future<void> _toggleAutostart(bool val) async {
    if (_selected == null && val) { _snack('Select a wallpaper first'); return; }
    await _svc.setAutostart(val, _selected ?? '', fps: _fps, volume: _volume, muted: _muted);
    setState(() => _autostart = _svc.autostartEnabled);
  }

  void _reapply() { if (_svc.isRunning) _svc.reapply(fps: _fps, volume: _volume, muted: _muted); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        title: const Text('Simplicity', style: TextStyle(fontWeight: FontWeight.w500)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _init),
          // Tray/app autostart option
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'about') { Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())); return; }
              if (v == 'tray') await _svc.setAppAutostart(true, startAsTray: true);
              if (v == 'notray') await _svc.setAppAutostart(true, startAsTray: false);
              if (v == 'noapp') await _svc.setAppAutostart(false);
              _snack('App autostart updated');
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'about', child: Text('About')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'tray', child: Text('Autostart as tray')),
              const PopupMenuItem(value: 'notray', child: Text('Autostart as window')),
              const PopupMenuItem(value: 'noapp', child: Text('Disable app autostart')),
            ],
          ),
        ],
      ),
      body: Column(children: [
        // Status bar
        Container(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(
                shape: BoxShape.circle, color: _svc.isRunning ? Colors.greenAccent : Colors.grey)),
            const SizedBox(width: 10),
            Expanded(child: Text(_status, style: const TextStyle(fontSize: 13))),
            if (_svc.isRunning) TextButton(
              onPressed: _stop,
              style: TextButton.styleFrom(foregroundColor: cs.error, padding: const EdgeInsets.symmetric(horizontal: 10)),
              child: const Text('Stop', style: TextStyle(fontSize: 12)),
            ),
          ]),
        ),
        // Grid
        Flexible(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _wallpapers.isEmpty
              ? const Center(child: Text('No wallpapers found.'))
              : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8),
            itemCount: _wallpapers.length,
            itemBuilder: (ctx, i) {
              final w = _wallpapers[i];
              return _WallpaperCard(
                wallpaper: w,
                selected: _selected == w.id,
                onTap: () => setState(() => _selected = w.id),
                onDetail: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => DetailPage(wallpaper: w))),
              );
            },
          ),
        ),
        // Settings
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.speed, size: 16), const SizedBox(width: 8),
              const Text('FPS', style: TextStyle(fontSize: 13)), const SizedBox(width: 4),
              Text(_fps == 0 ? 'Static' : '$_fps', style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w500)),
              Expanded(child: Slider(
                value: _fps.toDouble(), min: 0, max: _maxFps.toDouble(), divisions: _maxFps,
                onChanged: (v) => setState(() => _fps = v.round()),
                onChangeEnd: (_) => _reapply(),
              )),
              Text('$_maxFps', style: const TextStyle(fontSize: 11)),
            ]),
            Row(children: [
              GestureDetector(
                onTap: () { setState(() => _muted = !_muted); _reapply(); },
                child: Icon(_muted ? Icons.volume_off : Icons.volume_up, size: 16, color: _muted ? cs.error : null),
              ),
              const SizedBox(width: 8),
              const Text('Vol', style: TextStyle(fontSize: 13)), const SizedBox(width: 4),
              Text(_muted ? 'Muted' : '$_volume', style: TextStyle(fontSize: 12, color: _muted ? cs.error : cs.primary, fontWeight: FontWeight.w500)),
              Expanded(child: Slider(
                value: _muted ? 0 : _volume.toDouble(), min: 0, max: 100, divisions: 100,
                onChanged: _muted ? null : (v) => setState(() => _volume = v.round()),
                onChangeEnd: _muted ? null : (_) => _reapply(),
              )),
              const Text('100', style: TextStyle(fontSize: 11)),
            ]),
          ]),
        ),
        // Bottom
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: Row(children: [
            Switch(value: _autostart, onChanged: _toggleAutostart),
            const SizedBox(width: 6),
            const Text('Autostart', style: TextStyle(fontSize: 13)),
            const Spacer(),
            FilledButton.icon(
              onPressed: _selected != null ? _apply : null,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Apply'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF534AB7), foregroundColor: Colors.white),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  void dispose() { _svc.stop(); super.dispose(); }
}

class _WallpaperCard extends StatelessWidget {
  final Wallpaper wallpaper;
  final bool selected;
  final VoidCallback onTap, onDetail;
  const _WallpaperCard({required this.wallpaper, required this.selected, required this.onTap, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF534AB7) : cs.outlineVariant, width: selected ? 2 : 0.5),
        ),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: wallpaper.previewPath != null
                  ? Image.file(File(wallpaper.previewPath!), width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Text(wallpaper.name, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          // Info button top-left
          Positioned(top: 4, left: 4, child: GestureDetector(
            onTap: onDetail,
            child: Container(
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.info_outline, size: 14, color: Colors.white),
            ),
          )),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: const Color(0xFF2A2540),
      child: const Center(child: Icon(Icons.image_outlined, size: 32, color: Colors.white24)));
}