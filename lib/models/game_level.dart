import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'card_model.dart';
import 'sound_manager.dart';

class GameLevel extends ChangeNotifier {
  final int level;
  final int initialScore;
  late final List<CardModel> cards;
  late final int timeLimit;

  static const Duration _previewDuration = Duration(seconds: 3);
  static const Duration _shuffleDelay = Duration(milliseconds: 350);

  Timer? _timer;
  Timer? _previewTimer;
  Timer? _postPreviewShuffleTimer;
  int _timeRemaining = 0;
  bool _isGameStarted = false;
  bool _isPreview = true;
  bool _inputLocked = true;

  // One-time assists per level
  bool _usedAddTime = false;
  bool _usedHint = false;
  bool _usedClearBombs = false;

  CardModel? _first;
  CardModel? _second;
  int _matchesFound = 0;
  int _score = 0;
  int slevel = 11;

  VoidCallback? _onMatch;
  VoidCallback? _onMismatch;

  GameLevel({required this.level, this.initialScore = 0}) {
    timeLimit = 30 + (level - 1) * 8;
    _timeRemaining = timeLimit;
    cards = _generateCards();
    _score = initialScore;
  }

  int get _pairs => (level + 1).clamp(2, slevel);

  List<CardModel> _generateCards() {
    final pairs = _pairs;
    final images = _getCardImages().take(pairs).toList();
    final list = <CardModel>[];

    // ✅ Tạo cặp thẻ chuẩn
    for (var i = 0; i < pairs; i++) {
      list.add(CardModel(id: i, imagePath: images[i]));
      list.add(CardModel(id: i, imagePath: images[i]));
    }

    // ✅ Thêm thẻ bom tùy level
    if (level >= 6) {
      list.add(BombCard(id: 999, imagePath: 'assets/cards/bom.png'));
      list.add(BombCard(id: 1000, imagePath: 'assets/cards/bom.png'));
    } else if (level >= 3) {
      list.add(BombCard(id: 999, imagePath: 'assets/cards/bom.png'));
    }

    return list;
  }

  List<String> _getCardImages() {
    return const [
      'assets/cards/1.png',
      'assets/cards/2.png',
      'assets/cards/3.png',
      'assets/cards/4.png',
      'assets/cards/5.png',
      'assets/cards/6.png',
      'assets/cards/7.png',
      'assets/cards/8.png',
      'assets/cards/9.png',
      'assets/cards/10.png',
      'assets/cards/11.png',
      'assets/cards/12.png',
      'assets/cards/bom.png',
    ];
  }

  void startLevel(
    VoidCallback onTimeUp, {
    VoidCallback? onMatch,
    VoidCallback? onMismatch,
  }) {
    _onMatch = onMatch;
    _onMismatch = onMismatch;
    _isGameStarted = true;
    _isPreview = true;
    _inputLocked = true;
    _usedAddTime = false;
    _usedHint = false;
    _usedClearBombs = false;
    _matchesFound = 0;
    _first = null;
    _second = null;
    _timeRemaining = timeLimit;

    // ✅ Reset trạng thái thẻ
    for (final c in cards) {
      c.isFlipped = true; // Hiển thị preview
      c.isMatched = false;
    }
    notifyListeners();

    _previewTimer?.cancel();
    _postPreviewShuffleTimer?.cancel();
    _previewTimer = Timer(_previewDuration, () {
      if (!_isGameStarted) return;

      for (final c in cards) {
        if (!c.isMatched) {
          c.isFlipped = false;
        }
      }
      notifyListeners();

      _postPreviewShuffleTimer = Timer(_shuffleDelay, () {
        if (!_isGameStarted || !_isPreview) return;

        cards.shuffle();
        _isPreview = false;
        _inputLocked = false;
        _startTimer(onTimeUp);
        notifyListeners();
      });
    });
  }

  void _startTimer(VoidCallback onTimeUp) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_timeRemaining > 0) {
        _timeRemaining--;
        if (isLevelComplete()) {
          await _saveBestLevel();
          timer.cancel();
        }
      } else {
        _timer?.cancel();
        onTimeUp();
      }
      notifyListeners();
    });
  }

  Future<void> _saveBestLevel() async {
    final prefs = await SharedPreferences.getInstance();
    final best = prefs.getInt('bestLevel') ?? 1;
    if (level > best) {
      await prefs.setInt('bestLevel', level);
    }
  }

  void onCardTapped(CardModel card) {
    if (!_isGameStarted || _inputLocked || card.isFlipped || card.isMatched) {
      return;
    }

    // ✅ Nếu là thẻ bom
    if (card is BombCard) {
      card.flip();
      _timeRemaining -= card.penaltyTime;
      if (_timeRemaining < 0) _timeRemaining = 0;
      SoundManager().playBomb();
      notifyListeners();
      return;
    }

    // ✅ Thẻ thường
    card.flip();
    notifyListeners();

    if (_first == null) {
      _first = card;
      return;
    }

    _second = card;
    _inputLocked = true;

    if (_first!.id == _second!.id) {
      Future.delayed(const Duration(milliseconds: 350), () {
        _first!.match();
        _second!.match();
        _matchesFound++;
        _score += 20;
        _onMatch?.call();
        _resetSelection();
        _inputLocked = false;
        notifyListeners();
      });
    } else {
      _score -= 5;
      _onMismatch?.call();
      Future.delayed(const Duration(milliseconds: 700), () {
        _first?.flip();
        _second?.flip();
        _resetSelection();
        _inputLocked = false;
        notifyListeners();
      });
    }
  }

  void _resetSelection() {
    _first = null;
    _second = null;
  }

  bool isLevelComplete() => _matchesFound == _pairs;

  // ✅ Gợi ý: lật toàn bộ thẻ 3s
  void useHint() {
    if (!_isGameStarted || _isPreview || _usedHint) return;
    _inputLocked = true;
    _timeRemaining = (_timeRemaining - 10).clamp(0, timeLimit);
    _usedHint = true;

    for (final c in cards) {
      if (!c.isMatched) c.isFlipped = true;
    }
    notifyListeners();

    Future.delayed(const Duration(seconds: 3), () {
      if (!_isGameStarted) return;
      for (final c in cards) {
        if (!c.isMatched) c.isFlipped = false;
      }
      _resetSelection();
      _inputLocked = false;
      notifyListeners();
    });
  }

  // ✅ Cộng thời gian
  void addTime(int seconds) {
    if (!_isGameStarted || _usedAddTime) return;
    _timeRemaining += seconds;
    _usedAddTime = true;
    notifyListeners();
  }

  // ✅ Xóa thẻ bom khỏi bàn
  void clearBombs() {
    if (!_isGameStarted || _usedClearBombs) return;
    bool changed = false;
    for (final c in cards) {
      if (c is BombCard && !c.isMatched) {
        c.isMatched = true;
        changed = true;
      }
    }
    if (changed) {
      _usedClearBombs = true;
      notifyListeners();
    }
  }

  // Getters
  int get timeRemaining => _timeRemaining;
  bool get isGameStarted => _isGameStarted;
  bool get isPreview => _isPreview;
  bool get inputLocked => _inputLocked;
  int get score => _score;

  bool get canUseAddTime => _isGameStarted && !_isPreview && !_usedAddTime;
  bool get canUseHint => _isGameStarted && !_isPreview && !_usedHint;
  bool get canClearBombs => _isGameStarted && !_isPreview && !_usedClearBombs;

  @override
  void dispose() {
    _timer?.cancel();
    _previewTimer?.cancel();
    _postPreviewShuffleTimer?.cancel();
    super.dispose();
  }
}
