import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundManager {
  // Singleton pattern
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;

  SoundManager._internal();

  /// Phát âm thanh từ assets
  Future<void> play(String assetPath) async {
    try {
      final player = AudioPlayer(); // tạo mới player mỗi lần phát
      await player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint("❌ Lỗi phát âm thanh: $e");
    }
  }

  /// Các hàm tiện ích để gọi nhanh
  Future<void> playBomb() async => play('audio/bum.mp3');
  Future<void> playFlip() async => play('audio/flip.mp3');
  Future<void> playMatch() async => play('audio/match.mp3');
  Future<void> playWin() async => play('audio/win.mp3');
  Future<void> playLose() async => play('audio/lose.mp3');
}
