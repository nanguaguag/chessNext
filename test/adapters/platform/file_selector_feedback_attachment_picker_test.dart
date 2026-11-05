import 'dart:typed_data';
import 'dart:io';

import 'package:chess_next/adapters/platform/file_selector_feedback_attachment_picker.dart';
import 'package:chess_next/ports/feedback_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final png = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0]);

  test('reads selected PNG and returns a safe immutable attachment', () async {
    final directory = await Directory.systemTemp.createTemp('feedback-picker-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/board.PNG')..writeAsBytesSync(png);
    var requestedTypes = <XTypeGroup>[];
    final picker = FileSelectorFeedbackAttachmentPicker(
      chooser: (types) async {
        requestedTypes = types;
        return [XFile(file.path)];
      },
    );
    final result = await picker.pickAttachments(remaining: 3);
    expect(requestedTypes.single.extensions, ['png', 'jpg', 'jpeg']);
    expect(result!.single.name, 'board.PNG');
    expect(result.single.mimeType, 'image/png');
    expect(result.single.bytes, png);
    expect(() => result.add(result.single), throwsUnsupportedError);
  });

  test(
    'rejects unsupported formats, oversized files and excess selection',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'feedback-picker-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final unsupported = FileSelectorFeedbackAttachmentPicker(
        chooser: (_) async => [XFile.fromData(png, name: 'board.gif')],
      );
      await expectLater(
        unsupported.pickAttachments(remaining: 3),
        throwsA(
          isA<FeedbackAttachmentPickerException>().having(
            (error) => error.reason,
            'reason',
            FeedbackAttachmentPickerFailure.format,
          ),
        ),
      );

      final oversized = FileSelectorFeedbackAttachmentPicker(
        chooser: (_) async => [
          XFile(
            (File(
                  '${directory.path}/large.png',
                )..writeAsBytesSync(Uint8List(FeedbackAttachment.maxBytes + 1)))
                .path,
          ),
        ],
      );
      await expectLater(
        oversized.pickAttachments(remaining: 3),
        throwsA(
          isA<FeedbackAttachmentPickerException>().having(
            (error) => error.reason,
            'reason',
            FeedbackAttachmentPickerFailure.size,
          ),
        ),
      );

      final tooMany = FileSelectorFeedbackAttachmentPicker(
        chooser: (_) async => List.generate(
          2,
          (index) => XFile.fromData(png, name: 'board$index.png'),
        ),
      );
      await expectLater(
        tooMany.pickAttachments(remaining: 1),
        throwsA(isA<FeedbackAttachmentPickerException>()),
      );
    },
  );
}
