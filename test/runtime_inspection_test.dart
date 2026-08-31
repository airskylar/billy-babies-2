import 'package:coreflame/game/observability/inspectable_flame_game.dart';
import 'package:coreflame/game/observability/runtime_inspection.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Runtime inspection kernel', () {
    test('keeps a bounded, sequence-addressable event journal', () {
      final journal = RuntimeEventJournal(capacity: 2);

      for (var revision = 1; revision <= 3; revision += 1) {
        journal.add(
          revision: revision,
          gameTimeSeconds: revision / 10,
          kind: RuntimeEventKind.viewportChanged,
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

    testWithGame<_CounterGame>(
      'supports a non-demo game through only the generic adapter contract',
      _CounterGame.new,
      (game) async {
        await game.ready();

        final capabilities = game.capabilities();
        expect(capabilities.gameId, 'counter');
        expect(capabilities.commands.single.name, 'increment');

        final initialRevision = game.revision;
        final result = game.dispatch(
          RuntimeCommandEnvelope(
            name: 'increment',
            expectedRevision: initialRevision,
            arguments: const {'amount': '2'},
          ),
        );

        expect(result.accepted, isTrue);
        expect(result.currentRevision, initialRevision + 1);
        expect(result.snapshot.game.id, 'counter');
        expect((result.snapshot.game.state as _CounterState).value, 2);
        expect(
          game.eventBatchAfter(0).events.map((event) => event.kind),
          contains(_CounterEventKind.incremented),
        );
      },
    );
  });
}

enum _CounterEventKind implements InspectionEventKind {
  incremented;

  @override
  String get wireName => name;
}

class _CounterState implements GameInspectionState {
  const _CounterState(this.value);

  final int value;

  @override
  Map<String, Object?> toJson() => {'value': value};
}

class _CounterAdapter implements RuntimeInspectionAdapter {
  _CounterAdapter(this.recordEvent);

  final RuntimeEventRecorder recordEvent;
  int value = 0;

  @override
  String get gameId => 'counter';

  @override
  int get schemaVersion => 1;

  @override
  List<CommandDescriptor> get commands => const [
    CommandDescriptor(
      name: 'increment',
      description: 'Increment the counter.',
      parameters: [
        CommandParameterDescriptor(
          name: 'amount',
          type: CommandParameterType.integer,
          required: true,
          description: 'Amount to add.',
        ),
      ],
    ),
  ];

  @override
  RuntimeCommandOutcome dispatch(RuntimeCommandEnvelope command) {
    if (command.name != 'increment') {
      throw FormatException('Unknown command: ${command.name}');
    }
    if (command.arguments.keys.toSet().difference(const {
      'amount',
    }).isNotEmpty) {
      throw const FormatException('Unexpected increment parameter');
    }
    final amount = int.tryParse(command.arguments['amount'] ?? '');
    if (amount == null) {
      throw const FormatException('Expected integer parameter: amount');
    }

    value += amount;
    recordEvent(_CounterEventKind.incremented, {'amount': amount});
    return const RuntimeCommandOutcome(
      accepted: true,
      code: 'applied',
      message: 'Incremented the counter',
    );
  }

  @override
  GameInspectionState snapshot(SnapshotDetail detail) => _CounterState(value);
}

class _CounterGame extends InspectableFlameGame {
  late final _CounterAdapter _adapter = _CounterAdapter(recordInspectionEvent);

  @override
  RuntimeInspectionAdapter get inspectionAdapter => _adapter;
}
