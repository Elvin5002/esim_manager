import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esim_manager/esim_manager_method_channel.dart';
import 'package:esim_manager/esim_manager_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelEsimManager platform = MethodChannelEsimManager();
  const MethodChannel channel = MethodChannel('esim_manager');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getPlatformVersion':
            return '42';
          case 'isEsimSupported':
            return true;
          case 'listProfiles':
            return [
              {'id': 'p1', 'iccid': 'iccid1', 'eid': 'eid1', 'nickname': 'Work', 'isActive': true},
              {'id': 'p2', 'iccid': 'iccid2', 'eid': 'eid2', 'nickname': 'Travel', 'isActive': false},
            ];
          case 'installFromActivationCode':
            return {'status': 'success', 'message': 'ok', 'profileId': 'p3'};
          case 'installFromSmDp':
            return {'status': 'pending', 'message': 'in progress', 'profileId': null};
          case 'installIosViaLpa':
            // Simulate that the system accepted opening the URL on iOS
            return true;
          case 'removeProfile':
            return true;
          case 'getActiveProfile':
            return {'id': 'p1', 'iccid': 'iccid1', 'eid': 'eid1', 'nickname': 'Work', 'isActive': true};
          default:
            return null;
        }
      },
    );
  });

  test('install result callback is received via stream', () async {
    final completer = Completer<Map<String, dynamic>>();
    platform.onInstallResult.listen((event) {
      completer.complete(event);
    });

    // Simulate platform calling back with install result
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall('onInstallResult', {'requestId': 'r1', 'result': {'status': 'success'}})),
      (ByteData? data) {},
    );

    final event = await completer.future.timeout(const Duration(seconds: 2));
    expect(event['requestId'], 'r1');
    expect((event['result'] as Map)['status'], 'success');
  });

  test('install event stream yields parsed InstallEvent', () async {
    final completer = Completer<InstallEvent>();
    platform.installEvents.listen((event) {
      completer.complete(event);
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall('onInstallResult', {'requestId': 'r2', 'result': {'accepted': true}})),
      (ByteData? data) {},
    );

    final event = await completer.future.timeout(const Duration(seconds: 2));
    expect(event.requestId, 'r2');
    expect(event.result.status, InstallStatus.success);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('isEsimSupported returns true', () async {
    expect(await platform.isEsimSupported(), isTrue);
  });

  test('listProfiles returns parsed profiles', () async {
    final profiles = await platform.listProfiles();
    expect(profiles, hasLength(2));
    expect(profiles.first.id, 'p1');
    expect(profiles.first.isActive, isTrue);
  });

  test('installFromActivationCode returns success InstallResult', () async {
    final res = await platform.installFromActivationCode('code');
    expect(res.status, InstallStatus.success);
    expect(res.profileId, 'p3');
  });

  test('installFromSmDp returns pending InstallResult', () async {
    final res = await platform.installFromSmDp('https://smdp');
    expect(res.status, InstallStatus.pending);
  });

  test('installIosViaLpa returns true (simulated)', () async {
    final launched = await platform.installIosViaLpa('some-lpa-string');
    expect(launched, isTrue);
  });

  test('removeProfile returns true', () async {
    final removed = await platform.removeProfile('p1');
    expect(removed, isTrue);
  });

  test('getActiveProfile returns profile', () async {
    final profile = await platform.getActiveProfile();
    expect(profile, isNotNull);
    expect(profile!.id, 'p1');
  });
}
