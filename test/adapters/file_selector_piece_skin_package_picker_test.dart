import 'dart:typed_data';

import 'package:chess_next/adapters/platform/file_selector_piece_skin_package_picker.dart';
import 'package:chess_next/ports/piece_skin_package_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reads a bounded selected ZIP and filters by extension', () async {
    List<XTypeGroup>? requested;
    final expected = Uint8List.fromList(List<int>.generate(64, (i) => i));
    final picker = FileSelectorPieceSkinPackagePicker(
      chooser: (types) async {
        requested = types;
        return XFile.fromData(expected, name: 'skin.zip');
      },
    );
    expect(await picker.pickZip(), expected);
    expect(requested!.single.extensions, ['zip']);
  });

  test('rejects input shorter than a ZIP container', () async {
    final picker = FileSelectorPieceSkinPackagePicker(
      chooser: (_) async =>
          XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'skin.zip'),
    );
    await expectLater(
      picker.pickZip(),
      throwsA(
        isA<PieceSkinPackageReadException>().having(
          (error) => error.failure,
          'failure',
          PieceSkinPackageReadFailure.tooLarge,
        ),
      ),
    );
  });
}
