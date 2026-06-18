import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

/// Passphrase-based AES-256-CBC encryption for optional encrypted cloud
/// backups. The 256-bit key is derived from the user's passphrase via SHA-256
/// and a fresh random IV is generated per payload and stored alongside the
/// ciphertext.
///
/// This protects backups at rest in the cloud against casual access. For a
/// hardened deployment, swap SHA-256 key derivation for a memory-hard KDF
/// (e.g. Argon2) and an AEAD mode (GCM) — see final_audit/security_audit.md.
class EncryptionService {
  const EncryptionService();

  static const String marker = 'habitview-enc-v1';

  Map<String, String> encryptText(String plaintext, String passphrase) {
    final key = _deriveKey(passphrase);
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return {
      'marker': marker,
      'iv': iv.base64,
      'ciphertext': encrypted.base64,
    };
  }

  String decryptPayload(Map<String, dynamic> payload, String passphrase) {
    final key = _deriveKey(passphrase);
    final iv = IV.fromBase64(payload['iv'] as String);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    return encrypter.decrypt64(payload['ciphertext'] as String, iv: iv);
  }

  bool isEncrypted(Map<String, dynamic> payload) => payload['marker'] == marker;

  /// Derives a 32-byte (AES-256) key from the passphrase via SHA-256.
  Key _deriveKey(String passphrase) {
    final digest = sha256.convert(utf8.encode(passphrase));
    return Key(Uint8List.fromList(digest.bytes));
  }
}
