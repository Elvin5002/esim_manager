import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'esim_manager_platform_interface.dart';

/// An implementation of [EsimManagerPlatform] that uses method channels.
class MethodChannelEsimManager extends EsimManagerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('esim_manager');

  final _installResultController = StreamController<Map<String, dynamic>>.broadcast();
  final _installEventController = StreamController<InstallEvent>.broadcast();

  MethodChannelEsimManager() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  Stream<Map<String, dynamic>> get onInstallResult => _installResultController.stream;

  @override
  Stream<InstallEvent> get installEvents => _installEventController.stream;

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onInstallResult':
        final args = call.arguments as Map<dynamic, dynamic>?;
        if (args != null) {
          final raw = Map<String, dynamic>.from(args.cast<String, dynamic>());
          _installResultController.add(raw);

          try {
            final event = InstallEvent.fromRaw(raw);
            _installEventController.add(event);
          } catch (_) {
            // ignore parsing errors, caller can use raw payload
          }
        }
        break;
      default:
        break;
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> isEsimSupported() async {
    try {
      final supported = await methodChannel.invokeMethod<bool>('isEsimSupported');
      return supported == true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<List<EsimProfile>> listProfiles() async {
    final result = await methodChannel.invokeMethod<List<dynamic>>('listProfiles');
    if (result == null) return <EsimProfile>[];
    return result
        .map((e) => EsimProfile.fromMap(e as Map<dynamic, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<InstallResult> installEsim(String lpa) async {
    if (lpa.trim().isEmpty) {
      return InstallResult(status: InstallStatus.failed, message: 'LPA string cannot be empty');
    }
    try {
      final result = await methodChannel.invokeMethod<dynamic>(
        'installEsim',
        <String, dynamic>{'lpa': lpa},
      );
      if (result is Map) {
        return InstallResult.fromPlatformPayload(result);
      }
      final success = result == true;
      return InstallResult(
        status: success ? InstallStatus.success : InstallStatus.failed,
        message: success ? 'Installer launched successfully' : 'Failed to launch installer',
      );
    } on PlatformException catch (e) {
      debugPrint('eSIM install error: ${e.message}');
      return InstallResult(status: InstallStatus.failed, message: e.message);
    }
  }

  @override
  Future<bool> removeProfile(String profileId) async {
    try {
      final removed = await methodChannel.invokeMethod<bool>('removeProfile', <String, dynamic>{'profileId': profileId});
      return removed == true;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<EsimProfile?> getActiveProfile() async {
    final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>?>('getActiveProfile');
    if (result == null) return null;
    return EsimProfile.fromMap(result);
  }
}
