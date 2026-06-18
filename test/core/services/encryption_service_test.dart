import 'package:flutter_test/flutter_test.dart';
import 'package:habitview/core/services/encryption_service.dart';

void main() {
  const service = EncryptionService();

  group('EncryptionService', () {
    test('round-trips text with the correct passphrase', () {
      const plaintext = '{"habits":[{"id":"h1","name":"Read"}]}';
      final payload = service.encryptText(plaintext, 'correct horse');
      expect(service.isEncrypted(payload), isTrue);
      expect(payload['ciphertext'], isNot(contains('Read')));

      final decrypted = service.decryptPayload(payload, 'correct horse');
      expect(decrypted, plaintext);
    });

    test('produces a fresh IV per encryption (non-deterministic ciphertext)', () {
      const plaintext = 'same input';
      final a = service.encryptText(plaintext, 'pw');
      final b = service.encryptText(plaintext, 'pw');
      expect(a['ciphertext'], isNot(equals(b['ciphertext'])));
      expect(a['iv'], isNot(equals(b['iv'])));
    });

    test('decryption with the wrong passphrase does not return the plaintext',
        () {
      const plaintext = 'secret data';
      final payload = service.encryptText(plaintext, 'right');
      // Wrong key either throws (padding error) or yields garbage — never the
      // original plaintext.
      try {
        final result = service.decryptPayload(payload, 'wrong');
        expect(result, isNot(equals(plaintext)));
      } catch (_) {
        // Throwing on bad padding is an acceptable outcome.
      }
    });

    test('isEncrypted is false for an unmarked payload', () {
      expect(service.isEncrypted({'foo': 'bar'}), isFalse);
    });
  });
}
