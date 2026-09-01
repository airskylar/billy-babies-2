// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_platform_services.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VersionedGameSave _$VersionedGameSaveFromJson(Map<String, dynamic> json) =>
    $checkedCreate('VersionedGameSave', json, ($checkedConvert) {
      $checkKeys(
        json,
        allowedKeys: const [
          'schemaVersion',
          'revision',
          'parentRevision',
          'writtenAtUtc',
          'payload',
        ],
        requiredKeys: const ['parentRevision'],
      );
      final val = VersionedGameSave(
        schemaVersion: $checkedConvert(
          'schemaVersion',
          (v) => (v as num).toInt(),
        ),
        revision: $checkedConvert('revision', (v) => (v as num).toInt()),
        parentRevision: $checkedConvert(
          'parentRevision',
          (v) => (v as num?)?.toInt(),
        ),
        writtenAtUtc: $checkedConvert(
          'writtenAtUtc',
          (v) => DateTime.parse(v as String),
        ),
        payload: $checkedConvert('payload', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$VersionedGameSaveToJson(VersionedGameSave instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'revision': instance.revision,
      'parentRevision': instance.parentRevision,
      'writtenAtUtc': instance.writtenAtUtc.toIso8601String(),
      'payload': instance.payload,
    };
