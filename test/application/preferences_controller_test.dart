import 'dart:async';
import 'package:chess_next/application/app_preferences.dart';
import 'package:chess_next/application/board_session.dart';
import 'package:chess_next/application/engine_session_controller.dart';
import 'package:chess_next/application/preferences_controller.dart';
import 'package:chess_next/ports/preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/fake_engine.dart';

class ControlledPreferences extends MemoryPreferencesRepository {
  Completer<void>? readGate, writeGate;
  bool failRead = false, failWrite = false;
  final writes = <AppPreferences>[];
  @override
  Future<LoadedPreferences?> load() async {
    await readGate?.future;
    if (failRead) throw StateError('broken');
    return super.load();
  }

  @override
  Future<void> save(AppPreferences next) async {
    writes.add(next);
    if (writes.length == 1) await writeGate?.future;
    if (failWrite) throw StateError('full');
    await super.save(next);
  }
}

void main() {
  late BoardSession session;
  late FakeEngine fake;
  late EngineSessionController engine;
  late ControlledPreferences repository;
  late PreferencesController preferences;
  setUp(() {
    session = BoardSession();
    fake = FakeEngine();
    engine = EngineSessionController(
      session,
      () async => fake,
      deviceThreads: 4,
    );
    repository = ControlledPreferences();
    preferences = PreferencesController(engine, repository);
  });
  tearDown(() {
    preferences.dispose();
    engine.dispose();
    session.dispose();
  });
  test(
    'codec rejects future schemas and invalid numbers instead of silently accepting them',
    () {
      final value = AppPreferences(
        theme: ThemePreference.dark,
        displayTone: DisplayTone.maple,
        boardLayoutPreset: BoardLayoutPreset.boardOnLeft,
        threads: 4,
        hashMb: 128,
        multiPv: 5,
        thinkTimeMs: 3000,
        aiWalkDifficulty: 7,
        aiWalkTimeMs: 0,
        aiWalkMaxDepth: 42,
        openingBookMode: OpeningBookMode.randomWithinGap,
        endgameBookEnabled: false,
        leaveBookMoves: 24,
        bookServiceBaseUrl: 'https://books.example.org/api',
        bookLookupSource: BookLookupSource.masterGames,
        releaseServiceBaseUrl: 'https://updates.example.org/api',
      );
      expect(AppPreferences.fromJson(value.toJson()), value);
      final legacyTone = AppPreferences().toJson()
        ..remove('displayTone')
        ..remove('nightBoardInDarkMode');
      expect(
        AppPreferences.fromJson(legacyTone).displayTone,
        DisplayTone.skyBlue,
      );
      expect(AppPreferences.fromJson(legacyTone).nightBoardInDarkMode, isTrue);
      expect(
        AppPreferences().copyWith(
          releaseServiceBaseUrl: 'https://updates.example.org/api',
        ),
        AppPreferences.fromJson({
          ...AppPreferences().toJson(),
          'releaseServiceBaseUrl': 'https://updates.example.org/api',
        }),
      );
      final catalog = AppPreferences().copyWith(
        skinCatalogBaseUrl: 'https://skins.example.org/catalog',
      );
      expect(AppPreferences.fromJson(catalog.toJson()), catalog);
      expect(
        () => AppPreferences(skinCatalogBaseUrl: 'http://example.org'),
        throwsArgumentError,
      );
      expect(
        () => AppPreferences(bookServiceBaseUrl: 'http://example.org'),
        throwsArgumentError,
      );
      expect(
        () => AppPreferences(bookServiceBaseUrl: 'http://localhost:8080'),
        returnsNormally,
      );
      expect(
        () => AppPreferences(skinCatalogBaseUrl: 'http://localhost:8080'),
        returnsNormally,
      );
      expect(
        AppPreferences(recordPlaybackIntervalMs: 100).recordPlaybackIntervalMs,
        100,
      );
      expect(
        AppPreferences(
          recordPlaybackIntervalMs: 60000,
        ).recordPlaybackIntervalMs,
        60000,
      );
      expect(
        AppPreferences(recordPlaybackIntervalMs: 700).recordPlaybackIntervalMs,
        700,
        reason: 'legacy 100ms-step values remain readable',
      );
      expect(
        () => AppPreferences(recordPlaybackIntervalMs: 750),
        throwsArgumentError,
      );
      final legacy = AppPreferences().toJson()..remove('boardLayoutPreset');
      expect(
        AppPreferences.fromJson(legacy).boardLayoutPreset,
        BoardLayoutPreset.centered,
      );
      final explicitLegacy = AppPreferences(hashMb: 96).toJson()
        ..remove('autoHash');
      expect(AppPreferences.fromJson(explicitLegacy).autoHash, isFalse);
      expect(AppPreferences.fromJson(explicitLegacy).hashMb, 96);
      expect(AppPreferences.fromJson(explicitLegacy).aiWalkDifficulty, 20);
      expect(AppPreferences.fromJson(explicitLegacy).aiWalkTimeMs, 1000);
      expect(AppPreferences.fromJson(explicitLegacy).aiWalkMaxDepth, 60);
      for (final entry in {
        'schema': 2,
        'theme': 'unknown',
        'displayTone': 'unknown',
        'nightBoardInDarkMode': 'yes',
        'boardLayoutPreset': 'unknown',
        'threads': 0,
        'multiPv': 257,
        'thinkTimeMs': 49,
        'aiWalkDifficulty': 21,
        'aiWalkTimeMs': 750,
        'aiWalkMaxDepth': 0,
        'hashMb': 1.5,
        'recordPlaybackIntervalMs': 499,
        'showMoveList': 1,
        'showPanelSwitchBar': 'yes',
        'activeSidePanel': 'unknown',
        'boardContextActions': ['copyFen', 'unknown'],
        'sidePanelOrder': ['analysis', 'analysis', 'review', 'candidates'],
      }.entries) {
        expect(
          () => AppPreferences.fromJson({
            ...value.toJson(),
            entry.key: entry.value,
          }),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'automatic hash follows threads and remains within engine limits',
    () async {
      await preferences.initialize();
      await preferences.apply(
        AppPreferences().copyWith(threads: 2, autoHash: true),
      );
      expect(preferences.value.hashMb, 128);
      expect(engine.settings.hashMb, 128);
      expect(repository.value!.autoHash, isTrue);

      await preferences.apply(
        preferences.value.copyWith(autoHash: false, hashMb: 80),
      );
      expect(preferences.value.hashMb, 80);
      expect(engine.settings.hashMb, 80);
    },
  );
  test(
    'side panel order persists and invalid or incomplete orders are rejected',
    () async {
      final changed = AppPreferences().copyWith(
        sidePanelOrder: const [
          SidePanel.candidates,
          SidePanel.play,
          SidePanel.analysis,
          SidePanel.review,
        ],
      );
      expect(AppPreferences.fromJson(changed.toJson()), changed);
      final hidden = AppPreferences().copyWith(
        visibleSidePanels: const [SidePanel.play, SidePanel.review],
      );
      expect(AppPreferences.fromJson(hidden.toJson()), hidden);
      final boardOnLeft = AppPreferences().copyWith(
        boardLayoutPreset: BoardLayoutPreset.boardOnLeft,
      );
      expect(AppPreferences.fromJson(boardOnLeft.toJson()), boardOnLeft);
      expect(
        () => AppPreferences(
          visibleSidePanels: const [SidePanel.play, SidePanel.play],
        ),
        throwsArgumentError,
      );
      for (final invalid in [
        ['analysis'],
        ['analysis', 'analysis', 'review', 'candidates'],
        ['analysis', 'play', 'review', 'unknown'],
        ['visibleSidePanels', 'play', 'play'],
      ]) {
        expect(
          () => AppPreferences.fromJson({
            ...AppPreferences().toJson(),
            if (invalid.first == 'visibleSidePanels')
              'visibleSidePanels': invalid.skip(1).toList()
            else
              'sidePanelOrder': invalid,
          }),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'late reads merge only unedited fields and preserve newly chosen theme and time',
    () async {
      repository.value = AppPreferences(
        theme: ThemePreference.dark,
        displayTone: DisplayTone.ink,
        threads: 2,
        hashMb: 128,
        multiPv: 3,
      );
      repository.readGate = Completer<void>();
      final reading = preferences.initialize();
      final choosing = preferences.setTheme(ThemePreference.light);
      final choosingTone = preferences.setDisplayTone(DisplayTone.maple);
      final choosingNightBoard = preferences.setNightBoardInDarkMode(false);
      final choosingCatalog = preferences.setSkinCatalogBaseUrl(
        'https://skins.example.org',
      );
      final choosingLayout = preferences.setBoardLayoutPreset(
        BoardLayoutPreset.boardOnLeft,
      );
      final choosingPanels = preferences.setSidePanelOrder(const [
        SidePanel.candidates,
        SidePanel.play,
        SidePanel.analysis,
        SidePanel.review,
      ]);
      final choosingPlayback = preferences.setRecordPlaybackInterval(500);
      final hidingMoveList = preferences.setShowMoveList(false);
      final hidingPlaybackButton = preferences.setShowRecordPlaybackButton(
        false,
      );
      final enablingPanelBar = preferences.setShowPanelSwitchBar(true);
      final choosingPanel = preferences.setActiveSidePanel(SidePanel.review);
      final choosingBookSource = preferences.setBookLookupSource(
        BookLookupSource.masterGames,
      );
      final choosingContextActions = preferences.setBoardContextActions(const [
        BoardContextAction.copyFen,
        BoardContextAction.saveRecord,
      ]);
      final hidingReview = preferences.setSidePanelVisibility(
        SidePanel.review,
        false,
      );
      await engine.setThinkTime(3000);
      var finished = false;
      final exiting = preferences.flush().then((_) => finished = true);
      await Future<void>.delayed(Duration.zero);
      expect(finished, isFalse);
      repository.readGate!.complete();
      await reading;
      await choosing;
      await choosingTone;
      await choosingNightBoard;
      await choosingCatalog;
      await choosingLayout;
      await choosingPanels;
      await choosingPlayback;
      await hidingMoveList;
      await hidingPlaybackButton;
      await enablingPanelBar;
      await choosingPanel;
      await choosingBookSource;
      await choosingContextActions;
      await hidingReview;
      await exiting;
      await preferences.flush();
      expect(preferences.value.theme, ThemePreference.light);
      expect(preferences.value.displayTone, DisplayTone.maple);
      expect(preferences.value.nightBoardInDarkMode, isFalse);
      expect(preferences.value.skinCatalogBaseUrl, 'https://skins.example.org');
      expect(
        preferences.value.boardLayoutPreset,
        BoardLayoutPreset.boardOnLeft,
      );
      expect(preferences.value.sidePanelOrder.first, SidePanel.candidates);
      expect(preferences.value.recordPlaybackIntervalMs, 500);
      expect(preferences.value.showMoveList, isFalse);
      expect(preferences.value.showRecordPlaybackButton, isFalse);
      expect(preferences.value.showPanelSwitchBar, isTrue);
      expect(preferences.value.activeSidePanel, SidePanel.review);
      expect(preferences.value.bookLookupSource, BookLookupSource.masterGames);
      expect(preferences.value.boardContextActions, const [
        BoardContextAction.copyFen,
        BoardContextAction.saveRecord,
      ]);
      expect(
        preferences.value.visibleSidePanels,
        isNot(contains(SidePanel.review)),
      );
      expect(preferences.value.thinkTimeMs, 3000);
      expect(preferences.value.hashMb, 128);
      expect(engine.settings.multiPv, 3);
      expect(repository.value, preferences.value);
      expect(engine.aiSides, isEmpty);
      expect(fake.requests, isEmpty);
    },
  );
  test(
    'hardware and engine capability limits clamp persisted resources before searching',
    () async {
      repository.value = AppPreferences(threads: 999, multiPv: 8, hashMb: 512);
      await preferences.initialize();
      await preferences.flush();
      expect(engine.settings.threads, 4);
      expect(engine.settings.multiPv, 8);
      await engine.enable();
      await preferences.flush();
      expect(engine.settings.multiPv, 5);
      expect(fake.requests.single.multiPv, 5);
      expect(repository.value!.multiPv, 5);
      final requests = fake.requests.length;
      await preferences.setTheme(ThemePreference.dark);
      expect(
        fake.requests.length,
        requests,
        reason: 'changing only theme must not restart a search',
      );
    },
  );
  test(
    'serial writes preserve the latest theme and existing-panel parameter changes',
    () async {
      await preferences.initialize();
      repository.writeGate = Completer<void>();
      final first = preferences.setTheme(ThemePreference.dark);
      await engine.configure(
        const AnalysisSettings(threads: 2, hashMb: 64, multiPv: 3),
      );
      final last = preferences.setTheme(ThemePreference.light);
      repository.writeGate!.complete();
      await first;
      await last;
      expect(repository.writes.first.theme, ThemePreference.dark);
      expect(repository.value!.theme, ThemePreference.light);
      expect(repository.value!.hashMb, 64);
      expect(repository.value!.multiPv, 3);
    },
  );
  test(
    'failed reads stay untouched until a user applies settings; failed writes can retry',
    () async {
      repository.failRead = true;
      await preferences.initialize();
      await preferences.flush();
      expect(repository.writes, isEmpty);
      expect(preferences.error, contains('读取失败'));
      repository.failWrite = true;
      await preferences.setTheme(ThemePreference.dark);
      expect(preferences.value.theme, ThemePreference.dark);
      expect(preferences.error, contains('保存失败'));
      repository.failWrite = false;
      await preferences.flush(force: true);
      expect(preferences.error, isNull);
      expect(repository.value!.theme, ThemePreference.dark);
    },
  );
}
