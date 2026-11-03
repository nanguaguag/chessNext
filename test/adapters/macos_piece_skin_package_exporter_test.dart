import 'package:chess_next/adapters/platform/macos_piece_skin_package_exporter.dart';
import 'package:chess_next/ports/record_file_exporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previous = debugDefaultTargetPlatformOverride;
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);
  tearDown(() => debugDefaultTargetPlatformOverride = previous);

  test('cancel before save does not open chooser', () async {
    var chose = false;
    final exporter = MacOsPieceSkinPackageExporter(
      chooser: (_) async {
        chose = true;
        return '/tmp/skin.zip';
      },
      writer: (_, _) async {},
    );
    final cancellation = FileExportCancellation()..cancel();
    expect(
      await exporter.saveZip(
        suggestedName: 'skin',
        bytes: Uint8List.fromList([1]),
        cancellation: cancellation,
      ),
      RecordFileExportResult.cancelled,
    );
    expect(chose, isFalse);
  });

  test('writes selected ZIP bytes unchanged', () async {
    final expected = Uint8List.fromList([0x50, 0x4b, 3, 4]);
    String? suggested;
    String? path;
    Uint8List? actual;
    final exporter = MacOsPieceSkinPackageExporter(
      chooser: (name) async {
        suggested = name;
        return '/tmp/skin.zip';
      },
      writer: (destination, bytes) async {
        path = destination;
        actual = bytes;
      },
    );
    expect(
      await exporter.saveZip(
        suggestedName: 'skin-name',
        bytes: expected,
        cancellation: FileExportCancellation(),
      ),
      RecordFileExportResult.saved,
    );
    expect(suggested, 'skin-name');
    expect(path, '/tmp/skin.zip');
    expect(actual, expected);
  });
}
