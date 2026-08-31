import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'runtime_inspection.dart';

abstract interface class RuntimeInspectionTarget {
  RuntimeInspectionCapabilities capabilities();

  RuntimeSnapshot snapshot(SnapshotDetail detail);

  RuntimeEventBatch eventBatchAfter(int sequence);

  RuntimeCommandResult dispatch(RuntimeCommandEnvelope command);
}

final class RuntimeInspectionSession {
  const RuntimeInspectionSession._({required this.id, required this.target});

  final int id;
  final RuntimeInspectionTarget target;

  bool get isActive => identical(CoreflameDebugBridge._session, this);

  Map<String, Object?> envelope(Map<String, Object?> payload) => {
    ...payload,
    'sessionId': id,
  };
}

class CoreflameDebugBridge {
  CoreflameDebugBridge._();

  static RuntimeInspectionSession? _session;
  static int _nextSessionId = 1;
  static bool _registered = false;

  static RuntimeInspectionSession? attach(RuntimeInspectionTarget target) {
    if (!kDebugMode) return null;
    final session = RuntimeInspectionSession._(
      id: _nextSessionId,
      target: target,
    );
    _nextSessionId += 1;
    _session = session;
    if (_registered) return session;

    developer.registerExtension(
      'ext.coreflame.getCapabilities',
      _getCapabilities,
    );
    developer.registerExtension('ext.coreflame.getSnapshot', _getSnapshot);
    developer.registerExtension('ext.coreflame.getEvents', _getEvents);
    developer.registerExtension('ext.coreflame.dispatch', _dispatch);
    _registered = true;
    return session;
  }

  static void detach({
    required RuntimeInspectionTarget target,
    required RuntimeInspectionSession session,
  }) {
    if (identical(_session, session) && identical(session.target, target)) {
      _session = null;
    }
  }

  static bool publish({
    required RuntimeInspectionTarget target,
    required RuntimeInspectionSession session,
    required RuntimeEvent event,
  }) {
    if (!kDebugMode ||
        !identical(_session, session) ||
        !identical(session.target, target)) {
      return false;
    }
    developer.postEvent('Coreflame.Event', session.envelope(event.toJson()));
    return true;
  }

  static Future<developer.ServiceExtensionResponse> _getCapabilities(
    String method,
    Map<String, String> parameters,
  ) async {
    final session = _session;
    if (session == null) return _unavailable();
    final target = session.target;

    try {
      final arguments = _requestArguments(parameters);
      _rejectUnexpected(arguments, const {});
      return _result(session: session, value: target.capabilities().toJson());
    } on FormatException catch (error) {
      return _invalidParameters(error.message);
    }
  }

  static Future<developer.ServiceExtensionResponse> _getSnapshot(
    String method,
    Map<String, String> parameters,
  ) async {
    final session = _session;
    if (session == null) return _unavailable();
    final target = session.target;

    try {
      final arguments = _requestArguments(parameters);
      _rejectUnexpected(arguments, const {'detail'});
      final detail = SnapshotDetail.parse(arguments['detail']);
      return _result(session: session, value: target.snapshot(detail).toJson());
    } on FormatException catch (error) {
      return _invalidParameters(error.message);
    }
  }

  static Future<developer.ServiceExtensionResponse> _getEvents(
    String method,
    Map<String, String> parameters,
  ) async {
    final session = _session;
    if (session == null) return _unavailable();
    final target = session.target;

    try {
      final arguments = _requestArguments(parameters);
      _rejectUnexpected(arguments, const {'after'});
      final rawAfter = arguments['after'];
      final after = rawAfter == null ? 0 : int.tryParse(rawAfter);
      if (after == null || after < 0) {
        throw const FormatException(
          'Expected after to be a non-negative integer',
        );
      }
      return _result(
        session: session,
        value: target.eventBatchAfter(after).toJson(),
      );
    } on FormatException catch (error) {
      return _invalidParameters(error.message);
    }
  }

  static Future<developer.ServiceExtensionResponse> _dispatch(
    String method,
    Map<String, String> parameters,
  ) async {
    final session = _session;
    if (session == null) return _unavailable();
    final target = session.target;

    try {
      final request = RuntimeCommandEnvelope.parse(
        _requestArguments(parameters),
      );
      return _result(
        session: session,
        value: target.dispatch(request).toJson(),
      );
    } on FormatException catch (error) {
      return _invalidParameters(error.message);
    } on RangeError catch (error) {
      return _invalidParameters(error.message);
    }
  }

  static void _rejectUnexpected(
    Map<String, String> parameters,
    Set<String> allowed,
  ) {
    final unexpected = parameters.keys
        .where((key) => !allowed.contains(key))
        .toList(growable: false);
    if (unexpected.isNotEmpty) {
      throw FormatException(
        'Unexpected parameter(s): ${unexpected.join(', ')}',
      );
    }
  }

  static Map<String, String> _requestArguments(
    Map<String, String> parameters,
  ) => Map.fromEntries(
    parameters.entries.where((entry) => entry.key != 'isolateId'),
  );

  static developer.ServiceExtensionResponse _result({
    required RuntimeInspectionSession session,
    required Map<String, Object?> value,
  }) {
    return developer.ServiceExtensionResponse.result(
      jsonEncode(session.envelope(value)),
    );
  }

  static developer.ServiceExtensionResponse _unavailable() {
    return developer.ServiceExtensionResponse.error(
      developer.ServiceExtensionResponse.extensionError,
      'No active Coreflame game is attached',
    );
  }

  static developer.ServiceExtensionResponse _invalidParameters(String message) {
    return developer.ServiceExtensionResponse.error(
      developer.ServiceExtensionResponse.invalidParams,
      message,
    );
  }
}
