import 'package:flutter_test/flutter_test.dart';
import 'package:esim_manager/esim_manager.dart';
import 'package:esim_manager/esim_manager_platform_interface.dart';
import 'package:esim_manager/esim_manager_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEsimManagerPlatform
    with MockPlatformInterfaceMixin
    implements EsimManagerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> isEsimSupported() => Future.value(true);

  @override
  Future<List<EsimProfile>> listProfiles() => Future.value([
    EsimProfile(
      id: 'p1',
      iccid: 'iccid1',
      eid: 'eid1',
      nickname: 'Work',
      isActive: true,
    ),
  ]);

  @override
  Future<InstallResult> installFromActivationCode(String activationCode) =>
      Future.value(
        InstallResult(status: InstallStatus.success, profileId: 'p1'),
      );

  @override
  Future<InstallResult> installFromSmDp(
    String smDpUrl, {
    String? confirmationCode,
  }) => Future.value(InstallResult(status: InstallStatus.pending));

  @override
  Future<bool> removeProfile(String profileId) => Future.value(true);

  @override
  Future<EsimProfile?> getActiveProfile() => Future.value(
    EsimProfile(
      id: 'p1',
      iccid: 'iccid1',
      eid: 'eid1',
      nickname: 'Work',
      isActive: true,
    ),
  );

  @override
  // TODO: implement onInstallResult
  Stream<Map<String, dynamic>> get onInstallResult =>
      throw UnimplementedError();

  @override
  Future<bool> installIosViaLpa(String lpaString) {
    // TODO: implement installIosViaLpa
    throw UnimplementedError();
  }
  
  @override
  // TODO: implement installEvents
  Stream<InstallEvent> get installEvents => throw UnimplementedError();
}

void main() {
  final EsimManagerPlatform initialPlatform = EsimManagerPlatform.instance;

  test('$MethodChannelEsimManager is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEsimManager>());
  });

  test('getPlatformVersion', () async {
    EsimManager esimManagerPlugin = EsimManager();
    MockEsimManagerPlatform fakePlatform = MockEsimManagerPlatform();
    EsimManagerPlatform.instance = fakePlatform;

    expect(await esimManagerPlugin.getPlatformVersion(), '42');
  });

  test('isEsimSupported delegates to platform', () async {
    EsimManager esimManagerPlugin = EsimManager();
    MockEsimManagerPlatform fakePlatform = MockEsimManagerPlatform();
    EsimManagerPlatform.instance = fakePlatform;

    expect(await esimManagerPlugin.isEsimSupported(), isTrue);
  });

  test('listProfiles delegates to platform', () async {
    EsimManager esimManagerPlugin = EsimManager();
    MockEsimManagerPlatform fakePlatform = MockEsimManagerPlatform();
    EsimManagerPlatform.instance = fakePlatform;

    final profiles = await esimManagerPlugin.listProfiles();
    expect(profiles, hasLength(1));
    expect(profiles.first.id, 'p1');
  });
}
