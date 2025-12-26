import 'package:flutter_test/flutter_test.dart';
import 'package:esim_manager/esim_manager_platform_interface.dart';

void main() {
  test('fromPlatformPayload handles status string', () {
    final res = InstallResult.fromPlatformPayload({'status': 'success', 'message': 'ok', 'profileId': 'p1'});
    expect(res.status, InstallStatus.success);
    expect(res.profileId, 'p1');
  });

  test('fromPlatformPayload handles accepted boolean', () {
    final res1 = InstallResult.fromPlatformPayload({'accepted': true});
    expect(res1.status, InstallStatus.success);

    final res2 = InstallResult.fromPlatformPayload({'accepted': false, 'message': 'user declined'});
    expect(res2.status, InstallStatus.failed);
    expect(res2.message, 'user declined');
  });

  test('fromPlatformPayload handles numeric resultCode', () {
    final ok = InstallResult.fromPlatformPayload({'resultCode': 0});
    expect(ok.status, InstallStatus.success);

    final fail = InstallResult.fromPlatformPayload({'resultCode': 5});
    expect(fail.status, InstallStatus.failed);
    expect(fail.message, 'resultCode=5');
  });

  test('fromPlatformPayload falls back to message', () {
    final res = InstallResult.fromPlatformPayload({'error': 'network'});
    expect(res.status, InstallStatus.failed);
    expect(res.message, 'network');
  });
}
