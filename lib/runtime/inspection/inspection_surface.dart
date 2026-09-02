import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../input/pointer_trace.dart';
import 'inspectable_flame_game.dart';
import 'runtime_inspection.dart';

class InspectableGameSurface<T extends InspectableFlameGame>
    extends StatefulWidget {
  const InspectableGameSurface({
    required this.game,
    this.autofocus = true,
    super.key,
  });

  final T game;
  final bool autofocus;

  @override
  State<InspectableGameSurface<T>> createState() =>
      _InspectableGameSurfaceState<T>();
}

class _InspectableGameSurfaceState<T extends InspectableFlameGame>
    extends State<InspectableGameSurface<T>>
    implements RuntimeInspectionSurface, PointerTraceTarget {
  final _boundaryKey = GlobalKey();
  final List<_FrameWaiter> _frameWaiters = [];
  int _presentedFrameNumber = 0;

  @override
  void initState() {
    super.initState();
    widget.game.attachInspectionSurface(this);
  }

  @override
  void didUpdateWidget(InspectableGameSurface<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.game, widget.game)) {
      oldWidget.game.detachInspectionSurface(this);
      widget.game.attachInspectionSurface(this);
      _presentedFrameNumber = 0;
      _completeWaitersWithError(
        const FormatException('The game changed while awaiting a frame'),
      );
    }
  }

  @override
  void dispose() {
    widget.game.detachInspectionSurface(this);
    _completeWaitersWithError(
      const FormatException('The game surface was disposed'),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: _boundaryKey,
    child: GameWidget<T>(game: widget.game, autofocus: widget.autofocus),
  );

  @override
  void didPresentFrame(int frameNumber) {
    if (frameNumber > _presentedFrameNumber) {
      _presentedFrameNumber = frameNumber;
    }
    for (final waiter in List<_FrameWaiter>.of(_frameWaiters)) {
      if (waiter.frameNumber <= _presentedFrameNumber) {
        _frameWaiters.remove(waiter);
        waiter.completer.complete();
      }
    }
  }

  @override
  Future<InspectionCaptureResult> capture(
    InspectionCaptureRequest request,
  ) async {
    if (!widget.game.paused) {
      throw const FormatException('Pause the engine before capturing a frame');
    }
    final endOfFrame = WidgetsBinding.instance.endOfFrame;
    final step = request.stepSeconds;
    if (step != null) {
      widget.game.stepEngine(stepTime: step);
    }

    final targetFrame = widget.game.frameNumber;
    await _waitForFrame(targetFrame);
    await endOfFrame;

    List<int>? pngBytes;
    if (request.includePng) {
      final boundary = _boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw const FormatException('The game surface is not ready to capture');
      }
      final image = await boundary.toImage(pixelRatio: request.pixelRatio);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) {
          throw const FormatException('Flutter did not encode the frame');
        }
        pngBytes = bytes.buffer.asUint8List();
      } finally {
        image.dispose();
      }
    }

    return InspectionCaptureResult(
      snapshot: widget.game.snapshot(request.detail),
      presentedFrameNumber: _presentedFrameNumber,
      pngBytes: pngBytes,
    );
  }

  @override
  Future<PointerReplayResult> replay(PointerTrace trace) async {
    if (!widget.game.paused) {
      throw const FormatException(
        'Pause the engine before replaying pointer input',
      );
    }
    final count = await const PointerTracePlayer().play(trace, this);
    return PointerReplayResult(
      eventsDispatched: count,
      snapshot: widget.game.snapshot(SnapshotDetail.semantic),
    );
  }

  RenderBox get _renderBox {
    final renderObject = _boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      throw const FormatException('The game surface is not laid out');
    }
    return renderObject;
  }

  @override
  Size get surfaceSize => _renderBox.size;

  @override
  Offset localToGlobal(Offset position) => _renderBox.localToGlobal(position);

  @override
  void dispatchPointerEvent(PointerEvent event) {
    GestureBinding.instance.handlePointerEvent(event);
  }

  @override
  Future<void> elapse(Duration duration) async {
    // Event timestamps drive velocity and ordering. Live replay intentionally
    // avoids wall-clock sleeps; deterministic timer-driven gestures belong in
    // widget tests where the binding clock can be advanced explicitly.
  }

  Future<void> _waitForFrame(int frameNumber) {
    if (_presentedFrameNumber >= frameNumber) return SynchronousFuture(null);
    final completer = Completer<void>();
    _frameWaiters.add(_FrameWaiter(frameNumber, completer));
    return completer.future;
  }

  void _completeWaitersWithError(Object error) {
    for (final waiter in _frameWaiters) {
      waiter.completer.completeError(error);
    }
    _frameWaiters.clear();
  }
}

final class _FrameWaiter {
  const _FrameWaiter(this.frameNumber, this.completer);

  final int frameNumber;
  final Completer<void> completer;
}
