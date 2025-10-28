import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/theme_provider.dart';
import '../providers/sound_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _menuBgIndex = 1; // 1..3
  VideoPlayerController? _bgVc;
  bool _bgReady = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _menuBgIndex =
          prefs.getInt('game_bg_index') ?? prefs.getInt('menu_bg_index') ?? 1;
    });
    await _initBgVideo();
  }

  Future<void> _setMenuBgIndex(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('game_bg_index', value);
    setState(() {
      _menuBgIndex = value;
    });
    await _initBgVideo();
  }

  String _bgLabel(int idx) =>
      idx == 1 ? 'Syteam' : (idx == 2 ? 'Dark' : 'Light');

  Future<void> _pickGameBg() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container
                (
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade600,
                    Colors.blue.shade800,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  listTileTheme: ListTileThemeData(
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    selectedColor: Colors.white,
                    selectedTileColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette_rounded),
                      title: const Text('Syteam'),
                      trailing: _menuBgIndex == 1
                          ? Icon(Icons.check_circle, color: scheme.onPrimary)
                          : null,
                      onTap: () => Navigator.pop(context, 1),
                      selected: _menuBgIndex == 1,
                    ),
                    ListTile(
                      leading: const Icon(Icons.nightlight_round),
                      title: const Text('Dark'),
                      trailing: _menuBgIndex == 2
                          ? Icon(Icons.check_circle, color: scheme.onPrimary)
                          : null,
                      onTap: () => Navigator.pop(context, 2),
                      selected: _menuBgIndex == 2,
                    ),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny_rounded),
                      title: const Text('Light'),
                      trailing: _menuBgIndex == 3
                          ? Icon(Icons.check_circle, color: scheme.onPrimary)
                          : null,
                      onTap: () => Navigator.pop(context, 3),
                      selected: _menuBgIndex == 3,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    if (selected != null) {
      await _setMenuBgIndex(selected);
    }
  }

  String _videoPathFor(int idx) {
    switch (idx) {
      case 1:
        return 'assets/backgrounds/Syteam.mp4';
      case 2:
        return 'assets/backgrounds/Dark.mp4';
      case 3:
        return 'assets/backgrounds/Light.mp4';
      default:
        return 'assets/backgrounds/Syteam.mp4';
    }
  }

  Future<void> _initBgVideo() async {
    final path = _videoPathFor(_menuBgIndex);
    try {
      final c = VideoPlayerController.asset(path);
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      final old = _bgVc;
      if (!mounted) return;
      setState(() {
        _bgVc = c;
        _bgReady = c.value.isInitialized;
      });
      await old?.dispose();
    } catch (_) {
      // ignore errors silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final soundProvider = Provider.of<SoundProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nền video giống trong Game
          if (_bgReady && _bgVc != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _bgVc!.value.size.width,
                height: _bgVc!.value.size.height,
                child: VideoPlayer(_bgVc!),
              ),
            )
          else
            const SizedBox.shrink(),
          // Nội dung cài đặt
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Phần Âm thanh
                Text('Âm thanh', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: _sectionDecoration(context),
                  child: Row(
                    children: [
                      Icon(
                        soundProvider.isBgMusicEnabled
                            ? Icons.music_note
                            : Icons.music_off,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('Nhạc nền')),
                      Switch.adaptive(
                        value: soundProvider.isBgMusicEnabled,
                        onChanged: (_) => soundProvider.toggleBackgroundMusic(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Phần nền trong game (video) với thanh trượt 3 nấc: Syteam(1) - Dark(2) - Light(3)
                Text(
                  'Giao Diện',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: _blueSectionDecoration(context),
                  child: Row(
                    children: [
                      const Icon(Icons.palette_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ': ${_bgLabel(_menuBgIndex)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _pickGameBg,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Chọn'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Phần Cỡ chữ
                Text('Cỡ chữ', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: _sectionDecoration(context),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.text_fields_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                final scale = themeProvider.textScale; // 0.8..1.4
                                // map 0.8..1.4 -> 1..100
                                final percent = (1 + ((scale - 0.8) / 0.6) * 99)
                                    .clamp(1, 100)
                                    .round()
                                    .toDouble();
                                return SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 2.0,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8,
                                    ),
                                  ),
                                  child: Slider(
                                    value: percent,
                                    min: 1,
                                    max: 100,
                                    divisions: 99,
                                    label: percent.toStringAsFixed(0),
                                    onChanged: (v) {
                                      // map 1..100 -> 0.8..1.4
                                      final newScale =
                                          0.8 + ((v - 1) / 99.0) * 0.6;
                                      themeProvider.setTextScale(newScale);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'x${themeProvider.textScale.toStringAsFixed(1)}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bgVc?.dispose();
    super.dispose();
  }
}

BoxDecoration _sectionDecoration(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        scheme.surface.withAlpha(230),
        scheme.surfaceContainerHighest.withAlpha(217),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: scheme.outline.withAlpha(128), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(20),
        blurRadius: 16,
        spreadRadius: 1,
        offset: const Offset(0, 6),
      ),
    ],
  );
}

BoxDecoration _blueSectionDecoration(BuildContext context) {
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.blue.shade500,
        Colors.blue.shade700,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(30),
        blurRadius: 18,
        spreadRadius: 1,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
