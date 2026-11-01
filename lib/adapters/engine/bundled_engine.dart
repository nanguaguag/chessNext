import 'dart:io';
import '../../ports/engine_gateway.dart';
import 'engine_transport.dart';
import 'uci_engine.dart';

Future<EngineGateway> openBundledEngine() async {
  if (!Platform.isMacOS) {
    throw UnsupportedError('This platform needs a native engine adapter');
  }
  final directory =
      '${File(Platform.resolvedExecutable).parent.parent.path}/Resources/pikafish';
  final executable = File('$directory/Pikafish-MacOS-universal');
  final network = File('$directory/pikafish.nnue');
  if (!await executable.exists() || !await network.exists()) {
    throw StateError('本地分析引擎尚未安装');
  }
  final transport = await ProcessEngineTransport.spawn(
    executable.path,
    workingDirectory: directory,
  );
  try {
    return UciEngine(transport, networkPath: network.path);
  } catch (_) {
    await transport.close();
    rethrow;
  }
}
