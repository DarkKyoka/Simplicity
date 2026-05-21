import 'dart:io';

class MonitorService {
  /// Detects all connected monitors and their max refresh rates via xrandr.
  /// Returns a map of { monitorName: maxHz }
  static Future<Map<String, int>> detectMonitors() async {
    final result = await Process.run('xrandr', ['--query']);
    final output = result.stdout as String;
    final monitors = <String, int>{};

    String? currentMonitor;
    final monitorLineReg = RegExp(r'^(\S+)\s+connected', multiLine: true);
    final modeLineReg = RegExp(r'^\s+\d+x\d+\s+([\d.]+)\*?', multiLine: true);
    final allHzReg = RegExp(r'([\d.]+)\*?', multiLine: false);

    // Parse line by line
    final lines = output.split('\n');
    for (final line in lines) {
      final monitorMatch = monitorLineReg.firstMatch(line);
      if (monitorMatch != null) {
        currentMonitor = monitorMatch.group(1);
        monitors[currentMonitor!] = 60; // default fallback
        continue;
      }

      if (currentMonitor != null && line.startsWith('   ')) {
        // This is a mode line — extract all Hz values
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          int maxHz = 0;
          for (final part in parts.skip(1)) {
            final clean = part.replaceAll('*', '').replaceAll('+', '');
            final hz = double.tryParse(clean);
            if (hz != null && hz > maxHz) maxHz = hz.round();
          }
          if (maxHz > (monitors[currentMonitor] ?? 0)) {
            monitors[currentMonitor!] = maxHz;
          }
        }
      }
    }

    return monitors;
  }

  /// Returns the max Hz for a specific monitor, defaulting to 60.
  static Future<int> getMaxHz(String monitorName) async {
    try {
      final monitors = await detectMonitors();
      return monitors[monitorName] ?? 60;
    } catch (_) {
      return 60;
    }
  }
}