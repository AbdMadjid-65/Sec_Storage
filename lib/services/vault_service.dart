// ============================================================
// PriVault – Vault Service
// ============================================================
// Handles secure local storage of sensitive keys/seeds and
// integrates with local_auth for biometric protection.
// ============================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Secure storage service for PriVault.
class VaultService {
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  static const String _masterKeySeedKey = 'privault_master_key_seed';
  static const String _sharingPrivateKeyKey = 'privault_sharing_private_key';

  /// Authenticate the user via biometrics or device PIN/pattern.
  Future<bool> authenticateUser({
    String reason = 'Authenticate to access your vault',
  }) async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        // If device has no security, we either fail or bypass.
        // For maximum security, we'd fail, but for usability we might bypass
        // depending on app settings. For now, bypass if not supported.
        return true;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      // In case of any PlatformException, return false to deny access
      return false;
    }
  }

  /// Save the master key seed securely. Requires authentication.
  Future<void> saveMasterKeySeed(String seed) async {
    final isAuthenticated = await authenticateUser(
      reason: 'Authenticate to save your vault key',
    );
    if (!isAuthenticated) {
      throw Exception('Authentication failed');
    }
    await _secureStorage.write(key: _masterKeySeedKey, value: seed);
  }

  /// Retrieve the master key seed securely. Requires authentication.
  Future<String?> getMasterKeySeed() async {
    final isAuthenticated = await authenticateUser(
      reason: 'Authenticate to unlock your vault',
    );
    if (!isAuthenticated) {
      throw Exception('Authentication failed');
    }
    return await _secureStorage.read(key: _masterKeySeedKey);
  }

  /// Save the sharing private key securely.
  Future<void> saveSharingPrivateKey(String privateKey) async {
    await _secureStorage.write(key: _sharingPrivateKeyKey, value: privateKey);
  }

  /// Retrieve the sharing private key securely.
  Future<String?> getSharingPrivateKey() async {
    return await _secureStorage.read(key: _sharingPrivateKeyKey);
  }

  /// Delete the sharing private key.
  Future<void> deleteSharingPrivateKey() async {
    await _secureStorage.delete(key: _sharingPrivateKeyKey);
  }

  /// Delete the master key seed securely. Requires authentication.
  Future<void> deleteMasterKeySeed() async {
    final isAuthenticated = await authenticateUser(
      reason: 'Authenticate to delete your vault key',
    );
    if (!isAuthenticated) {
      throw Exception('Authentication failed');
    }
    await _secureStorage.delete(key: _masterKeySeedKey);
  }
}
