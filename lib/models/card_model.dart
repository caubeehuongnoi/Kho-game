/// - [id]: định danh cặp. Hai lá thuộc cùng cặp sẽ có cùng id.
/// - [imagePath]: đường dẫn ảnh mặt trước của lá bài.
/// - [isFlipped]: trạng thái đang lật hay không.
/// - [isMatched]: đã được ghép đúng và ẩn khỏi bàn hay chưa.
class CardModel {
  static int _uidCounter = 0; // counter để sinh uid cho từng instance

  final int uid; // unique instance id (dùng làm ValueKey ổn định)
  final int id;
  final String imagePath;
  bool isFlipped;
  bool isMatched;

  CardModel({
    required this.id,
    required this.imagePath,
    this.isFlipped = false,
    this.isMatched = false,
  }) : uid = _uidCounter++;

  /// Đảo trạng thái lật của lá bài.
  void flip() {
    // ⚙️ Nếu đã matched rồi thì không cho lật lại (tránh lỗi hiển thị)
    if (isMatched) return;
    isFlipped = !isFlipped;
  }

  /// Đánh dấu lá bài đã ghép đúng.
  void match() {
    isMatched = true;
    isFlipped = true; // giữ mặt ngửa sau khi ghép đúng
  }
}

/// Thẻ Bom (xuất hiện từ level 3 trở đi).
/// Khi người chơi lật trúng thẻ này sẽ bị trừ [penaltyTime] giây.
class BombCard extends CardModel {
  final int penaltyTime;

  BombCard({
    required super.id,
    required super.imagePath,
    this.penaltyTime = 5, // mặc định trừ 5 giây
  });

  /// Kích hoạt bom: trả về số giây bị trừ.
  int activate() => penaltyTime;

  @override
  void match() {
    // Nếu bom bị loại (clearBombs), coi như ẩn hoàn toàn
    isMatched = true;
    isFlipped = true;
  }
}