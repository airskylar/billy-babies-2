import 'dart:async';

import 'package:flame_audio/bgm.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulsar_haptics/pulsar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game_action_origin.dart';
import '../tic_tac_toe_match.dart';

enum GameFeedbackLifecycle { created, loading, ready, disposing, disposed }

enum BackgroundMusicPhase {
  uninitialized,
  initializing,
  ready,
  starting,
  playing,
  stopping,
  disposed;

  bool get isInitialized => switch (this) {
    BackgroundMusicPhase.ready ||
    BackgroundMusicPhase.starting ||
    BackgroundMusicPhase.playing ||
    BackgroundMusicPhase.stopping => true,
    _ => false,
  };
}

enum GameFeedbackEventKind {
  lifecycleChanged,
  backgroundMusicChanged,
  settingsLoaded,
  settingChanged,
  failure,
}

enum FeedbackSetting { sound, music, vibration }

class GameFeedbackFailure {
  const GameFeedbackFailure({
    required this.feature,
    required this.errorType,
    required this.message,
  });

  final String feature;
  final String errorType;
  final String message;

  Map<String, Object?> toEventPayload() => {
    'feature': feature,
    'errorType': errorType,
    'message': message,
  };
}

class GameFeedbackEvent {
  GameFeedbackEvent({
    required this.kind,
    Map<String, Object?> payload = const {},
  }) : payload = Map.unmodifiable(payload);

  final GameFeedbackEventKind kind;
  final Map<String, Object?> payload;
}

typedef GameFeedbackObserver = void Function(GameFeedbackEvent event);

abstract interface class BackgroundMusicController {
  Future<void> initialize();

  Future<void> play(String asset, {required double volume});

  Future<void> stop();

  Future<void> dispose();
}

class _FlameBackgroundMusicController implements BackgroundMusicController {
  Bgm? _player;

  Bgm get _activePlayer => _player ??= Bgm(audioCache: FlameAudio.audioCache);

  @override
  Future<void> initialize() => _activePlayer.initialize();

  @override
  Future<void> play(String asset, {required double volume}) =>
      _activePlayer.play(asset, volume: volume);

  @override
  Future<void> stop() => _activePlayer.stop();

  @override
  Future<void> dispose() async {
    await _player?.dispose();
  }
}

class GameFeedback {
  GameFeedback({Pulsar? pulsar, BackgroundMusicController? backgroundMusic})
    : _pulsar = pulsar ?? Pulsar(),
      _backgroundMusic = backgroundMusic ?? _FlameBackgroundMusicController();

  static const xSound = 'place_x.mp3';
  static const oSound = 'place_o.mp3';
  static const backgroundMusic = 'blossom.mp3';
  static const backgroundMusicVolume = 0.32;
  static const _soundPreference = 'settings.sound';
  static const _musicPreference = 'settings.music';
  static const _vibrationPreference = 'settings.vibration';

  final Pulsar _pulsar;
  final BackgroundMusicController _backgroundMusic;
  SharedPreferences? _preferences;
  final List<GameFeedbackObserver> _observers = [];
  Future<void> _backgroundOperation = Future.value();
  bool _pulsarSoundDisabled = false;
  bool _preferencesLoaded = false;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  GameFeedbackLifecycle _lifecycle = GameFeedbackLifecycle.created;
  BackgroundMusicPhase _backgroundMusicPhase =
      BackgroundMusicPhase.uninitialized;
  GameFeedbackFailure? _lastFailure;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get preferencesLoaded => _preferencesLoaded;
  GameFeedbackLifecycle get lifecycle => _lifecycle;
  BackgroundMusicPhase get backgroundMusicPhase => _backgroundMusicPhase;
  GameFeedbackFailure? get lastFailure => _lastFailure;

