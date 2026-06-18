import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/error/app_exception.dart';
import '../../core/services/encryption_service.dart';
import '../../domain/models/habit.dart';
import '../../domain/models/habit_log.dart';
import '../../domain/models/insight.dart';
import '../../domain/models/user_progress.dart';
import '../../domain/repositories/backup_repository.dart';
import '../local/entities/habit_entity.dart';
import '../local/entities/habit_log_entity.dart';
import '../local/entities/insight_entity.dart';
import '../local/entities/user_progress_entity.dart';
import '../local/mappers/habit_log_mapper.dart';
import '../local/mappers/habit_mapper.dart';
import '../local/mappers/insight_mapper.dart';
import '../local/mappers/user_progress_mapper.dart';

/// Local-first backup. Local export/import always works offline; the cloud
/// path writes a SINGLE snapshot document per user (never per-habit writes) so
/// Firebase usage stays negligible.
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(
    this._isar, {
    EncryptionService encryption = const EncryptionService(),
    FirebaseFirestore? firestore,
  })  : _encryption = encryption,
        _firestore = firestore;

  final Isar _isar;
  final EncryptionService _encryption;
  final FirebaseFirestore? _firestore;

  static const String _backupCollection = 'backups';

  @override
  Future<String> exportToJson(String userId) async {
    final snapshot = await _buildSnapshot(userId);
    return const JsonEncoder.withIndent('  ').convert(snapshot);
  }

  @override
  Future<String> exportToFile(String userId) async {
    final json = await exportToJson(userId);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/habitview-backup-$stamp.'
        '${AppConstants.backupFileExtension}');
    await file.writeAsString(json);
    return file.path;
  }

  @override
  Future<BackupImportResult> importFromJson(
    String userId,
    String json, {
    bool merge = true,
  }) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      throw BackupException('The backup file is not valid JSON.', cause: e);
    }
    return _applySnapshot(userId, data, merge: merge);
  }

  @override
  Future<void> backupToCloud(String userId, {String? passphrase}) async {
    final firestore = _requireFirestore();
    final json = await exportToJson(userId);

    final Map<String, dynamic> payload;
    final bool encrypted;
    if (passphrase != null && passphrase.isNotEmpty) {
      payload = _encryption.encryptText(json, passphrase);
      encrypted = true;
    } else {
      payload = {'plaintext': json};
      encrypted = false;
    }

    await firestore.collection(_backupCollection).doc(userId).set({
      'schemaVersion': AppConstants.backupSchemaVersion,
      'encrypted': encrypted,
      'payload': payload,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<BackupImportResult> restoreFromCloud(
    String userId, {
    String? passphrase,
    bool merge = false,
  }) async {
    final firestore = _requireFirestore();
    final doc =
        await firestore.collection(_backupCollection).doc(userId).get();
    if (!doc.exists) {
      throw const BackupException('No cloud backup found for this account.');
    }
    final data = doc.data()!;
    final payload = (data['payload'] as Map).cast<String, dynamic>();
    final encrypted = data['encrypted'] == true;

    final String json;
    if (encrypted) {
      if (passphrase == null || passphrase.isEmpty) {
        throw const BackupException(
            'This backup is encrypted. A passphrase is required.');
      }
      try {
        json = _encryption.decryptPayload(payload, passphrase);
      } catch (e) {
        throw const BackupException(
            'Could not decrypt the backup — wrong passphrase?');
      }
    } else {
      json = payload['plaintext'] as String;
    }

    return importFromJson(userId, json, merge: merge);
  }

  @override
  Future<DateTime?> lastCloudBackupAt(String userId) async {
    final firestore = _firestore;
    if (firestore == null) return null;
    final doc =
        await firestore.collection(_backupCollection).doc(userId).get();
    if (!doc.exists) return null;
    final ts = doc.data()?['updatedAt'];
    return ts is Timestamp ? ts.toDate() : null;
  }

  // --- internals -----------------------------------------------------------

  Future<Map<String, dynamic>> _buildSnapshot(String userId) async {
    final habits = await _isar.habitEntitys
        .filter()
        .userIdEqualTo(userId)
        .findAll();
    final logs =
        await _isar.habitLogEntitys.filter().userIdEqualTo(userId).findAll();
    final insights =
        await _isar.insightEntitys.filter().userIdEqualTo(userId).findAll();
    final progress = await _isar.userProgressEntitys
        .filter()
        .userIdEqualTo(userId)
        .findFirst();

    return {
      'schemaVersion': AppConstants.backupSchemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'userId': userId,
      'habits': habits.map((e) => HabitMapper.toDomain(e).toJson()).toList(),
      'logs': logs.map((e) => HabitLogMapper.toDomain(e).toJson()).toList(),
      'insights':
          insights.map((e) => InsightMapper.toDomain(e).toJson()).toList(),
      'userProgress': progress == null
          ? UserProgress(userId: userId).toJson()
          : UserProgressMapper.toDomain(progress).toJson(),
    };
  }

  Future<BackupImportResult> _applySnapshot(
    String userId,
    Map<String, dynamic> data, {
    required bool merge,
  }) async {
    final habits = (data['habits'] as List? ?? [])
        .map((e) => Habit.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final logs = (data['logs'] as List? ?? [])
        .map((e) => HabitLog.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    final insights = (data['insights'] as List? ?? [])
        .map((e) => Insight.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    try {
      await _isar.writeTxn(() async {
        if (!merge) {
          await _isar.habitEntitys.filter().userIdEqualTo(userId).deleteAll();
          await _isar.habitLogEntitys
              .filter()
              .userIdEqualTo(userId)
              .deleteAll();
          await _isar.insightEntitys
              .filter()
              .userIdEqualTo(userId)
              .deleteAll();
        }
        await _isar.habitEntitys.putAll([
          for (final h in habits)
            HabitMapper.toEntity(h.copyWith(userId: userId))
        ]);
        await _isar.habitLogEntitys.putAll([
          for (final l in logs)
            HabitLogMapper.toEntity(l.copyWith(userId: userId))
        ]);
        await _isar.insightEntitys.putAll([
          for (final i in insights)
            InsightMapper.toEntity(i.copyWith(userId: userId))
        ]);
      });
    } catch (e) {
      throw BackupException('Could not import backup data.', cause: e);
    }

    return BackupImportResult(
      habits: habits.length,
      logs: logs.length,
      insights: insights.length,
    );
  }

  FirebaseFirestore _requireFirestore() {
    final firestore = _firestore;
    if (firestore == null) {
      throw const BackupException(
        'Cloud backup is not configured. Enable it in Settings first.',
      );
    }
    return firestore;
  }
}
