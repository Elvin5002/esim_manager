// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'esim_manager_platform_interface.dart';

export 'esim_manager_platform_interface.dart' show EsimProfile, InstallResult, InstallStatus, InstallEvent;

class EsimManager {
  Future<String?> getPlatformVersion() {
    return EsimManagerPlatform.instance.getPlatformVersion();
  }

  Future<bool> isEsimSupported() {
    return EsimManagerPlatform.instance.isEsimSupported();
  }

  Future<List<EsimProfile>> listProfiles() {
    return EsimManagerPlatform.instance.listProfiles();
  }

  Future<InstallResult> installEsim(String lpa) {
    if (lpa.trim().isEmpty) {
      return Future.value(InstallResult(status: InstallStatus.failed, message: 'LPA string cannot be empty'));
    }
    return EsimManagerPlatform.instance.installEsim(lpa);
  }

  Future<bool> removeProfile(String profileId) {
    return EsimManagerPlatform.instance.removeProfile(profileId);
  }

  Future<EsimProfile?> getActiveProfile() {
    return EsimManagerPlatform.instance.getActiveProfile();
  }

  /// Stream of raw install result callbacks from the platform.
  Stream<Map<String, dynamic>> get onInstallResult => EsimManagerPlatform.instance.onInstallResult;

  /// Typed install events that wrap parsed [InstallResult] with raw payload and request id.
  Stream<InstallEvent> get installEvents => EsimManagerPlatform.instance.installEvents;
}

