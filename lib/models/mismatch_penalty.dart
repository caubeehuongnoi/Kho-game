class MismatchPenalty {
  static const int timePenaltySeconds = 3;

  static int apply(int currentTime) {
    final remaining = currentTime - timePenaltySeconds;
    return remaining < 0 ? 0 : remaining;
  }
}
