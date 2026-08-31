import 'package:coreflame/game/observability/coreflame_debug_bridge.dart';
import 'package:coreflame/game/observability/inspectable_flame_game.dart';
import 'package:coreflame/game/observability/runtime_inspection.dart';
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
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

    testWithGame<_HierarchyGame>(
      'preserves typed Flame configuration and inspectable relationships',
      _HierarchyGame.new,
      (game) async {
        await game.ready();

        expect(identical(game.world, game.configuredWorld), isTrue);
        expect(identical(game.camera, game.configuredCamera), isTrue);
        expect(game.initialChild.isMounted, isTrue);

        final components = game.snapshot(SnapshotDetail.semantic).components;
        final byId = {
          for (final component in components) component.id: component,
        };

        expect(
          byId.keys,
          unorderedEquals(const {
            'game',
            'initial-child',
            'hud',
            'viewfinder-child',
            'world',
            'world-entity',
            'world-leaf',
          }),
        );
        expect(
          byId['game']!.childIds,
          containsAll(const {
            'initial-child',
            'hud',
            'viewfinder-child',
            'world',
          }),
        );
        expect(byId['world']!.parentId, 'game');
        expect(byId['world']!.childIds, ['world-entity']);
        expect(byId['world-entity']!.parentId, 'world');
        expect(byId['world-entity']!.childIds, ['world-leaf']);
        expect(byId['world-leaf']!.parentId, 'world-entity');
        expect(byId['hud']!.parentId, 'game');
        expect(byId['viewfinder-child']!.parentId, 'game');
      },
    );

    testWithGame<_HierarchyGame>(
      'resolves visual bounds in world and screen coordinate spaces',
      _HierarchyGame.new,
      (game) async {
        await game.ready();

        final components = game.snapshot(SnapshotDetail.visual).components;
        final byId = {
          for (final component in components) component.id: component,
        };
        final worldEntity = byId['world-entity']!.transform!;
        final hud = byId['hud']!.transform!;
        final viewfinderChild = byId['viewfinder-child']!.transform!;
        final initialChild = byId['initial-child']!.transform!;

        expect(worldEntity.x, 10);
        expect(worldEntity.y, 20);
        expect(worldEntity.width, 20);
        expect(worldEntity.height, 10);
        _expectRect(
          worldEntity.worldBounds,
          x: 50,
          y: 80,
          width: 40,
          height: 20,
        );
        _expectRect(
          worldEntity.screenBounds,
          x: 400,
          y: 360,
          width: 80,
          height: 40,
        );

        expect(hud.worldBounds, isNull);
        _expectRect(hud.screenBounds, x: 10, y: 12, width: 20, height: 40);

        _expectRect(
          viewfinderChild.worldBounds,
          x: 60,
          y: 60,
          width: 10,
          height: 10,
        );
        _expectRect(
          viewfinderChild.screenBounds,
          x: 420,
          y: 320,
          width: 20,
          height: 20,
        );

        expect(initialChild.worldBounds, isNull);
        _expectRect(initialChild.screenBounds, x: 7, y: 8, width: 3, height: 4);
      },
    );

    testWithGame<_HierarchyGame>(
      'does not attach inspection while a game is only constructed',
      _HierarchyGame.new,
      (mountedGame) async {
        await mountedGame.ready();
        final mountedSession = mountedGame.inspectionSession;
        expect(mountedSession, isNotNull);
        expect(mountedSession!.isActive, isTrue);

        final constructedGame = _HierarchyGame();

        expect(constructedGame.inspectionSession, isNull);
        expect(mountedSession.isActive, isTrue);
      },
    );

    testWithGame<_HierarchyGame>(
      'identifies every pull response with the active mount session',
      _HierarchyGame.new,
      (game) async {
        await game.ready();
        final session = game.inspectionSession!;
        final responses = <String, Map<String, Object?>>{
          'capabilities': game.capabilities().toJson(),
          'snapshot': game.snapshot(SnapshotDetail.semantic).toJson(),
          'events': game.eventBatchAfter(0).toJson(),
          'dispatch': game
              .dispatch(
                RuntimeCommandEnvelope(
                  name: 'increment',
                  expectedRevision: game.revision,
                  arguments: const {'amount': '1'},
                ),
              )
              .toJson(),
        };

        for (final MapEntry(:key, :value) in responses.entries) {
          expect(session.envelope(value)['sessionId'], session.id, reason: key);
        }
      },
    );

    test(
      'keeps a replacement active and rejects stale event publishers',
      () async {
        final firstGame = await initializeGame<_HierarchyGame>(
          _HierarchyGame.new,
        );
        var firstRemoved = false;
        _HierarchyGame? secondGame;
        var secondRemoved = false;
        addTearDown(() {
          if (!firstRemoved) firstGame.onRemove();
          if (!secondRemoved) secondGame?.onRemove();
        });

        final firstSession = firstGame.inspectionSession!;
        secondGame = await initializeGame<_HierarchyGame>(_HierarchyGame.new);
        final secondSession = secondGame.inspectionSession!;

        expect(firstSession.isActive, isFalse);
        expect(secondSession.isActive, isTrue);

        final event = RuntimeEvent(
          sequence: 1,
          revision: 1,
          gameTimeSeconds: 0,
          kind: RuntimeEventKind.enginePaused,
        );
        expect(
          CoreflameDebugBridge.publish(
            target: firstGame,
            session: firstSession,
            event: event,
          ),
          isFalse,
        );
        expect(
          CoreflameDebugBridge.publish(
            target: firstGame,
            session: secondSession,
            event: event,
          ),
          isFalse,
        );
        expect(
          CoreflameDebugBridge.publish(
            target: secondGame,
            session: secondSession,
            event: event,
          ),
          isTrue,
        );

        firstRemoved = true;
        firstGame.onRemove();
        expect(secondSession.isActive, isTrue);

        secondRemoved = true;
        secondGame.onRemove();
        expect(secondSession.isActive, isFalse);
      },
    );

    test('creates a fresh inspection session when remounted', () async {
      final game = await initializeGame<_HierarchyGame>(_HierarchyGame.new);
      var mounted = true;
      addTearDown(() {
        if (mounted) {
          // ignore: invalid_use_of_internal_member
          game.finalizeRemoval();
        }
      });

      final firstSession = game.inspectionSession!;
      // ignore: invalid_use_of_internal_member
      game.finalizeRemoval();
      mounted = false;

      expect(game.inspectionSession, isNull);
      expect(firstSession.isActive, isFalse);

      // ignore: invalid_use_of_internal_member
      game.mount();
      mounted = true;
      final secondSession = game.inspectionSession!;

      expect(secondSession.id, isNot(firstSession.id));
      expect(secondSession.isActive, isTrue);
    });
  });
}

