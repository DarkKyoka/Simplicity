import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

const String kBinary = '/home/vaggelis/linux-wallpaperengine/build/output/linux-wallpaperengine';
const String kWorkshopPath = '/home/vaggelis/.local/share/Steam/steamapps/workshop/content/431960';
const String kAutostartPath = '/home/vaggelis/.config/autostart/wallpaperengine.desktop';
const String kAppAutostartPath = '/home/vaggelis/.config/autostart/simplicity.desktop';
const String kMonitor = 'DP-1';

class Wallpaper {
  final String id;
  final String? previewPath;
  final String name;
  final int sizeBytes;

  Wallpaper({required this.id, this.previewPath, required this.name, this.sizeBytes = 0});
}

class WallpaperService {
  Process? _process;
  String? _runningId;

  String? get runningId => _runningId;
  bool get isRunning => _process != null || _runningId != null;

  Future<String?> detectRunningInstance() async {
    try {
      final r = await Process.run('pgrep', ['-f', 'linux-wallpaperengine']);
      final pid = (r.stdout as String).trim().split('\n').first.trim();
      if (pid.isEmpty) return null;
      final cmdline = await File('/proc/$pid/cmdline').readAsString();
      final args = cmdline.split('\x00').where((s) => s.isNotEmpty).toList();
      for (final arg in args.reversed) {
        if (!arg.startsWith('-') && RegExp(r'^\d+$').hasMatch(arg)) {
          _runningId = arg;
          return arg;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<Wallpaper>> listWallpapers() async {
    final dir = Directory(kWorkshopPath);
    if (!await dir.exists()) return [];
    final entities = await dir.list().where((e) => e is Directory).toList();
    final results = await Future.wait(entities.map((e) => _loadWallpaper(e.path)));
    results.sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  Future<Wallpaper> _loadWallpaper(String dirPath) async {
    final id = p.basename(dirPath);
    String? preview;
    String name = id;
    int size = 0;

    // Run preview and name detection in parallel
    await Future.wait([
      Future(() async {
        for (final ext in ['preview.gif', 'preview.png', 'preview.jpg']) {
          final f = File(p.join(dirPath, ext));
          if (await f.exists()) { preview = f.path; break; }
        }
      }),
      Future(() async {
        // Read name from project.json
        final json = File(p.join(dirPath, 'project.json'));
        if (await json.exists()) {
          try {
            final data = jsonDecode(await json.readAsString());
            name = (data['title'] as String?) ?? id;
          } catch (_) {}
        }
      }),
      Future(() async {
        // Compute folder size
        try {
          final r = await Process.run('du', ['-sb', dirPath]);
          size = int.tryParse((r.stdout as String).trim().split('\t').first) ?? 0;
        } catch (_) {}
      }),
    ]);

    return Wallpaper(id: id, previewPath: preview, name: name, sizeBytes: size);
  }

  Future<void> apply(String id, {int fps = 30, int volume = 15, bool muted = false}) async {
    await stop();
    await _launch(id, fps: fps, volume: volume, muted: muted, disableParticles: false);
  }

  Future<void> reapply({int fps = 30, int volume = 15, bool muted = false}) async {
    if (_runningId == null) return;
    final id = _runningId!;
    await stop();
    await _launch(id, fps: fps, volume: volume, muted: muted, disableParticles: false);
  }

  Future<void> _launch(String id, {int fps = 30, int volume = 15, bool muted = false, bool disableParticles = false}) async {
    final args = [
      '--screen-root', kMonitor,
      '--disable-mouse',
      if (disableParticles) '--disable-particles',
      '--no-fullscreen-pause',
      '--fps', (fps == 0 ? 1 : fps).toString(),
      if (muted) '--silent' else ...['-v', volume.toString()],
      id,
    ];
    _process = await Process.start(kBinary, args);
    _runningId = id;
  }

  void watchForCrash({required String id, required int fps, required int volume, required bool muted, required Future<void> Function() onCrash}) {
    _process?.exitCode.then((code) async {
      if ((code == 139 || code == -11) && _runningId == id) {
        _process = null; _runningId = null;
        await onCrash();
        await _launch(id, fps: fps, volume: volume, muted: muted, disableParticles: true);
      }
    });
  }

  Future<void> stop() async {
    if (_process != null) {
      _process!.kill();
      await _process!.exitCode.timeout(const Duration(seconds: 2), onTimeout: () => -1);
      _process = null; _runningId = null;
    }
  }

  bool get autostartEnabled => File(kAutostartPath).existsSync();
  bool get appAutostartEnabled => File(kAppAutostartPath).existsSync();

  Future<void> setAutostart(bool enabled, String wallpaperId, {int fps = 30, int volume = 15, bool muted = false}) async {
    final file = File(kAutostartPath);
    if (enabled) {
      final soundArgs = muted ? '--silent' : '-v $volume';
      await file.writeAsString(
        '[Desktop Entry]\nType=Application\nName=Simplicity Wallpaper\n'
            'Exec=bash -c "sleep 3 && $kBinary --screen-root $kMonitor --disable-mouse --no-fullscreen-pause --fps $fps $soundArgs $wallpaperId"\n'
            'X-KDE-AutostartEnabled=true\n',
      );
    } else {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> setAppAutostart(bool enabled, {bool startAsTray = false}) async {
    final file = File(kAppAutostartPath);
    if (enabled) {
      final appPath = Platform.resolvedExecutable;
      await file.writeAsString(
        '[Desktop Entry]\nType=Application\nName=Simplicity\n'
            'Exec=$appPath${startAsTray ? ' --tray' : ''}\n'
            'X-KDE-AutostartEnabled=true\n',
      );
    } else {
      if (await file.exists()) await file.delete();
    }
  }
}