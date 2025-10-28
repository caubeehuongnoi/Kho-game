import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundPath =
        isDark ? 'assets/backgrounds/dark.gif' : 'assets/backgrounds/light.gif';
    final colorScheme = Theme.of(context).colorScheme; // Get color scheme once

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng xếp hạng'),
        actions: [
          IconButton(
            tooltip: 'Xóa lịch sử',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Xóa lịch sử?'),
                  content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // The 'ignore: use_build_context_synchronously' is necessary
                // here because 'await showDialog' breaks the immediate sync context.
                // However, since we're using read<T> on the context, which doesn't
                // rebuild the widget, it's generally safe in this specific pattern.
                // ignore: use_build_context_synchronously
                await context.read<HistoryProvider>().clear();
              }
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          Consumer<HistoryProvider>(
            builder: (context, history, child) {
              return Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withAlpha(217),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colorScheme.outline.withAlpha(128),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(31),
                              blurRadius: 16,
                              spreadRadius: 1,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.leaderboard_outlined),
                                const SizedBox(width: 12),
                                Text(
                                  'Thành tích cao nhất',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: const _PlayerNameTile(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatTile(
                                    label: 'Điểm cao nhất',
                                    value: history.bestScore.toString(),
                                    icon: Icons.star_rate_rounded,
                                    color: Colors.amber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatTile(
                                    label: 'Level cao nhất',
                                    value: history.bestLevel.toString(),
                                    icon: Icons.trending_up_rounded,
                                    color: Colors.cyan,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlayerNameTile extends StatelessWidget {
  const _PlayerNameTile();

  Future<String> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = (prefs.getString('player_name') ?? '').trim();
    if (raw.isEmpty) return 'Chưa đặt tên';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadName(),
      builder: (context, snapshot) {
        final name = snapshot.connectionState == ConnectionState.done
            ? (snapshot.data ?? 'Chưa đặt tên')
            : 'Đang tải...';
        return _StatTile(
          label: 'Tên nhân vật',
          value: name,
          icon: Icons.person_outline,
          color: Colors.purple,
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    // ignore: unused_element_parameter
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.surface.withAlpha(230),
            scheme.surfaceContainerHighest.withAlpha(217),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withAlpha(128), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(38),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
