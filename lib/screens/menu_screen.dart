import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import '../login_screen.dart';
import '../providers/sound_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  VideoPlayerController? _vc;
  bool _videoReady = false;
  String? _playerName;
  bool _askedNameOnce = false;

  @override
  void initState() {
    super.initState();
    // Vào menu thì phát/tiếp tục nhạc nền menu (sau user gesture)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = Provider.of<SoundProvider>(context, listen: false);
      if (sp.isBgMusicEnabled) {
        sp.playBackgroundMusic();
      }
    });

    // Tải tên người chơi đã lưu, nếu chưa có thì hỏi
    _initPlayerName();

    // Khởi tạo video nền menu (mute + loop)
    _initVideo();
  }

  Future<void> _initPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('player_name')?.trim() ?? '';
    if (!mounted) return;
    setState(() {
      _playerName = saved;
    });
    if (_playerName == null || _playerName!.isEmpty) {
      _maybeAskPlayerName();
    }
  }

  Future<void> _maybeAskPlayerName() async {
    if (_askedNameOnce) return;
    _askedNameOnce = true;
    final controller = TextEditingController(text: _playerName ?? '');
    final name = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.lightBlue,
          elevation: 6,
          title: const Text('Nhập tên người chơi'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onSubmitted: (_) =>
                Navigator.of(context).pop(controller.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(''),
              child: const Text('Bỏ qua'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    setState(() {
      _playerName = (name ?? '').trim();
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name', _playerName ?? '');
  }

  Future<void> _initVideo() async {
    const path = 'assets/video/Menu.mp4';
    try {
      final controller = VideoPlayerController.asset(path);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0); // mute để tránh bị chặn autoplay
      await controller.play();
      if (!mounted) return;
      setState(() {
        _vc = controller;
        _videoReady = controller.value.isInitialized;
      });
    } catch (_) {
      // Nếu lỗi (thiếu asset, web chặn autoplay...), giữ _videoReady=false để fallback ảnh
    }
  }

  @override
  void dispose() {
    _vc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ảnh fallback cố định (không theo theme)
    // Màu tiêu đề (có thể chỉnh)
    final Color titleColor = const Color.fromARGB(255, 220, 57, 7);
    // Màu nền banner trong suốt và viền (có thể chỉnh)
    final Color bannerBg = Colors.black.withAlpha(
      40,
    ); // trong suốt, không che nền
    final Color bannerBorder = Colors.white.withAlpha(180);
    // Tính vị trí tiêu đề theo màn hình/thiết bị (cao hơn trên mobile)
    final mq = MediaQuery.of(context);
    final double titleTop = mq.padding.top + mq.size.height * 0.10;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nền video nếu đã sẵn sàng, ngược lại dùng ảnh fallback
          if (_videoReady && _vc != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _vc!.value.size.width,
                height: _vc!.value.size.height,
                child: VideoPlayer(_vc!),
              ),
            )
          else
            const SizedBox.shrink(),

          Container(color: Colors.black.withAlpha(31)),
          // Tiêu đề game đặt gần phía trên, căn giữa ngang
          Positioned(
            top: titleTop, // vị trí linh hoạt theo kích thước màn hình
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: bannerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bannerBorder, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(60, 0, 0, 0),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  '[Bậc Thầy Trí Tuệ]',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        color: Color.fromARGB(95, 73, 227, 214),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Main UI
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 2 hàng nút menu
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PixelButton(
                      label: "Start",
                      onPressed: () async {
                        // Điều hướng vào GameScreen và truyền tên
                        // ignore: use_build_context_synchronously
                        Navigator.push(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GameScreen(playerName: _playerName),
                          ),
                        ).then((_) {
                          // Khi quay lại menu, phát tiếp nhạc menu tại vị trí đã dừng
                          final sp =
                              // ignore: use_build_context_synchronously
                              Provider.of<SoundProvider>(
                                // ignore: use_build_context_synchronously
                                context,
                                listen: false,
                              );
                          if (sp.isBgMusicEnabled) {
                            sp.playBackgroundMusic();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 32),
                    _PixelButton(
                      label: "Setting",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PixelButton(
                      label: "Rank",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 32),
                    _PixelButton(
                      label: "Exit",
                      onPressed: () {
                        // Tạm dừng nhạc menu khi thoát
                        Provider.of<SoundProvider>(
                          context,
                          listen: false,
                        ).pauseBackgroundMusic();
                        // Thoát về màn hình đăng nhập/đăng ký và xóa toàn bộ stack
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PixelButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF6D7B0), // vàng nhạt
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // vuông góc
            side: const BorderSide(color: Colors.black, width: 3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.5,
            fontFamily: 'VT323', // nếu có font pixel
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
