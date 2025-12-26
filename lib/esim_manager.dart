// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'esim_manager_platform_interface.dart';

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

  Future<InstallResult> installFromActivationCode(String activationCode) {
    return EsimManagerPlatform.instance.installFromActivationCode(activationCode);
  }

  Future<InstallResult> installFromSmDp(String smDpUrl, {String? confirmationCode}) {
    return EsimManagerPlatform.instance.installFromSmDp(smDpUrl, confirmationCode: confirmationCode);
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

  /// Open Apple's LPA provisioning URL on iOS using an encoded LPA string.
  /// Returns true if the OS was asked to open the URL (may be false on non-iOS platforms).
  Future<bool> installIosViaLpa(String lpaString) {
    return EsimManagerPlatform.instance.installIosViaLpa(lpaString);
  }
}
