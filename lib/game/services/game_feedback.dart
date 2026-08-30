import 'dart:async';

import 'package:flame_audio/bgm.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:pulsar_haptics/pulsar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../tic_tac_toe_match.dart';

class GameFeedback {
  GameFeedback({Pulsar? pulsar}) : _pulsar = pulsar ?? Pulsar();

  static const xSound = 'place_x.mp3';
  static const oSound = 'place_o.mp3';
  static const backgroundMusic = 'blossom.mp3';
  static const backgroundMusicVolume = 0.32;
  static const _soundPreference = 'settings.sound';
  static const _musicPreference = 'settings.music';
  static const _vibrationPreference = 'settings.vibration';

  final Pulsar _pulsar;
  SharedPreferences? _preferences;
  final Bgm _bgm = Bgm(audioCache: FlameAudio.audioCache);
  bool _pulsarSoundDisabled = false;
  bool _bgmInitialized = false;
  bool _bgmStarting = false;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> preload() async {
    await _loadPreferences();

    try {
      await FlameAudio.audioCache.loadAll(const [xSound, oSound]);
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Audio preload', error, stackTrace);
    }

    try {
      await _bgm.initialize();
      _bgmInitialized = true;
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Background music setup', error, stackTrace);
    }
  }

  Future<void> startBackgroundMusic({bool fromUserGesture = false}) async {
    if (!_musicEnabled ||
        _bgm.isPlaying ||
        _bgmStarting ||
        (kIsWeb && !fromUserGesture)) {
      return;
    }

    _bgmStarting = true;
    try {
      if (!_bgmInitialized) {
        await _bgm.initialize();
        _bgmInitialized = true;
      }
      if (!_musicEnabled) return;
      await _bgm.play(backgroundMusic, volume: backgroundMusicVolume);
      if (!_musicEnabled) {
        await _bgm.stop();
      }
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Background music', error, stackTrace);
    } finally {
      _bgmStarting = false;
    }
  }

  void handleUserGesture() {
    if (kIsWeb && _musicEnabled && !_bgm.isPlaying) {
      unawaited(startBackgroundMusic(fromUserGesture: true));
    }
  }

  void setSoundEnabled(bool enabled) {
    if (_soundEnabled == enabled) return;
    _soundEnabled = enabled;
    unawaited(_persistPreference(_soundPreference, enabled));
  }

  void setMusicEnabled(bool enabled) {
    if (_musicEnabled == enabled) return;
    _musicEnabled = enabled;
    unawaited(_persistPreference(_musicPreference, enabled));
    if (enabled) {
      unawaited(startBackgroundMusic(fromUserGesture: true));
    } else {
      unawaited(_stopBackgroundMusic());
    }
  }

  void setVibrationEnabled(bool enabled) {
    if (_vibrationEnabled == enabled) return;
    final wasEnabled = _vibrationEnabled;
    _vibrationEnabled = enabled;
    unawaited(_persistPreference(_vibrationPreference, enabled));
    if (_supportsPulsar) {
      unawaited(_applyVibrationSetting(enabled, wasEnabled: wasEnabled));
    }
  }

  Future<void> dispose() async {
    if (!_bgmInitialized) return;
    await _bgm.dispose();
    _bgmInitialized = false;
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

  Future<void> _stopBackgroundMusic() async {
    try {
      if (_bgm.isPlaying) {
        await _bgm.stop();
      }
    } on Object catch (error, stackTrace) {
      _reportOptionalFailure('Background music stop', error, stackTrace);
    }
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

  void _reportOptionalFailure(
    String feature,
    Object error,
    StackTrace stackTrace,
  ) {
    assert(() {
      debugPrint('$feature unavailable: $error\n$stackTrace');
      return true;
    }());
  }
}
