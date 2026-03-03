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

/// Storage plan tiers and limits.
class StoragePlans {
  StoragePlans._();

  /// Free tier: 5 GB.
  static const int freeStorageBytes = 5 * 1024 * 1024 * 1024;

  /// Plus tier: 2 TB.
  static const int plusStorageBytes = 2 * 1024 * 1024 * 1024 * 1024;

  /// Family tier: 10 TB.
  static const int familyStorageBytes = 10 * 1024 * 1024 * 1024 * 1024;

  /// Plus monthly price.
  static const double plusMonthlyPrice = 4.99;

  /// Plus yearly price.
  static const double plusYearlyPrice = 49.00;

  /// Family monthly price.
  static const double familyMonthlyPrice = 9.99;
}

/// App-level configuration.
class AppConstants {
  AppConstants._();

  /// App name.
  static const String appName = 'PriVault';

  /// Recycle bin auto-purge days.
  static const int recycleBinRetentionDays = 30;

  /// Auto-lock timeout in minutes.
  static const int autoLockTimeoutMinutes = 5;

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
