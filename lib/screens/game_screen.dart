// (full file content, unchanged except the small change inside _AnimatedBoard)
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'menu_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_level.dart';
import '../widgets/card_widget.dart';
import '../providers/sound_provider.dart';
import '../providers/history_provider.dart';

// Shared UI color
const kSkyBlue = Color(0xFF24A3B5);

class GameScreen extends StatefulWidget {
  final String? playerName;
  const GameScreen({super.key, this.playerName});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameLevel _gameLevel;
  late String _playerName;
  VideoPlayerController? _bgVc;
  bool _bgReady = false;
  int _gameBgIndex = 1; // 1 Syteam, 2 Dark, 3 Light
  final Random _rng = Random();
  @override
  void initState() {
    super.initState();
    _gameLevel = GameLevel(level: 1, initialScore: 0);
    _playerName = widget.playerName?.trim() ?? '';
    // Hỏi tên nếu chưa có
    if (_playerName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _promptForPlayerName(),
      );
    }
    _initGameBgVideo();
    _startLevel();
  }

  Future<void> _initGameBgVideo() async {
    final prefs = await SharedPreferences.getInstance();
    // hỗ trợ fallback từ khóa cũ nếu có
    _gameBgIndex =
        prefs.getInt('game_bg_index') ?? (prefs.getInt('menu_bg_index') ?? 1);
    final path = _videoPathFor(_gameBgIndex);
    try {
      final c = VideoPlayerController.asset(path);
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
      if (!mounted) return;
      setState(() {
        _bgVc = c;
        _bgReady = c.value.isInitialized;
      });
    } catch (_) {
      // ignore background video errors
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

  Future<void> _promptForPlayerName() async {
    final controller = TextEditingController();
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
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startLevel() {
    final sound = context.read<SoundProvider>();
    final history = context.read<HistoryProvider>();

    _gameLevel.startLevel(
      () {
        sound.playLose();
        history.addEntry(
          time: DateTime.now(),
          level: _gameLevel.level,
          result: 'lose',
          timeRemaining: _gameLevel.timeRemaining,
          score: _gameLevel.score,
        );
        history.updateBests(score: _gameLevel.score, level: _gameLevel.level);
        _showGameOverDialog();
      },
      onMatch: sound.playMatch,
      onMismatch: sound.playMismatch,
    );
  }

  void _nextLevel() {
    final history = context.read<HistoryProvider>();

    if (_gameLevel.level >= _gameLevel.slevel) {
      _showWinDialog();
      return;
    }

    history.addEntry(
      time: DateTime.now(),
      level: _gameLevel.level,
      result: 'clear',
      timeRemaining: _gameLevel.timeRemaining,
      score: _gameLevel.score,
    );
    history.updateBests(score: _gameLevel.score, level: _gameLevel.level);

    setState(() {
      _gameLevel.dispose();
      _gameLevel = GameLevel(
        level: _gameLevel.level + 1,
        initialScore: _gameLevel.score,
      );
    });

    _startLevel();
  }

  void _showGameOverDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thua cuộc'),
        content: const Text('Bạn đã hết thời gian! Chơi lại?'),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).pop();
              setState(() {
                _gameLevel.dispose();
                _gameLevel = GameLevel(level: 1, initialScore: 0);
              });
              _startLevel();
            },
            child: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }

  void _showWinDialog() {
    final sound = context.read<SoundProvider>();
    final history = context.read<HistoryProvider>();

    history.addEntry(
      time: DateTime.now(),
      level: _gameLevel.level,
      result: 'win',
      timeRemaining: _gameLevel.timeRemaining,
      score: _gameLevel.score,
    );
    history.updateBests(score: _gameLevel.score, level: _gameLevel.level);
    sound.playWin();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chiến thắng!'),
        content: Text('Bạn đã hoàn thành tất cả ${_gameLevel.slevel} level.'),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              Navigator.of(context).pop();
              setState(() {
                _gameLevel.dispose();
                _gameLevel = GameLevel(level: 1, initialScore: 0);
              });
              _startLevel();
            },
            child: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded),
            tooltip: 'Thoát',
            onPressed: () {
              _gameLevel.dispose();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MenuScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
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
          ChangeNotifierProvider.value(
            value: _gameLevel,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Consumer<GameLevel>(
                builder: (context, game, _) {
                  if (game.isLevelComplete()) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _nextLevel();
                    });
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      // Khoảng cách ngang (giữa CỘT) và dọc (giữa HÀNG)
                      final hSpacing = 1.0; // cột: sát
                      final vSpacing = 1.0; // hàng: rộng thêm một xíu
                      final spacing =
                          hSpacing; // dùng cho các tính toán cũ phía trên
                      const paddingAll = 1.0;
                      const desiredCardSize = 140.0;
                      final itemCount = game.cards.length;

                      final maxWidth = constraints.maxWidth;
                      final maxHeight = constraints.maxHeight;
                      final availableWidthForGrid = maxWidth - (paddingAll * 2);
                      int crossAxis = ((availableWidthForGrid + spacing) /
                              (desiredCardSize + spacing))
                          .floor();
                      if (crossAxis < 2) crossAxis = 2;
                      if (crossAxis > itemCount) crossAxis = itemCount;

                      final int maxColumns =
                          maxWidth < 500 ? 3 : (maxWidth < 800 ? 4 : 5);
                      if (crossAxis > maxColumns) crossAxis = maxColumns;

                      int tentativeRows = (itemCount / crossAxis).ceil();
                      while (tentativeRows > 5 &&
                          crossAxis < maxColumns &&
                          crossAxis < itemCount) {
                        crossAxis++;
                        tentativeRows = (itemCount / crossAxis).ceil();
                      }

                      int rows;
                      double cardSize;
                      while (true) {
                        final totalHSpacing = hSpacing * (crossAxis + 1);
                        final widthForCards =
                            maxWidth - (paddingAll * 2) - totalHSpacing;
                        cardSize = widthForCards / crossAxis;

                        rows = (itemCount / crossAxis).ceil();
                        final totalVSpacing = vSpacing * (rows + 1);
                        final heightNeeded =
                            rows * cardSize + totalVSpacing + (paddingAll * 2);

                        if (heightNeeded <= maxHeight || crossAxis <= 2) {
                          break;
                        }
                        crossAxis--;
                      }

                      final double boardMaxWidth = constraints.maxWidth;
                      const double headerApprox = 100.0;
                      const double bottomApprox = 60.0;
                      const double verticalMargins = 20.0;
                      final double availableForBoard = (constraints.maxHeight -
                              headerApprox -
                              bottomApprox -
                              verticalMargins)
                          .clamp(360.0, constraints.maxHeight);
                      final double boardHeight = availableForBoard;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: boardMaxWidth),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF24A3B5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: game,
                                    builder: (context, _) {
                                      return Wrap(
                                        spacing: 12,
                                        runSpacing: 6,
                                        children: [
                                          _InfoChip(
                                            label: 'Người chơi',
                                            value: _playerName.isEmpty
                                                ? '---'
                                                : _playerName,
                                          ),
                                          _InfoChip(
                                            label: 'Level',
                                            value: '${game.level}',
                                          ),
                                          _InfoChip(
                                            label: 'Điểm',
                                            value: '${game.score}',
                                          ),
                                          _InfoChip(
                                            label: 'Thời gian',
                                            value: _formatTime(
                                              game.timeRemaining,
                                            ),
                                          ),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                              backgroundColor:
                                                  Colors.teal.shade700,
                                            ),
                                            onPressed: () {
                                              _gameLevel.dispose();
                                              Navigator.of(
                                                context,
                                              ).pushAndRemoveUntil(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const MenuScreen(),
                                                ),
                                                (route) => false,
                                              );
                                            },
                                            child: const Text('Về menu'),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // 🎨 Board trong suốt
                                Flexible(
                                  child: LayoutBuilder(
                                    builder: (context, outer) {
                                      final double boardWidth =
                                          outer.maxWidth * 0.68;
                                      // Chọn kích thước hình vuông vừa với không gian còn lại
                                      final double boardSize =
                                          boardWidth < boardHeight
                                              ? boardWidth
                                              : boardHeight;

                                      return Align(
                                        alignment: Alignment.topCenter,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 8,
                                              sigmaY: 8,
                                            ),
                                            child: Container(
                                              width: boardSize,
                                              height: boardSize,
                                              padding: EdgeInsets.zero,
                                              decoration: BoxDecoration(
                                                // ignore: deprecated_member_use
                                                color: Colors.white
                                                    .withValues(alpha: 0.06),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.white
                                                      // ignore: deprecated_member_use
                                                      .withValues(alpha: 0.1),
                                                ),
                                              ),
                                              child: _AnimatedBoard(
                                                game: game,
                                                itemCount: itemCount,
                                                boardSize: boardSize,
                                                hSpacing: hSpacing,
                                                vSpacing: vSpacing,
                                                posMap: const [],
                                                slotPositions: const [],
                                                onRequireLayout: (_, __) {},
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Bottom: one Help button opens three options
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _BottomBtn(
                                      label: 'Trợ giúp',
                                      onTap: () {
                                        showModalBottomSheet<void>(
                                          context: context,
                                          showDragHandle: true,
                                          builder: (ctx) {
                                            final btnStyle =
                                                ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  kSkyBlue, // xanh da trời
                                              foregroundColor:
                                                  const Color.fromARGB(
                                                255,
                                                87,
                                                84,
                                                84,
                                              ),
                                              minimumSize: const Size(
                                                double.infinity,
                                                48,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  10,
                                                ),
                                              ),
                                            );
                                            return SafeArea(
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromARGB(
                                                      255,
                                                      58,
                                                      58,
                                                      58,
                                                    ).withValues(alpha: 0.06),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      16,
                                                    ),
                                                    border: Border.all(
                                                      color: kSkyBlue,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                ElevatedButton
                                                                    .icon(
                                                              style: btnStyle,
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                  ctx,
                                                                );
                                                                game.addTime(
                                                                  10,
                                                                );
                                                              },
                                                              icon: const Icon(
                                                                Icons.add_alarm,
                                                              ),
                                                              label: const Text(
                                                                '+10 giây',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                ElevatedButton
                                                                    .icon(
                                                              style: btnStyle,
                                                              onPressed:
                                                                  game.canUseHint
                                                                      ? () {
                                                                          Navigator
                                                                              .pop(
                                                                            ctx,
                                                                          );
                                                                          game.useHint();
                                                                        }
                                                                      : null,
                                                              icon: const Icon(
                                                                Icons
                                                                    .visibility,
                                                              ),
                                                              label: const Text(
                                                                'Mở hết 3 giây',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                ElevatedButton
                                                                    .icon(
                                                              style: btnStyle,
                                                              onPressed:
                                                                  game.canClearBombs
                                                                      ? () {
                                                                          Navigator
                                                                              .pop(
                                                                            ctx,
                                                                          );
                                                                          game.clearBombs();
                                                                        }
                                                                      : null,
                                                              icon: const Icon(
                                                                Icons
                                                                    .delete_sweep,
                                                              ),
                                                              label: const Text(
                                                                'Xoá bomb',
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameLevel.dispose();
    _bgVc?.dispose();
    super.dispose();
  }
}

// Replace the _AnimatedBoard's item generation so each CardWidget uses card.uid as key.
// Below is the _AnimatedBoard class (replace the existing one in game_screen.dart)

class _AnimatedBoard extends StatelessWidget {
  final GameLevel game;
  final int itemCount;
  final double boardSize;
  final double hSpacing;
  final double vSpacing;
  final List<int> posMap; // ánh xạ: index thẻ -> index slot
  final List<Offset> slotPositions; // vị trí toạ độ của slot
  final void Function(List<Offset> slots, List<int> map) onRequireLayout;

  const _AnimatedBoard({
    required this.game,
    required this.itemCount,
    required this.boardSize,
    required this.hSpacing,
    required this.vSpacing,
    required this.posMap,
    required this.slotPositions,
    required this.onRequireLayout,
  });

  @override
  Widget build(BuildContext context) {
    const int cols = 5;
    const int rows = 5;
    final totalSlots = rows * cols;

    // Tính kích thước ô vuông theo khoảng cách và viền
    final cellSize = (boardSize - (cols + 1) * hSpacing) / cols;

    // Khởi tạo toạ độ slot nếu chưa có hoặc thay đổi kích thước
    List<Offset> slots = slotPositions;
    if (slots.length != totalSlots) {
      final list = <Offset>[];
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final left = hSpacing + c * (cellSize + hSpacing);
          final top = vSpacing + r * (cellSize + vSpacing);
          list.add(Offset(left, top));
        }
      }
      // Map mặc định: thẻ i đặt vào slot i
      final map = List<int>.generate(itemCount, (i) => i);
      // Gửi lại cho parent lưu
      onRequireLayout(list, map);
      slots = list;
    }

    // Đảm bảo posMap có đủ phần tử cho itemCount
    List<int> map = posMap;
    if (map.length != itemCount) {
      map = List<int>.generate(itemCount, (i) => i);
      onRequireLayout(slots, map);
    }

    return SizedBox(
      width: boardSize,
      height: boardSize,
      child: Stack(
        children: List.generate(itemCount, (index) {
          // Lấy vị trí hiển thị dựa trên map
          final slotIndex = (index < map.length) ? map[index] : index;
          final pos = (slotIndex < slots.length)
              ? slots[slotIndex]
              : const Offset(0, 0);

          // Quan trọng: Luôn sử dụng card tương ứng với index gốc, không phụ thuộc vào vị trí
          final card = game.cards[index];

          return AnimatedPositioned(
            key: ValueKey(card.uid),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            left: pos.dx,
            top: pos.dy,
            width: cellSize,
            height: cellSize,
            child: CardWidget(
              card: card,
            ),
          );
        }),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BottomBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF24A3B5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
