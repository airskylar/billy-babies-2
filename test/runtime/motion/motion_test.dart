import 'package:coreflame/runtime/motion/motion.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Motion', () {
    test('advances curved timed progress and can restart', () {
      final progress = TimedProgress(
        duration: 0.4,
        curve: Curves.easeIn,
        initiallyComplete: true,
      );

      expect(progress.value, 1);
      expect(progress.isSettled, isTrue);

      progress.restart();
      progress.advance(0.2);
      expect(progress.value, closeTo(Curves.easeIn.transform(0.5), 1e-9));
      expect(progress.isSettled, isFalse);

      progress.advance(0.2);
      expect(progress.value, 1);
      expect(progress.isSettled, isTrue);
    });

    test('spring consumes elapsed time consistently across partitions', () {
      final single = SpringDouble(value: 0)..setTarget(1);
      final partitioned = SpringDouble(value: 0)..setTarget(1);

      single.advance(0.2);
      for (var index = 0; index < 12; index += 1) {
        partitioned.advance(1 / 60);
      }

      expect(single.value, closeTo(partitioned.value, 1e-12));
      expect(single.velocity, closeTo(partitioned.velocity, 1e-12));
    });

    test('spring settles exactly and can be snapped', () {
      final spring = SpringDouble(value: 0)..setTarget(1);

      spring.advance(2);

      expect(spring.isSettled, isTrue);
      expect(spring.value, 1);
      expect(spring.velocity, 0);

      spring.snapTo(0.4);
      expect(spring.value, 0.4);
      expect(spring.target, 0.4);
      expect(spring.velocity, 0);
    });

    test('group advances and settles all motions', () {
      final first = TimedProgress(duration: 0.1);
      final second = TimedProgress(duration: 0.2);
      final group = MotionGroup([first, second]);

      group.advance(0.1);
      expect(first.isSettled, isTrue);
      expect(group.isSettled, isFalse);

      group.advance(0.1);
      expect(group.isSettled, isTrue);
    });

    test('rejects invalid elapsed time', () {
      final progress = TimedProgress(duration: 1);

      expect(() => progress.advance(-1), throwsArgumentError);
      expect(() => progress.advance(double.nan), throwsArgumentError);
    });
  });
}
