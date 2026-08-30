import 'package:coreflame/game/observability/coreflame_observability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coreflame observability', () {
    test('parses typed commands and rejects unknown parameters', () {
      final request = CoreflameCommandRequest.parse(const {
        'command': 'setFeedbackSetting',
        'setting': 'music',
        'enabled': 'false',
        'expected_revision': '12',
      });

      expect(request.expectedRevision, 12);
      expect(
        request.command,
        isA<SetFeedbackSettingCommand>()
            .having(
              (command) => command.setting,
              'setting',
              FeedbackSetting.music,
            )
            .having((command) => command.enabled, 'enabled', isFalse),
      );
      expect(
        () => CoreflameCommandRequest.parse(const {
          'command': 'resetMatch',
          'unexpected': 'value',
        }),
        throwsFormatException,
      );
    });

    test('keeps a bounded, sequence-addressable event journal', () {
      final journal = CoreflameEventJournal(capacity: 2);

      for (var revision = 1; revision <= 3; revision += 1) {
        journal.add(
          revision: revision,
          gameTimeSeconds: revision / 10,
          kind: CoreflameEventKind.viewportChanged,
        );
      }

      expect(journal.all.map((event) => event.sequence), [2, 3]);
      expect(journal.after(2).single.sequence, 3);
      expect(journal.after(3), isEmpty);

      final truncated = journal.batchAfter(0);
      expect(truncated.oldestAvailableSequence, 2);
      expect(truncated.latestSequence, 3);
      expect(truncated.truncated, isTrue);
      expect(truncated.events.map((event) => event.sequence), [2, 3]);
      expect(journal.batchAfter(1).truncated, isFalse);
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
