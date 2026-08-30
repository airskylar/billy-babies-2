import 'package:coreflame/game/coreflame_game.dart';
import 'package:coreflame/game/services/fake_game_platform_services.dart';
import 'package:coreflame/game/services/game_platform_services.dart';
import 'package:coreflame/main.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('hosts the Flame game without owning injected services', (
    tester,
  ) async {
    final gameServices = FakeGamePlatformServices();

    await tester.pumpWidget(CoreflameApp(gameServices: gameServices));
    await tester.pump();

    expect(find.byType(GameWidget<CoreflameGame>), findsOneWidget);
    expect(gameServices.isAuthenticated, isTrue);
    expect(
      gameServices.calls.map((call) => call.operation),
      contains(GameServiceOperation.authenticate),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());

    expect(gameServices.isDisposed, isFalse);
  });
}
