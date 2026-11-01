import 'dart:io';
import 'package:chess_next/adapters/storage/file_preferences_repository.dart';
import 'package:chess_next/application/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'settings reopen, recover a valid backup and preserve malformed originals',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'chessnext-settings-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = FilePreferencesRepository(() async => directory);
      expect(await repository.load(), isNull);
      final first = AppPreferences(
        theme: ThemePreference.dark,
        threads: 2,
        multiPv: 3,
      );
      await repository.save(first);
      await repository.save(first.copyWith(thinkTimeMs: 3000));
      expect(
        (await FilePreferencesRepository(
          () async => directory,
        ).load())!.value.thinkTimeMs,
        3000,
      );
      final primary = File(
        '${directory.path}/chessnext-settings/preferences.json',
      );
      final backup = File(
        '${directory.path}/chessnext-settings/preferences.bak',
      );
      await primary.writeAsString('{"schema":2}');
      final recovered = (await repository.load())!;
      expect(recovered.recovered, isTrue);
      expect(recovered.value, first);
      await backup.writeAsString('broken');
      await expectLater(repository.load(), throwsFormatException);
      await repository.save(first);
      final archives = await Directory('${directory.path}/chessnext-settings')
          .list()
          .where(
            (entry) => entry is Directory && entry.path.contains('.damaged-'),
          )
          .toList();
      expect(
        await File('${archives.single.path}/original.json').readAsString(),
        '{"schema":2}',
      );
      expect((await repository.load())!.value, first);
    },
  );
}
