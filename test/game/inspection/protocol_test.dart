import 'package:coreflame/game/inspection/protocol.dart';
import 'package:coreflame/runtime/inspection/runtime_inspection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tiny Tactics inspection protocol', () {
    test('parses typed commands and rejects unknown parameters', () {
      final envelope = RuntimeCommandEnvelope.parse(const {
        'command': 'setFeedbackSetting',
        'setting': 'music',
        'enabled': 'false',
        'expected_revision': '12',
      });
      final command = SetFeedbackSettingCommand.spec.decodeEnvelope(envelope);

      expect(envelope.expectedRevision, 12);
      expect(
        command,
        isA<SetFeedbackSettingCommand>()
            .having(
              (command) => command.setting,
              'setting',
              FeedbackSetting.music,
            )
            .having((command) => command.enabled, 'enabled', isFalse),
      );
      expect(
        () => ResetMatchCommand.spec.decodeEnvelope(
          RuntimeCommandEnvelope.parse(const {
            'command': 'resetMatch',
            'unexpected': 'value',
          }),
        ),
        throwsFormatException,
      );
    });

    test('keeps continuously changing fields out of semantic snapshots', () {
      const semantic = SceneSnapshot(
        overlay: 'none',
        assetsLoaded: true,
        animationsSettled: false,
        lastPlacedCell: 4,
      );

      final json = semantic.toJson();
      expect(json['overlay'], 'none');
      expect(json, isNot(contains('elapsedSeconds')));
      expect(json, isNot(contains('markProgress')));
      expect(json, isNot(contains('layout')));
    });
  });
}
