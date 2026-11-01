import 'dart:io';
import 'package:flutter/material.dart';
import 'engine_probe.dart';

void main() => runApp(const ProbeApp());

class ProbeApp extends StatefulWidget {
  const ProbeApp({super.key});
  @override
  State<ProbeApp> createState() => _ProbeAppState();
}

class _ProbeAppState extends State<ProbeApp> {
  late final Future<String> result;
  @override
  void initState() {
    super.initState();
    result =
        runEngineProbe(
              const String.fromEnvironment('PIKAFISH_DIR').isEmpty
                  ? '${File(Platform.resolvedExecutable).parent.parent.path}/Resources/pikafish'
                  : const String.fromEnvironment('PIKAFISH_DIR'),
            )
            .then((log) {
              final path = Platform.environment['PIKAFISH_PROBE_LOG'];
              if (path != null) File(path).writeAsStringSync(log);
              // Bounded native-app smoke mode, separate from the interactive probe.
              if (const bool.fromEnvironment('PROBE_AUTO_EXIT')) {
                stdout.write(log);
                exit(0);
              }
              return log;
            })
            .catchError((Object error) {
              if (const bool.fromEnvironment('PROBE_AUTO_EXIT')) {
                stderr.writeln(error);
                exit(1);
              }
              throw error;
            });
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    home: Scaffold(
      appBar: AppBar(title: const Text('Flutter ↔ Pikafish 通信验证')),
      body: FutureBuilder<String>(
        future: result,
        builder: (context, snapshot) =>
            snapshot.connectionState != ConnectionState.done
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  snapshot.hasError
                      ? 'FAIL: ${snapshot.error}'
                      : snapshot.data!,
                ),
              ),
      ),
    ),
  );
}
