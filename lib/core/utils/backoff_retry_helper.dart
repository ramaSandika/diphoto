import 'dart:async';
import 'dart:math';

class BackoffRetryHelper {
  /// Eksekusi fungsi async dengan algoritma Exponential Backoff + Jitter
  static Future<T> retry<T>({
    required Future<T> Function() action,
    int maxAttempts = 4,
    Duration initialDelay = const Duration(milliseconds: 800),
    double backoffFactor = 2.0,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;
    final random = Random();

    while (true) {
      try {
        attempt++;
        return await action();
      } catch (error) {
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Tambahkan jitter acak (0-200ms) untuk mencegah collision request
        final jitter = Duration(milliseconds: random.nextInt(200));
        final delayWithJitter = currentDelay + jitter;

        await Future.delayed(delayWithJitter);
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffFactor).toInt(),
        );
      }
    }
  }
}
