import 'adapters/platform/macos_record_file_exporter.dart';
import 'adapters/platform/file_selector_record_picker.dart';
import 'adapters/storage/file_recent_reading_repository.dart';
import 'adapters/storage/file_review_cache_repository.dart';
import 'adapters/storage/file_preferences_repository.dart';
import 'adapters/storage/file_draft_repository.dart';
import 'dart:io';
import 'adapters/engine/bundled_engine.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'adapters/storage/file_game_repository.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChessNextApp(
      showFirstRunGuide: true,
      filePicker: FileSelectorRecordPicker(),
      fileExporter: Platform.isMacOS ? MacOsRecordFileExporter() : null,
      recentReadingRepository: FileRecentReadingRepository(
        getApplicationSupportDirectory,
      ),
      repository: FileGameRepository(getApplicationDocumentsDirectory),
      draftRepository: FileDraftRepository(getApplicationDocumentsDirectory),
      preferencesRepository: FilePreferencesRepository(
        getApplicationSupportDirectory,
      ),
      engineFactory: openBundledEngine,
      reviewCache: FileReviewCacheRepository(getApplicationSupportDirectory),
      deviceThreads: Platform.numberOfProcessors,
    ),
  );
}
