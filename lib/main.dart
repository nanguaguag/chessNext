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
      repository: FileGameRepository(getApplicationDocumentsDirectory),
      engineFactory: openBundledEngine,
      deviceThreads: Platform.numberOfProcessors,
    ),
  );
}