void _expectRect(
  RectSnapshot? actual, {
  required double x,
  required double y,
  required double width,
  required double height,
}) {
  expect(actual, isNotNull);
  expect(actual!.x, closeTo(x, 1e-9));
  expect(actual.y, closeTo(y, 1e-9));
  expect(actual.width, closeTo(width, 1e-9));
  expect(actual.height, closeTo(height, 1e-9));
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

class _HierarchyGame extends InspectableFlameGame<_InspectableWorld> {
  factory _HierarchyGame() {
    final worldLeaf = _InspectablePosition(
      'world-leaf',
      position: Vector2(1, 2),
      size: Vector2.all(3),
    );
    final worldEntity = _InspectablePosition(
      'world-entity',
      position: Vector2(10, 20),
      size: Vector2(20, 10),
      children: [
        Component(children: [worldLeaf]),
      ],
    );
    final world = _InspectableWorld(
      children: [
        PositionComponent(
          position: Vector2(30, 40),
          scale: Vector2.all(2),
          children: [worldEntity],
        ),
      ],
    );
    final hud = _InspectablePosition(
      'hud',
      position: Vector2(5, 6),
      size: Vector2(10, 20),
    );
    final viewfinderChild = _InspectablePosition(
      'viewfinder-child',
      position: Vector2.all(60),
      size: Vector2.all(10),
    );
    final viewfinder = Viewfinder()
      ..position = Vector2.all(50)
      ..add(viewfinderChild);
    final camera = CameraComponent.withFixedResolution(
      width: 400,
      height: 300,
      viewfinder: viewfinder,
      hudComponents: [hud],
    );
    final initialChild = _InspectablePosition(
      'initial-child',
      position: Vector2(7, 8),
      size: Vector2(3, 4),
    );
    return _HierarchyGame._(
      world: world,
      camera: camera,
      initialChild: initialChild,
    );
  }

  _HierarchyGame._({
    required _InspectableWorld world,
    required CameraComponent camera,
    required this.initialChild,
  }) : configuredWorld = world,
       configuredCamera = camera,
       super(world: world, camera: camera, children: [initialChild]);

  final _InspectableWorld configuredWorld;
  final CameraComponent configuredCamera;
  final _InspectablePosition initialChild;

  late final _CounterAdapter _adapter = _CounterAdapter(recordInspectionEvent);

  @override
  RuntimeInspectionAdapter get inspectionAdapter => _adapter;
}

class _InspectableWorld extends World implements RuntimeInspectable {
  _InspectableWorld({super.children});

  @override
  String get inspectionId => 'world';

  @override
  Map<String, Object?> inspectState(SnapshotDetail detail) => const {};
}

class _InspectablePosition extends PositionComponent
    implements RuntimeInspectable {
  _InspectablePosition(
    this.inspectionId, {
    super.position,
    super.size,
    super.children,
  });

  @override
  final String inspectionId;

  @override
  Map<String, Object?> inspectState(SnapshotDetail detail) => const {};
}
