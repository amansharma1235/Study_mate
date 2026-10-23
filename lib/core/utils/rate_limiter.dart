import 'dart:math';

/// Result returned by [RateLimiter] indicating allowance and cooldown duration.
class RateLimitResult {
  final bool isAllowed;
  final int remainingAttempts;
  final Duration resetIn;
  final String? errorMessage;

  const RateLimitResult({
    required this.isAllowed,
    required this.remainingAttempts,
    required this.resetIn,
    this.errorMessage,
  });

  int get resetSeconds => max(1, resetIn.inSeconds);
}

/// Client-side rate limiting and throttling manager.
/// Protects authentication endpoints, password resets, AI queries, and cloud synchronization
/// from spamming, rapid double-tapping, and brute-force attacks.
class RateLimiter {
  RateLimiter._();
  static final RateLimiter instance = RateLimiter._();

  final Map<String, List<DateTime>> _attemptHistory = {};
  final Map<String, DateTime> _cooldowns = {};

  /// Checks whether an action can be executed within a sliding window of [maxAttempts] per [window].
  RateLimitResult checkLimit(
    String key, {
    int maxAttempts = 5,
    Duration window = const Duration(minutes: 1),
    String? customErrorMessage,
  }) {
    final now = DateTime.now();
    final cutoff = now.subtract(window);

    // Retrieve previous attempts and filter out expired timestamps
    final attempts = _attemptHistory[key] ?? [];
    attempts.removeWhere((t) => t.isBefore(cutoff));
    _attemptHistory[key] = attempts;

    if (attempts.length >= maxAttempts) {
      final oldest = attempts.first;
      final resetIn = window - now.difference(oldest);
      final waitSec = max(1, resetIn.inSeconds);

      return RateLimitResult(
        isAllowed: false,
        remainingAttempts: 0,
        resetIn: resetIn,
        errorMessage: customErrorMessage ??
            'Too many attempts. Please wait $waitSec seconds before trying again.',
      );
    }

    // Record this attempt
    attempts.add(now);
    return RateLimitResult(
      isAllowed: true,
      remainingAttempts: maxAttempts - attempts.length,
      resetIn: Duration.zero,
    );
  }

  /// Throttles actions with a strict consecutive cooldown.
  RateLimitResult throttle(
    String key, {
    Duration cooldown = const Duration(seconds: 2),
    String? customErrorMessage,
  }) {
    final now = DateTime.now();
    final lastTime = _cooldowns[key];

    if (lastTime != null) {
      final difference = now.difference(lastTime);
      if (difference < cooldown) {
        final remaining = cooldown - difference;
        final waitSec = max(1, remaining.inSeconds);

        return RateLimitResult(
          isAllowed: false,
          remainingAttempts: 0,
          resetIn: remaining,
          errorMessage: customErrorMessage ??
              'Please wait $waitSec second(s) before requesting again.',
        );
      }
    }

    _cooldowns[key] = now;
    return RateLimitResult(
      isAllowed: true,
      remainingAttempts: 1,
      resetIn: Duration.zero,
    );
  }

  /// Resets rate limits for a key (e.g. on successful login).
  void reset(String key) {
    _attemptHistory.remove(key);
    _cooldowns.remove(key);
  }
}
