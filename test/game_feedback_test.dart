import 'package:coreflame/game/game_action_origin.dart';
import 'package:coreflame/game/services/game_feedback.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameFeedback', () {
    test(
      'reports typed setting changes and an explicit disposal phase',
      () async {
        SharedPreferences.setMockInitialValues({});
        final backgroundMusic = _FakeBackgroundMusic();
        final feedback = GameFeedback(backgroundMusic: backgroundMusic);
        final events = <GameFeedbackEvent>[];
        feedback.addObserver(events.add);

        await feedback.startBackgroundMusic();

        expect(feedback.backgroundMusicPhase, BackgroundMusicPhase.playing);
        expect(backgroundMusic.initializeCalls, 1);
        expect(backgroundMusic.playCalls, 1);

        feedback.setSoundEnabled(false, origin: GameActionOrigin.test);

        expect(feedback.soundEnabled, isFalse);
        expect(
          events
              .singleWhere(
                (event) => event.kind == GameFeedbackEventKind.settingChanged,
              )
              .payload,
          containsPair('origin', GameActionOrigin.test.name),
        );

        await feedback.dispose();

        expect(feedback.lifecycle, GameFeedbackLifecycle.disposed);
        expect(feedback.backgroundMusicPhase, BackgroundMusicPhase.disposed);
        expect(backgroundMusic.disposeCalls, 1);
      },
    );

    test('does not eagerly initialize the platform music player', () async {
      final feedback = GameFeedback();

      expect(feedback.backgroundMusicPhase, BackgroundMusicPhase.uninitialized);

      await feedback.dispose();
      expect(feedback.lifecycle, GameFeedbackLifecycle.disposed);
    });
  });
}

class _FakeBackgroundMusic implements BackgroundMusicController {
  int initializeCalls = 0;
  int playCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
  }

  @override
  Future<void> play(String asset, {required double volume}) async {
    playCalls += 1;
  }

  @override
  Future<void> stop() async {}
}
