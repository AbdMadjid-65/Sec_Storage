// ============================================================
// PriVault – Crypto Utilities
// ============================================================
// Helpers for nonce generation, constant-time comparison,
// base64 encoding, and other crypto primitives.
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

/// Crypto utility functions.
class CryptoUtils {
  CryptoUtils._();

  /// Generate a cryptographically secure random nonce.
  static Uint8List generateNonce(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }

  /// Constant-time byte comparison to prevent timing attacks.
  static bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Generate a cryptographically secure random key.
  static Uint8List generateKey([int length = 32]) {
    return generateNonce(length);
  }

  /// Encode bytes to URL-safe base64.
  static String toBase64(Uint8List data) {
    return base64Url.encode(data);
  }

  /// Decode URL-safe base64 to bytes.
  static Uint8List fromBase64(String encoded) {
    return base64Url.decode(encoded);
  }

  /// Concatenate two byte arrays.
  static Uint8List concat(Uint8List a, Uint8List b) {
    final result = Uint8List(a.length + b.length);
    result.setAll(0, a);
    result.setAll(a.length, b);
    return result;
  }

  /// Securely wipe a byte array (best-effort on Dart VM).
  static void secureWipe(Uint8List data) {
    for (int i = 0; i < data.length; i++) {
      data[i] = 0;
    }
  }
}
