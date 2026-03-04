// ============================================================
// PriVault – Auth Service (HTTP API)
// ============================================================
// Handles authentication via Node.js REST API.
// ============================================================

import 'dart:typed_data';
import 'package:pri_vault/core/api/api_client.dart';
import 'package:pri_vault/core/encryption/key_derivation.dart';
import 'package:pri_vault/core/encryption/crypto_utils.dart';
import 'package:pri_vault/core/encryption/encryption_service.dart';
import 'package:pri_vault/services/vault_service.dart';

class AuthService {
  final ApiClient _api;
  final VaultService _vault;
  final EncryptionService _encryptionService;

  AuthService(this._api, this._vault, this._encryptionService);

  /// Sign up a new user securely.
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String accountType = 'regular',
  }) async {
    // 1. Generate salt and derive master key (client-side)
    final salt = KeyDerivation.generateSalt();
    final masterKey = await KeyDerivation.deriveMasterKey(
      password: password,
      salt: salt,
    );

    // 2. Generate key pair for sharing
    final keyPair = await _encryptionService.generateKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKey = await keyPair.extractPrivateKeyBytes();

    // 3. Register via API
    final response = await _api.post('/auth/register', body: {
      'email': email,
      'password': password,
      'account_type': accountType,
      'salt': CryptoUtils.toBase64(salt),
      'public_key':
          CryptoUtils.toBase64(Uint8List.fromList(publicKey.bytes)),
    });

    // 4. Save token
    if (response['token'] != null) {
      await _api.saveToken(response['token']);
    }
    if (response['user']?['id'] != null) {
      await _api.saveUserId(response['user']['id']);
    }

    // 5. Store Master Key and Private Key locally
    await _vault.saveMasterKeySeed(CryptoUtils.toBase64(masterKey));
    await _vault.saveSharingPrivateKey(
        CryptoUtils.toBase64(Uint8List.fromList(privateKey)));

    return response;
  }

  /// Sign in an existing user securely.
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    String? deviceFingerprint,
    String? deviceName,
    String? deviceType,
  }) async {
    // 1. Authenticate via API
    final response = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
      'device_fingerprint': deviceFingerprint,
      'device_name': deviceName,
      'device_type': deviceType,
    });

    // Check if 2FA is required
    if (response['requires_2fa'] == true) {
      return response; // Caller must handle 2FA flow
    }

    // 2. Save token
    if (response['token'] != null) {
      await _api.saveToken(response['token']);
    }
    if (response['user']?['id'] != null) {
      await _api.saveUserId(response['user']['id']);
    }

    // 3. Derive master key from the salt in the profile
    final user = response['user'] as Map<String, dynamic>;
    final saltBase64 = user['salt'] as String?;
    if (saltBase64 != null) {
      final salt = CryptoUtils.fromBase64(saltBase64);
      final masterKey = await KeyDerivation.deriveMasterKey(
        password: password,
        salt: salt,
      );
      await _vault.saveMasterKeySeed(CryptoUtils.toBase64(masterKey));
    }

    return response;
  }

  /// Verify 2FA code.
  Future<Map<String, dynamic>> verify2FA({
    required String userId,
    required String code,
    String? deviceFingerprint,
    String? deviceName,
    String? deviceType,
  }) async {
    final response = await _api.post('/auth/verify-2fa', body: {
      'user_id': userId,
      'code': code,
      'device_fingerprint': deviceFingerprint,
      'device_name': deviceName,
      'device_type': deviceType,
    });

    if (response['token'] != null) {
      await _api.saveToken(response['token']);
    }
    if (response['user']?['id'] != null) {
      await _api.saveUserId(response['user']['id']);
    }

    return response;
  }

  /// Sign out and clear secure vault.
  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.clearToken();
    try {
      await _vault.deleteMasterKeySeed();
      await _vault.deleteSharingPrivateKey();
    } catch (_) {}
  }

  /// Check if user is already authenticated (has valid token).
  Future<bool> isAuthenticated() async {
    final token = await _api.getToken();
    return token != null;
  }

  /// Request a password-reset OTP code via email.
  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    return await _api.post('/auth/forgot-password', body: {'email': email});
  }

  /// Verify the OTP code and get a short-lived reset token.
  Future<Map<String, dynamic>> verifyResetCode({
    required String email,
    required String code,
  }) async {
    return await _api.post('/auth/verify-reset-code', body: {
      'email': email,
      'code': code,
    });
  }

  /// Reset the password using the reset token.
  Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    return await _api.post('/auth/reset-password', body: {
      'reset_token': resetToken,
      'new_password': newPassword,
    });
  }
}