  void addObserver(GameFeedbackObserver observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  void removeObserver(GameFeedbackObserver observer) {
    _observers.remove(observer);
  }

  Future<void> preload() async {
    if (_lifecycle == GameFeedbackLifecycle.ready) return;
    if (_lifecycle != GameFeedbackLifecycle.created) {
      throw StateError('Cannot preload feedback while ${_lifecycle.name}');
    }

    _setLifecycle(GameFeedbackLifecycle.loading);
    await _loadPreferences();

    try {
      await FlameAudio.audioCache.loadAll(const [xSound, oSound]);
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Audio preload', error, stackTrace);
    }

    await _enqueueBackgroundOperation(_ensureBackgroundMusicInitialized);
    _setLifecycle(GameFeedbackLifecycle.ready);
  }

  Future<void> startBackgroundMusic({bool fromUserGesture = false}) {
    return _enqueueBackgroundOperation(() async {
      if (!_musicEnabled ||
          _lifecycle == GameFeedbackLifecycle.disposing ||
          _lifecycle == GameFeedbackLifecycle.disposed ||
          _backgroundMusicPhase == BackgroundMusicPhase.playing ||
          (kIsWeb && !fromUserGesture)) {
        return;
      }

      if (!await _ensureBackgroundMusicInitialized()) return;
      _setBackgroundMusicPhase(BackgroundMusicPhase.starting);
      try {
        await _backgroundMusic.play(
          backgroundMusic,
          volume: backgroundMusicVolume,
        );
        if (!_musicEnabled ||
            _lifecycle == GameFeedbackLifecycle.disposing ||
            _lifecycle == GameFeedbackLifecycle.disposed) {
          await _backgroundMusic.stop();
          _setBackgroundMusicPhase(BackgroundMusicPhase.ready);
        } else {
          _setBackgroundMusicPhase(BackgroundMusicPhase.playing);
        }
      } on Object catch (error, stackTrace) {
        _setBackgroundMusicPhase(BackgroundMusicPhase.ready);
        _reportOptionalFailure('Background music', error, stackTrace);
      }
    });
  }

  void handleUserGesture() {
    if (kIsWeb &&
        _musicEnabled &&
        _backgroundMusicPhase != BackgroundMusicPhase.playing) {
      unawaited(startBackgroundMusic(fromUserGesture: true));
    }
  }

  void setSoundEnabled(
    bool enabled, {
    GameActionOrigin origin = GameActionOrigin.system,
  }) {
    if (_soundEnabled == enabled) return;
    _soundEnabled = enabled;
    _emitSettingChanged(FeedbackSetting.sound, enabled, origin);
    unawaited(_persistPreference(_soundPreference, enabled));
  }

  void setMusicEnabled(
    bool enabled, {
    GameActionOrigin origin = GameActionOrigin.system,
  }) {
    if (_musicEnabled == enabled) return;
    _musicEnabled = enabled;
    _emitSettingChanged(FeedbackSetting.music, enabled, origin);
    unawaited(_persistPreference(_musicPreference, enabled));
    if (enabled) {
      unawaited(startBackgroundMusic(fromUserGesture: true));
    } else {
      unawaited(_stopBackgroundMusic());
    }
  }

  void setVibrationEnabled(
    bool enabled, {
    GameActionOrigin origin = GameActionOrigin.system,
  }) {
    if (_vibrationEnabled == enabled) return;
    final wasEnabled = _vibrationEnabled;
    _vibrationEnabled = enabled;
    _emitSettingChanged(FeedbackSetting.vibration, enabled, origin);
    unawaited(_persistPreference(_vibrationPreference, enabled));
    if (_supportsPulsar) {
      unawaited(_applyVibrationSetting(enabled, wasEnabled: wasEnabled));
    }
  }

  Future<void> dispose() {
    if (_lifecycle == GameFeedbackLifecycle.disposed ||
        _lifecycle == GameFeedbackLifecycle.disposing) {
      return _backgroundOperation;
    }

    _setLifecycle(GameFeedbackLifecycle.disposing);
    return _enqueueBackgroundOperation(() async {
      try {
        await _backgroundMusic.dispose();
      } on Object catch (error, stackTrace) {
        _reportOptionalFailure('Background music dispose', error, stackTrace);
      } finally {
        _setBackgroundMusicPhase(BackgroundMusicPhase.disposed);
        _setLifecycle(GameFeedbackLifecycle.disposed);
      }
    });
  }

  void playMove(Mark mark, {bool isWinningMove = false}) {
    if (_soundEnabled) {
      unawaited(_playSound(mark));
    }
    if (_vibrationEnabled && _supportsPulsar) {
      unawaited(isWinningMove ? _playWinHaptic() : _playMoveHaptic());
    }
  }

  void playButtonHaptic() {
    if (_vibrationEnabled && _supportsPulsar) {
      unawaited(_playButtonHaptic());
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = _preferences ??=
          await SharedPreferences.getInstance();
      _soundEnabled = preferences.getBool(_soundPreference) ?? true;
      _musicEnabled = preferences.getBool(_musicPreference) ?? true;
      _vibrationEnabled = preferences.getBool(_vibrationPreference) ?? true;
      _preferencesLoaded = true;
      _emit(GameFeedbackEventKind.settingsLoaded, {
        'settings': {
          'soundEnabled': _soundEnabled,
          'musicEnabled': _musicEnabled,
          'vibrationEnabled': _vibrationEnabled,
        },
      });
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Settings load', error, stackTrace);
    }
  }

  Future<void> _persistPreference(String key, bool enabled) async {
    try {
      final preferences = _preferences ??=
          await SharedPreferences.getInstance();
      await preferences.setBool(key, enabled);
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Settings save', error, stackTrace);
    }
  }

  Future<bool> _ensureBackgroundMusicInitialized() async {
    if (_backgroundMusicPhase.isInitialized) return true;
    if (_backgroundMusicPhase == BackgroundMusicPhase.disposed ||
        _lifecycle == GameFeedbackLifecycle.disposing ||
        _lifecycle == GameFeedbackLifecycle.disposed) {
      return false;
    }

    _setBackgroundMusicPhase(BackgroundMusicPhase.initializing);
    try {
      await _backgroundMusic.initialize();
      _setBackgroundMusicPhase(BackgroundMusicPhase.ready);
      return true;
    } on Object catch (error, stackTrace) {
      _setBackgroundMusicPhase(BackgroundMusicPhase.uninitialized);
      _reportOptionalFailure('Background music setup', error, stackTrace);
      return false;
    }
  }

  Future<void> _stopBackgroundMusic() {
    return _enqueueBackgroundOperation(() async {
      if (!_backgroundMusicPhase.isInitialized ||
          _backgroundMusicPhase == BackgroundMusicPhase.ready) {
        return;
      }
      _setBackgroundMusicPhase(BackgroundMusicPhase.stopping);
      try {
        await _backgroundMusic.stop();
      } on Object catch (error, stackTrace) {
        _reportOptionalFailure('Background music stop', error, stackTrace);
      } finally {
        if (_backgroundMusicPhase != BackgroundMusicPhase.disposed) {
          _setBackgroundMusicPhase(BackgroundMusicPhase.ready);
        }
      }
    });
  }

  Future<void> _enqueueBackgroundOperation(Future<void> Function() operation) {
    final previous = _backgroundOperation;
    final next = () async {
      await previous;
      await operation();
    }();
    _backgroundOperation = next;
    return next;
  }

  Future<void> _applyVibrationSetting(
    bool enabled, {
    required bool wasEnabled,
  }) async {
    try {
      if (!enabled && wasEnabled) {
        await _playButtonHaptic();
        await _pulsar.enableHaptics(false);
      } else if (enabled) {
        await _pulsar.enableHaptics(true);
        await _playButtonHaptic();
      }
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Vibration setting', error, stackTrace);
    }
  }

  Future<void> _playSound(Mark mark) async {
    try {
      await FlameAudio.play(mark == Mark.x ? xSound : oSound);
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Move sound', error, stackTrace);
    }
  }

  Future<void> _preparePulsar() async {
    if (_pulsarSoundDisabled) return;
    await _pulsar.enableSound(false);
    _pulsarSoundDisabled = true;
  }

  Future<void> _playMoveHaptic() async {
    try {
      await _preparePulsar();
      await _pulsar.presets.systemImpactLight();
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Move haptic', error, stackTrace);
    }
  }

  Future<void> _playWinHaptic() async {
    try {
      await _preparePulsar();
      await _pulsar.presets.fanfare();
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Win haptic', error, stackTrace);
    }
  }

  Future<void> _playButtonHaptic() async {
    try {
      await _preparePulsar();
      await _pulsar.presets.systemEffectClick();
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Button haptic', error, stackTrace);
    }
  }

  bool get _supportsPulsar =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _setLifecycle(GameFeedbackLifecycle value) {
    if (_lifecycle == value) return;
    final previous = _lifecycle;
    _lifecycle = value;
    _emit(GameFeedbackEventKind.lifecycleChanged, {
      'from': previous.name,
      'to': value.name,
    });
  }

  void _setBackgroundMusicPhase(BackgroundMusicPhase value) {
    if (_backgroundMusicPhase == value) return;
    final previous = _backgroundMusicPhase;
    _backgroundMusicPhase = value;
    _emit(GameFeedbackEventKind.backgroundMusicChanged, {
      'from': previous.name,
      'to': value.name,
    });
  }

  void _emitSettingChanged(
    FeedbackSetting setting,
    bool enabled,
    GameActionOrigin origin,
  ) {
    _emit(GameFeedbackEventKind.settingChanged, {
      'setting': setting.name,
      'enabled': enabled,
      'origin': origin.name,
    });
  }

  void _emit(
    GameFeedbackEventKind kind, [
    Map<String, Object?> payload = const {},
  ]) {
    final event = GameFeedbackEvent(kind: kind, payload: payload);
    for (final observer in List<GameFeedbackObserver>.of(_observers)) {
      observer(event);
    }
  }

  void _reportOptionalFailure(
    String feature,
    Object error,
    StackTrace stackTrace,
  ) {
    final failure = GameFeedbackFailure(
      feature: feature,
      errorType: error.runtimeType.toString(),
      message: error.toString(),
    );
    _lastFailure = failure;
    _emit(GameFeedbackEventKind.failure, {
      ...failure.toEventPayload(),
      'stackTrace': stackTrace.toString(),
    });
    assert(() {
      debugPrint('$feature unavailable: $error\n$stackTrace');
      return true;
    }());
  }
}
