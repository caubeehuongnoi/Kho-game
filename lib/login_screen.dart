import 'package:flutter/material.dart';
import 'login_controller.dart';
import 'package:video_player/video_player.dart';
// Music will start on MenuScreen, not here

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController controller = LoginController();

  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool _busy = false;
  bool _obscurePassword = true;
  bool _isLoginMode = true;
  late final VideoPlayerController _videoController;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo video nền (mute, loop, autoplay)
    _videoController = VideoPlayerController.asset('assets/video/DangK.mp4')
      ..setLooping(true)
      ..setVolume(0.0);

    _videoController.initialize().then((_) {
      if (!mounted) return;
      setState(() => _videoReady = true);
      _videoController.play();
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() => _busy = true);
    controller.setUsername(userController.text);
    controller.setPassword(passController.text);
    final ok = await controller.login();
    setState(() => _busy = false);

    if (!mounted) return;
    if (ok) {
      // Điều hướng sang Menu; nhạc nền sẽ được khởi động trong MenuScreen
      Navigator.pushReplacementNamed(context, '/menu');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sai tên đăng nhập hoặc mật khẩu ❌")),
      );
    }
  }

  Future<void> _doRegister() async {
    setState(() => _busy = true);
    controller.setUsername(userController.text);
    controller.setPassword(passController.text);
    final ok = await controller.register();
    setState(() => _busy = false);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đăng ký thành công 🎉 — bạn có thể đăng nhập ngay"),
        ),
      );
      setState(() => _isLoginMode = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tên đăng nhập đã tồn tại hoặc không hợp lệ ❌"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video background (không dùng fallback ảnh khi chưa sẵn sàng)
          _videoReady
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                )
              : Container(color: Colors.black),

          // Form đăng nhập/đăng ký với nền trong suốt
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                // Tăng độ trong suốt: 0.2 = rất trong suốt, 0.3 = vừa phải
                color: Colors.white.withValues(alpha: 0.25),
                elevation: 2, // Giảm bóng đổ
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  // Thêm viền để dễ nhìn hơn khi trong suốt
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Trường Tài Khoản
                      TextField(
                        controller: userController,
                        decoration: InputDecoration(
                          hintText: 'Tài Khoản',
                          hintStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.blue[700],
                          ),
                          filled: true,
                          // Làm trong suốt các TextField
                          fillColor: Colors.white.withValues(alpha: 0.7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue[300]!,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue[300]!,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Trường Mật Khẩu
                      TextField(
                        controller: passController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Mật Khẩu',
                          hintStyle: TextStyle(color: Colors.grey[700]),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.blue[700],
                          ),
                          suffixIcon: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100]?.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 18,
                                    color: Colors.blue[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _obscurePassword ? 'Hiện' : 'Ẩn',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue[300]!,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue[300]!,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: Colors.blue[700]!,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút Đăng Nhập/Đăng Ký
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _busy
                              ? null
                              : (_isLoginMode ? _doLogin : _doRegister),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: _busy
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.login,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isLoginMode ? 'Đăng Nhập' : 'Đăng Ký',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Chỉ có nút Đăng Ký/Đăng Nhập
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() => _isLoginMode = !_isLoginMode);
                          },
                          child: Text(
                            _isLoginMode ? 'Đăng Ký' : 'Đăng Nhập',
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
