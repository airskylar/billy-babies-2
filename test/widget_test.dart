import 'package:coreflame/game/coreflame_game.dart';
import 'package:coreflame/main.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hosts the Flame game', (tester) async {
    await tester.pumpWidget(const CoreflameApp());
    await tester.pump();

    expect(find.byType(GameWidget<CoreflameGame>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
