import 'package:esim_manager/esim_manager_platform_interface.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:esim_manager/esim_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  bool _isEsimSupported = false;
  final _esimManagerPlugin = EsimManager();

  final TextEditingController _activationController = TextEditingController();
  final TextEditingController _smdpController = TextEditingController();
  final List<String> _logs = <String>[];
  InstallResult? _lastParsedInstall;
  Map<String, dynamic>? _lastRawInstallPayload;
  StreamSubscription<Map<String, dynamic>>? _installSub;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    checkEsimSupport();

    // Listen to platform install callbacks
    _installSub = _esimManagerPlugin.onInstallResult.listen((event) {
      addLog('Install callback (raw): ${event.toString()}');
      final resultObj = (event['result'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>();
      setState(() {
        _lastRawInstallPayload = resultObj;
      });
      try {
        final parsed = InstallResult.fromPlatformPayload(resultObj);
        setState(() {
          _lastParsedInstall = parsed;
        });
        addLog('Parsed install result: status=${parsed.status}, message=${parsed.message ?? ''}, profileId=${parsed.profileId ?? ''}');
      } catch (e) {
        addLog('Error parsing install result: $e');
      }
    });
  }

  void addLog(String text) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String()}: $text');
    });
  }

  @override
  void dispose() {
    _installSub?.cancel();
    _activationController.dispose();
    _smdpController.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _esimManagerPlugin.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> checkEsimSupport() async {
    try {
      final supported = await _esimManagerPlugin.isEsimSupported();
      if (!mounted) return;
      setState(() => _isEsimSupported = supported);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion\n'),
              Text('eSIM supported: \\${_isEsimSupported ? 'yes' : 'no'}'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: checkEsimSupport,
                child: const Text('Check eSIM support'),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('activationCode'),
                decoration: const InputDecoration(labelText: 'Activation code'),
                controller: _activationController,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final code = _activationController.text.trim();
                  if (code.isEmpty) {
                    addLog('Activation code empty');
                    return;
                  }
                  addLog('Starting install from activation code...');
                  try {
                    final res = await _esimManagerPlugin.installFromActivationCode(code);
                    addLog('Install started: ${res.status} ${res.message ?? ''} profileId=${res.profileId ?? ''}');
                  } catch (e) {
                    addLog('Error starting install: $e');
                  }
                },
                child: const Text('Install from activation code')
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('smdpUrl'),
                decoration: const InputDecoration(labelText: 'SM‑DP+ URL'),
                controller: _smdpController,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final url = _smdpController.text.trim();
                  if (url.isEmpty) {
                    addLog('SM‑DP+ URL empty');
                    return;
                  }
                  addLog('Starting install from SM‑DP+...');
                  try {
                    final res = await _esimManagerPlugin.installFromSmDp(url);
                    addLog('Install started: ${res.status} ${res.message ?? ''} profileId=${res.profileId ?? ''}');
                  } catch (e) {
                    addLog('Error starting SM‑DP+ install: $e');
                  }
                },
                child: const Text('Install from SM‑DP+')
              ),
              const SizedBox(height: 12),

              // Parsed install result panel
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Last install (parsed):', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Status: ${_lastParsedInstall?.status ?? 'n/a'}'),
                      Text('Message: ${_lastParsedInstall?.message ?? 'n/a'}'),
                      Text('ProfileId: ${_lastParsedInstall?.profileId ?? 'n/a'}'),
                      const SizedBox(height: 8),
                      const Text('Last install (raw payload):', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_lastRawInstallPayload != null ? const JsonEncoder.withIndent('  ').convert(_lastRawInstallPayload) : 'n/a'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Text('Logs:'),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  reverse: true,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Text(_logs[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
