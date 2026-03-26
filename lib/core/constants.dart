// ============================================================
// PriVault – App-Wide Constants
// ============================================================
// All encryption parameters, storage limits, plan tiers, and
// API configuration constants live here.
// ============================================================

/// Encryption constants for Argon2id key derivation.
class CryptoConstants {
  CryptoConstants._();

  /// Argon2id salt length in bytes.
  static const int argon2SaltLength = 16;

  /// Argon2id iterations (time cost).
  static const int argon2Iterations = 3;

  /// Argon2id memory cost in KB (64 MB).
  static const int argon2MemoryKB = 65536;

  /// Argon2id parallelism (lanes).
  static const int argon2Parallelism = 4;

  /// Derived master key length in bytes (256-bit).
  static const int masterKeyLength = 32;

  /// XChaCha20-Poly1305 nonce length in bytes.
  static const int nonceLength = 24;

  /// HKDF info strings for sub-key derivation.
  static const String hkdfInfoFiles = 'privault-files-v1';
  static const String hkdfInfoChat = 'privault-chat-v1';
  static const String hkdfInfoNotes = 'privault-notes-v1';
  static const String hkdfInfoVault = 'privault-vault-v1';
  static const String hkdfInfoCalendar = 'privault-calendar-v1';

  /// File encryption chunk size (5 MB).
  static const int fileChunkSize = 5 * 1024 * 1024;

  /// Recovery phrase word count.
  static const int recoveryPhraseWordCount = 24;
}

/// Storage plan tiers and limits (BR-04, BR-05).
class StoragePlans {
  StoragePlans._();

  /// Free tier: 3 GB (BR-04).
  static const int freeStorageBytes = 3 * 1024 * 1024 * 1024;

  /// Premium tier: 20 GB (BR-05).
  static const int premiumStorageBytes = 20 * 1024 * 1024 * 1024;

  /// Professional tier: Unlimited (BR-05) – represented as 1 TB cap.
  static const int professionalStorageBytes = 1024 * 1024 * 1024 * 1024;

  /// Premium monthly price (BR-05).
  static const double premiumMonthlyPrice = 19.00;

  /// Professional monthly price (BR-05).
  static const double professionalMonthlyPrice = 49.00;

  /// Returns max storage bytes for a given plan name.
  static int maxBytesForPlan(String? plan) {
    switch (plan) {
      case 'premium':
        return premiumStorageBytes;
      case 'professional':
        return professionalStorageBytes;
      default:
        return freeStorageBytes;
    }
  }
}

/// App-level configuration.
class AppConstants {
  AppConstants._();

  /// App name.
  static const String appName = 'PriVault';

  /// Recycle bin auto-purge days.
  static const int recycleBinRetentionDays = 30;

  /// Auto-lock timeout in minutes (BR-11: 2 minutes).
  static const int autoLockTimeoutMinutes = 2;

  /// Maximum chat group size.
  static const int maxGroupChatMembers = 200;

  /// Message edit window in minutes.
  static const int messageEditWindowMinutes = 15;

  /// Maximum share link downloads (default).
  static const int defaultMaxDownloads = 100;

  /// Supported preview file extensions.
  static const List<String> imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'heic',
    'heif',
  ];
  static const List<String> videoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
  ];
  static const List<String> documentExtensions = [
    'pdf',
    'txt',
    'md',
    'csv',
    'json',
  ];
}
