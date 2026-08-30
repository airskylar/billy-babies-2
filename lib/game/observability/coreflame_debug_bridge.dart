import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'coreflame_observability.dart';

abstract interface class CoreflameDebugTarget {
  CoreflameSnapshot snapshot(SnapshotDetail detail);

  CoreflameEventBatch eventBatchAfter(int sequence);

  CoreflameCommandResult dispatch(CoreflameCommandRequest request);
}

class CoreflameDebugBridge {
  CoreflameDebugBridge._();

  static CoreflameDebugTarget? _target;
  static bool _registered = false;

  static void attach(CoreflameDebugTarget target) {
    if (!kDebugMode) return;
    _target = target;
    if (_registered) return;

    developer.registerExtension('ext.coreflame.getSnapshot', _getSnapshot);
    developer.registerExtension('ext.coreflame.getEvents', _getEvents);
    developer.registerExtension('ext.coreflame.dispatch', _dispatch);
    _registered = true;
  }

  static void detach(CoreflameDebugTarget target) {
    if (identical(_target, target)) {
      _target = null;
    }
  }

  static void publish(CoreflameEvent event) {
    if (!kDebugMode) return;
    developer.postEvent('Coreflame.Event', event.toJson());
  }

  static Future<developer.ServiceExtensionResponse> _getSnapshot(
    String method,
    Map<String, String> parameters,
  ) async {
    final target = _target;
    if (target == null) return _unavailable();

    try {
      final arguments = _requestArguments(parameters);
      _rejectUnexpected(arguments, const {'detail'});
      final detail = SnapshotDetail.parse(arguments['detail']);
      return _result(target.snapshot(detail).toJson());
    } on FormatException catch (error) {
      return _invalidParameters(error.message);
    }
  }

  static Future<developer.ServiceExtensionResponse> _getEvents(
    String method,
    Map<String, String> parameters,
  ) async {
    final target = _target;
    if (target == null) return _unavailable();

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
      return _result(target.eventBatchAfter(after).toJson());
    } on FormatException catch (error) {
      return _invalidParameters(error.message);
    }
  }

  static Future<developer.ServiceExtensionResponse> _dispatch(
    String method,
    Map<String, String> parameters,
  ) async {
    final target = _target;
    if (target == null) return _unavailable();

    try {
      final request = CoreflameCommandRequest.parse(
        _requestArguments(parameters),
      );
      return _result(target.dispatch(request).toJson());
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

  static developer.ServiceExtensionResponse _result(
    Map<String, Object?> value,
  ) {
    return developer.ServiceExtensionResponse.result(jsonEncode(value));
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
