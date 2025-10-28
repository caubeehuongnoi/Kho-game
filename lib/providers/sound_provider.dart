import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SoundProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _bgMusicPlayer = AudioPlayer(); // Player riêng cho nhạc nền

  bool _isBgMusicEnabled = true;
  bool get isBgMusicEnabled => _isBgMusicEnabled;
  bool _bgLoaded = false;

  SoundProvider() {
    // Cấu hình nhạc nền lặp lại
    _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
  }

  /// Bật/tắt nhạc nền
  Future<void> toggleBackgroundMusic() async {
    _isBgMusicEnabled = !_isBgMusicEnabled;
    notifyListeners();

    if (_isBgMusicEnabled) {
      await playBackgroundMusic();
    } else {
      // Tạm dừng để giữ vị trí phát hiện tại
      await pauseBackgroundMusic();
    }
  }

  /// Phát nhạc nền
  Future<void> playBackgroundMusic() async {
    if (!_isBgMusicEnabled) return;

    try {
      // Chỉ nạp nguồn một lần, sau đó resume để tiếp tục từ vị trí trước đó
      if (!_bgLoaded) {
        await _bgMusicPlayer.setSource(AssetSource('audio/NhacNen1.mp3'));
        await _bgMusicPlayer.setVolume(0.4); // Âm lượng 40%
        _bgLoaded = true;
      }
      await _bgMusicPlayer.resume();
    } catch (e) {
      // Nếu không có file nhạc nền, bỏ qua
      debugPrint('Không thể phát nhạc nền: $e');
    }
  }

  /// Tạm dừng nhạc nền (giữ vị trí)
  Future<void> pauseBackgroundMusic() async {
    try {
      await _bgMusicPlayer.pause();
    } catch (_) {}
  }

  /// Phát âm khi lật thẻ (flip).
  Future<void> playFlip() => _safePlay('audio/flip.mp3');

  /// Phát âm khi ghép đúng (match).
  Future<void> playMatch() => _safePlay('audio/match.mp3');

  /// Phát âm khi ghép sai (mismatch).
  Future<void> playMismatch() => _safePlay('audio/mismatch.mp3');

  /// Phát âm khi hoàn thành game (chiến thắng).
  Future<void> playWin() => _safePlay('audio/win.mp3');

  /// Phát âm khi thua game (hết giờ).
  Future<void> playLose() => _safePlay('audio/lose.mp3');

  /// Helper an toàn để phát một asset. Nếu lỗi/thiếu file sẽ bỏ qua.
  Future<void> _safePlay(String assetPath) async {
    try {
      // Gọi stop() không chờ để tránh treo trên Web
      _player
          .stop()
          .timeout(const Duration(milliseconds: 150))
          .catchError((_) {});
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Nếu lỗi hoặc thiếu file, bỏ qua không gây crash
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _bgMusicPlayer.dispose();
    super.dispose();
  }

  void playShuffle() {}
}
