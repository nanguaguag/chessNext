import 'adapters/platform/macos_record_file_exporter.dart';
import 'adapters/platform/macos_png_file_exporter.dart';
import 'adapters/platform/macos_image_clipboard.dart';
import 'adapters/platform/macos_gif_file_exporter.dart';
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
import 'adapters/audio/audioplayers_feedback.dart';
import 'adapters/speech/flutter_tts_move_speech.dart';
import 'adapters/platform/file_selector_audio_picker.dart';
import 'adapters/storage/file_audio_override_repository.dart';
import 'adapters/platform/file_selector_piece_image_picker.dart';
import 'adapters/storage/file_piece_image_repository.dart';
import 'adapters/storage/file_board_skin_image_repository.dart';
import 'adapters/storage/file_piece_skin_library_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final audioOverrides = FileAudioOverrideRepository(
    getApplicationSupportDirectory,
  );
  runApp(
    ChessNextApp(
      showFirstRunGuide: true,
      filePicker: FileSelectorRecordPicker(),
      fileExporter: Platform.isMacOS ? MacOsRecordFileExporter() : null,
      pngExporter: Platform.isMacOS ? MacOsPngFileExporter() : null,
      imageClipboard: Platform.isMacOS ? MacOsImageClipboard() : null,
      gifExporter: Platform.isMacOS ? MacOsGifFileExporter() : null,
      recentReadingRepository: FileRecentReadingRepository(
        getApplicationSupportDirectory,
      ),
      repository: FileGameRepository(getApplicationDocumentsDirectory),
      draftRepository: FileDraftRepository(getApplicationDocumentsDirectory),
      preferencesRepository: FilePreferencesRepository(
        getApplicationSupportDirectory,
      ),
      audioFeedback: AudioplayersFeedback(overrides: audioOverrides),
      moveSpeech: FlutterTtsMoveSpeech(),
      audioFilePicker: FileSelectorAudioPicker(),
      audioOverrides: audioOverrides,
      pieceImagePicker: FileSelectorPieceImagePicker(),
      pieceImageRepository: FilePieceImageRepository(
        getApplicationSupportDirectory,
      ),
      pieceSkinLibraryRepository: FilePieceSkinLibraryRepository(
        getApplicationSupportDirectory,
      ),
      boardSkinImagePicker: FileSelectorPieceImagePicker(),
      boardSkinImageRepository: FileBoardSkinImageRepository(
        getApplicationSupportDirectory,
      ),
      engineFactory: openBundledEngine,
      reviewCache: FileReviewCacheRepository(getApplicationSupportDirectory),
      deviceThreads: Platform.numberOfProcessors,
    ),
  );
}
