import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_model.dart';
import '../models/game_level.dart';
import '../providers/sound_provider.dart';

class CardWidget extends StatefulWidget {
  final CardModel card;

  const CardWidget({
    super.key,
    required this.card,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // Đồng bộ trạng thái khởi tạo theo card
    if (widget.card.isFlipped) {
      _controller.value = 1; // mặt trước
    } else {
      _controller.value = 0; // mặt sau
    }
  }

  @override
  void didUpdateWidget(covariant CardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Nếu widget đang được tái sử dụng cho card khác (theo uid), reset controller
    // So sánh uid thay vì identity để an toàn khi CardModel có thể được recreate.
    final oldUid = oldWidget.card.uid;
    final newUid = widget.card.uid;

    if (oldUid != newUid) {
      if (widget.card.isFlipped) {
        _controller.value = 1;
      } else {
        _controller.value = 0;
      }
      _controller.stop();
      return;
    }

    // Khi cùng card nhưng flip thay đổi => chạy animation
    if (widget.card.isFlipped) {
      if (_controller.status != AnimationStatus.forward &&
          _controller.value != 1) {
        _controller.forward();
      }
    } else {
      if (_controller.status != AnimationStatus.reverse &&
          _controller.value != 0) {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameLevel>(context, listen: false);
    final sound = Provider.of<SoundProvider>(context, listen: false);

    if (widget.card.isMatched) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        sound.playFlip();
        game.onCardTapped(widget.card);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final showFront = angle > (pi / 2); // đổi logic: 0 = back, 1 = front
          final bgColor = Colors.white.withValues(alpha: 0.12);

          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildSide(
                    visible: !showFront,
                    angle: angle,
                    child: _buildBack(),
                  ),
                  _buildSide(
                    visible: showFront,
                    angle: angle + pi,
                    child: _buildFront(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSide({
    required bool visible,
    required double angle,
    required Widget child,
  }) {
    return Opacity(
      opacity: visible ? 1 : 0,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle),
        child: child,
      ),
    );
  }

  Widget _buildFront() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              widget.card.imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.orange,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              'assets/cards/NenThe1.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.blueGrey,
                alignment: Alignment.center,
                child: const Icon(Icons.help_outline, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}