import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'esim_manager_method_channel.dart';

/// A lightweight model representing an eSIM profile on the device.
class EsimProfile {
  final String id;
  final String? iccid;
  final String? eid;
  final String? nickname;
  final bool isActive;

  EsimProfile({
    required this.id,
    this.iccid,
    this.eid,
    this.nickname,
    required this.isActive,
  });

  factory EsimProfile.fromMap(Map<dynamic, dynamic> map) {
    return EsimProfile(
      id: map['id']?.toString() ?? '',
      iccid: map['iccid']?.toString(),
      eid: map['eid']?.toString(),
      nickname: map['nickname']?.toString(),
      isActive: map['isActive'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'iccid': iccid,
        'eid': eid,
        'nickname': nickname,
        'isActive': isActive,
      };
}

enum InstallStatus { success, failed, pending }

class InstallResult {
  final InstallStatus status;
  final String? message;
  final String? profileId;

  InstallResult({required this.status, this.message, this.profileId});

  factory InstallResult.fromMap(Map<dynamic, dynamic> map) {
    final statusStr = map['status']?.toString();
    final status = statusStr == 'success'
        ? InstallStatus.success
        : statusStr == 'pending'
            ? InstallStatus.pending
            : InstallStatus.failed;
    return InstallResult(
      status: status,
      message: map['message']?.toString(),
      profileId: map['profileId']?.toString(),
    );
  }

  /// Parse a variety of platform payloads (Android PendingIntent extras, iOS completion result, etc.)
  /// into a conservative [InstallResult]. This helps normalize different platform callback shapes.
  factory InstallResult.fromPlatformPayload(Map<dynamic, dynamic>? payload) {
    if (payload == null) {
      return InstallResult(status: InstallStatus.failed, message: 'empty payload');
    }

    // If the platform already provides a clear `status`, prefer that.
    if (payload['status'] != null) {
      return InstallResult.fromMap(payload);
    }

    // iOS-style: accepted boolean and optional error
    final accepted = payload['accepted'];
    if (accepted is bool) {
      if (accepted) {
        return InstallResult(status: InstallStatus.success, message: payload['message']?.toString());
      }
      return InstallResult(status: InstallStatus.failed, message: payload['message']?.toString());
    }

    // Android-style: look for numeric result codes (common keys)
    final int? code = (payload['resultCode'] is int)
        ? payload['resultCode'] as int
        : (payload['result'] is int)
            ? payload['result'] as int
            : (payload['code'] is int)
                ? payload['code'] as int
                : null;
    if (code != null) {
      // Heuristic: 0 => success, other => failure (we don't assume other meanings)
      if (code == 0) {
        return InstallResult(status: InstallStatus.success, message: 'resultCode=0');
      }
      return InstallResult(status: InstallStatus.failed, message: 'resultCode=$code');
    }

    // Fallback: look for known message or error fields
    final msg = payload['message'] ?? payload['error'] ?? payload['msg'];
    if (msg != null) {
      return InstallResult(status: InstallStatus.failed, message: msg.toString());
    }

    // Unknown payload shape — return failed conservatively but include raw payload as message
    return InstallResult(status: InstallStatus.failed, message: 'unrecognized payload: ${payload.toString()}');
  }

  Map<String, dynamic> toMap() => {
        'status': status.toString().split('.').last,
        'message': message,
        'profileId': profileId,
      };
}

/// A typed install event that combines the platform request id, parsed result and raw payload.
class InstallEvent {
  final String requestId;
  final InstallResult result;
  final Map<String, dynamic>? rawPayload;

  InstallEvent({required this.requestId, required this.result, this.rawPayload});

  factory InstallEvent.fromRaw(Map<dynamic, dynamic> raw) {
    final req = raw['requestId']?.toString() ?? '';
    final payload = (raw['result'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>();
    final parsed = InstallResult.fromPlatformPayload(payload);
    return InstallEvent(requestId: req, result: parsed, rawPayload: payload);
  }
}

abstract class EsimManagerPlatform extends PlatformInterface {
  /// Constructs a EsimManagerPlatform.
  EsimManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static EsimManagerPlatform _instance = MethodChannelEsimManager();

  /// The default instance of [EsimManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelEsimManager].
  static EsimManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EsimManagerPlatform] when
  /// they register themselves.
  static set instance(EsimManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns whether the current device/platform supports eSIM operations.
  Future<bool> isEsimSupported() {
    throw UnimplementedError('isEsimSupported() has not been implemented.');
  }

  /// Lists installed eSIM profiles.
  Future<List<EsimProfile>> listProfiles() {
    throw UnimplementedError('listProfiles() has not been implemented.');
  }

  /// Installs a profile using an activation code (e.g., SM-DP+ activation code or QR content depending on platform).
  Future<InstallResult> installFromActivationCode(String activationCode) {
    throw UnimplementedError('installFromActivationCode() has not been implemented.');
  }

  /// Installs a profile using an SM‑DP+ URL and optional confirmation/activation code.
  Future<InstallResult> installFromSmDp(String smDpUrl, {String? confirmationCode}) {
    throw UnimplementedError('installFromSmDp() has not been implemented.');
  }

  /// Removes an installed profile by id.
  Future<bool> removeProfile(String profileId) {
    throw UnimplementedError('removeProfile() has not been implemented.');
  }

  /// Returns the currently active profile if any.
  Future<EsimProfile?> getActiveProfile() {
    throw UnimplementedError('getActiveProfile() has not been implemented.');
  }

  /// Stream that emits platform install results (raw payloads).
  /// Each event is a map with at least `requestId` and `result` entries as provided by the platform.
  Stream<Map<String, dynamic>> get onInstallResult {
    throw UnimplementedError('onInstallResult() has not been implemented.');
  }

  /// A typed install event that contains a parsed [InstallResult] with raw payload.
  Stream<InstallEvent> get installEvents {
    throw UnimplementedError('installEvents() has not been implemented.');
  }

  /// Installs iOS eSIM via Apple LPA URL (LPA string). Returns true if the system URL was opened successfully.
  /// This is a convenience for opening Apple's official LPA provisioning URL.
  Future<bool> installIosViaLpa(String lpaString) {
    throw UnimplementedError('installIosViaLpa() has not been implemented.');
  }

  /// Existing helper kept for backwards compatibility.
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
