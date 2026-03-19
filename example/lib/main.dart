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
  String status = 'Idle';

  final TextEditingController _lpaController = TextEditingController();
  final List<String> _logs = <String>[];
  InstallResult? _lastParsedInstall;
  Map<String, dynamic>? _lastRawInstallPayload;
  StreamSubscription<Map<String, dynamic>>? _installSub;

    static const String _exampleLpa =
      'LPA:1\$SMDP.GSMA.COM\$ABC1234567890';

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
    _lpaController.dispose();
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

  Future<void> _installEsim() async {
    final lpa = _lpaController.text.trim();
    if (lpa.isEmpty) {
      setState(() => status = 'LPA string is empty');
      return;
    }

    setState(() => status = 'Starting install…');
    final ok = await _esimManagerPlugin.installEsim(lpa);
    setState(() {
      status = ok
          ? 'Installer opened successfully'
          : 'Failed to open installer';
    });
    addLog('installEsim(lpa) => $ok');
  }

  void _fillExampleLpa() {
    _lpaController.text = _exampleLpa;
    addLog('Example LPA inserted');
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Running on: $_platformVersion'),
                const SizedBox(height: 6),
                Text('eSIM supported: ${_isEsimSupported ? 'yes' : 'no'}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: checkEsimSupport,
                  child: const Text('Check eSIM support'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'LPA String Example',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SelectableText(_exampleLpa),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _fillExampleLpa,
                  child: const Text('Use Example LPA'),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('lpaString'),
                  controller: _lpaController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'LPA string',
                    hintText: 'LPA:1\$SMDP.GSMA.COM\$ABC1234567890',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _installEsim,
                  child: const Text('Install eSIM from LPA'),
                ),
                const SizedBox(height: 12),
                Text('Status: $status'),
                const SizedBox(height: 12),

                // Parsed install result panel
                Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
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
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _logs.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(_logs[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
