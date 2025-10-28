import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý lịch sử chơi game, lưu trữ dưới dạng JSON trong SharedPreferences.
class HistoryProvider extends ChangeNotifier {
  static const _prefsKey = 'history_records_v1';
  static const _bestScoreKey = 'history_best_score_v1';
  static const _bestLevelKey = 'history_best_level_v1';
  final List<HistoryEntry> _entries = [];
  int _bestScore = 0;
  int _bestLevel = 1;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  HistoryProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _entries
          ..clear()
          ..addAll(list.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // Nếu dữ liệu bị lỗi, bỏ qua
      }
    }
    _bestScore = prefs.getInt(_bestScoreKey) ?? 0;
    _bestLevel = prefs.getInt(_bestLevelKey) ?? 1;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_entries.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  Future<void> addEntry({
    required DateTime time,
    required int level,
    required String result, // 'win' | 'lose' | 'clear'
    required int timeRemaining,
    required int score,
  }) async {
    _entries.insert(
      0,
      HistoryEntry(
        time: time,
        level: level,
        result: result,
        timeRemaining: timeRemaining,
        score: score,
      ),
    );
    await _save();
    notifyListeners();
  }

  Future<void> updateBests({required int score, required int level}) async {
    bool changed = false;
    if (score > _bestScore) {
      _bestScore = score;
      changed = true;
    }
    if (level > _bestLevel) {
      _bestLevel = level;
      changed = true;
    }
    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestScoreKey, _bestScore);
      await prefs.setInt(_bestLevelKey, _bestLevel);
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _entries.clear();
    _bestScore = 0;
    _bestLevel = 1;
    await _save();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bestScoreKey);
    await prefs.remove(_bestLevelKey);
    notifyListeners();
  }

  int get bestScore => _bestScore;
  int get bestLevel => _bestLevel;
}

/// Một bản ghi lịch sử chơi game.
class HistoryEntry {
  final DateTime time;
  final int level;
  final String result; // 'win' | 'lose' | 'clear'
  final int timeRemaining;
  final int score;

  HistoryEntry({
    required this.time,
    required this.level,
    required this.result,
    required this.timeRemaining,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'level': level,
        'result': result,
        'timeRemaining': timeRemaining,
        'score': score,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
        level: json['level'] as int? ?? 1,
        result: json['result'] as String? ?? 'clear',
        timeRemaining: json['timeRemaining'] as int? ?? 0,
        score: json['score'] as int? ?? 0,
      );
}