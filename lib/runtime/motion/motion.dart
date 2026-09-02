import 'dart:math' as math;

import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

abstract interface class Motion {
  bool get isSettled;

  void advance(double dt);
}

final class TimedProgress implements Motion {
  TimedProgress({
    required double duration,
    Curve curve = Curves.linear,
    bool initiallyComplete = false,
  }) : _controller = EffectController(duration: duration, curve: curve) {
    if (initiallyComplete) _controller.setToEnd();
  }

  final EffectController _controller;

  double get value => _controller.progress;

  @override
  bool get isSettled => _controller.completed;

  @override
  void advance(double dt) {
    _validateDelta(dt);
    _controller.advance(dt);
  }

  void restart() => _controller.setToStart();

  void complete() => _controller.setToEnd();
}

final class SpringDouble implements Motion {
  SpringDouble({
    required double value,
    double? target,
    this.stiffness = 310,
    this.damping = 22,
    this.mass = 1,
    this.settleDistance = 0.001,
    this.settleVelocity = 0.001,
  }) : value = value,
       target = target ?? value {
    if (!stiffness.isFinite || stiffness <= 0) {
      throw ArgumentError.value(stiffness, 'stiffness', 'must be positive');
    }
    if (!damping.isFinite || damping < 0) {
      throw ArgumentError.value(damping, 'damping', 'must not be negative');
    }
    if (!mass.isFinite || mass <= 0) {
      throw ArgumentError.value(mass, 'mass', 'must be positive');
    }
  }

  final double stiffness;
  final double damping;
  final double mass;
  final double settleDistance;
  final double settleVelocity;

  double value;
  double target;
  double velocity = 0;

  @override
  bool get isSettled =>
      (value - target).abs() <= settleDistance &&
      velocity.abs() <= settleVelocity;

  void setTarget(double value, {double? minimumVelocity}) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
    target = value;
    if (minimumVelocity case final minimum?) {
      if (!minimum.isFinite) {
        throw ArgumentError.value(minimum, 'minimumVelocity', 'must be finite');
      }
      velocity = math.max(velocity, minimum);
    }
  }

  void snapTo(double value) {
    if (!value.isFinite) {
      throw ArgumentError.value(value, 'value', 'must be finite');
    }
    this.value = value;
    target = value;
    velocity = 0;
  }

  @override
  void advance(double dt) {
    _validateDelta(dt);
    if (dt == 0 || isSettled) return;

    final displacement = value - target;
    final alpha = damping / (2 * mass);
    final naturalFrequencySquared = stiffness / mass;
    final discriminant = alpha * alpha - naturalFrequencySquared;

    late final double nextDisplacement;
    late final double nextVelocity;
    if (discriminant.abs() < 1e-12) {
      final coefficient = velocity + alpha * displacement;
      final decay = math.exp(-alpha * dt);
      nextDisplacement = decay * (displacement + coefficient * dt);
      nextVelocity =
          decay * (coefficient - alpha * (displacement + coefficient * dt));
    } else if (discriminant < 0) {
      final frequency = math.sqrt(-discriminant);
      final sineCoefficient = (velocity + alpha * displacement) / frequency;
      final cosine = math.cos(frequency * dt);
      final sine = math.sin(frequency * dt);
      final oscillation = displacement * cosine + sineCoefficient * sine;
      final decay = math.exp(-alpha * dt);
      nextDisplacement = decay * oscillation;
      nextVelocity =
          decay *
          (-displacement * frequency * sine +
              sineCoefficient * frequency * cosine -
              alpha * oscillation);
    } else {
      final root = math.sqrt(discriminant);
      final slowRoot = -alpha + root;
      final fastRoot = -alpha - root;
      final slowCoefficient =
          (velocity - fastRoot * displacement) / (slowRoot - fastRoot);
      final fastCoefficient = displacement - slowCoefficient;
      final slowDecay = math.exp(slowRoot * dt);
      final fastDecay = math.exp(fastRoot * dt);
      nextDisplacement =
          slowCoefficient * slowDecay + fastCoefficient * fastDecay;
      nextVelocity =
          slowRoot * slowCoefficient * slowDecay +
          fastRoot * fastCoefficient * fastDecay;
    }

    value = target + nextDisplacement;
    velocity = nextVelocity;
    if (isSettled) {
      value = target;
      velocity = 0;
    }
  }
}

final class MotionGroup implements Motion {
  MotionGroup(Iterable<Motion> motions) : motions = List.unmodifiable(motions);

  final List<Motion> motions;

  @override
  bool get isSettled => motions.every((motion) => motion.isSettled);

  @override
  void advance(double dt) {
    for (final motion in motions) {
      motion.advance(dt);
    }
  }
}

void _validateDelta(double dt) {
  if (!dt.isFinite || dt < 0) {
    throw ArgumentError.value(dt, 'dt', 'must be finite and non-negative');
  }
}
