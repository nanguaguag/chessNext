import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../application/board_gif_encoder.dart';
import '../../application/board_gif_snapshot.dart';
import '../../ports/gif_file_exporter.dart';
import '../board/board_display_scope.dart';
import '../board/xiangqi_board.dart';

typedef BoardGifFrameCapture = Future<Uint8List> Function(int frameIndex);

class BoardGifDialog extends StatefulWidget {
  const BoardGifDialog({
    super.key,
    required this.snapshot,
    required this.initialSettings,
    required this.onSettingsChanged,
    this.exporter,
    this.captureFrame,
    this.encoder = encodeBoardGif,
  });
  final BoardGifSnapshot snapshot;
  final BoardGifSettings initialSettings;
  final ValueChanged<BoardGifSettings> onSettingsChanged;
  final GifFileExporter? exporter;
  final BoardGifFrameCapture? captureFrame;
  final BoardGifEncoder encoder;

  @override
  State<BoardGifDialog> createState() => _BoardGifDialogState();
}

class _BoardGifDialogState extends State<BoardGifDialog> {
  final boundary = GlobalKey();
  late final TextEditingController title;
  late BoardGifSettings settings;
  ThemeData? boardTheme;
  int frameIndex = 0;
  bool busy = false, saving = false, dismissed = false;
  GifImage? gif;
  String? status;
  FileExportCancellation? cancellation;

  bool get active =>
      mounted && !dismissed && ModalRoute.of(context)?.isCurrent == true;

  @override
  void initState() {
    super.initState();
    settings = widget.initialSettings;
    title = TextEditingController(text: settings.title);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boardTheme ??= Theme.of(context);
  }

  void dismiss() {
    dismissed = true;
    cancellation?.cancel();
  }

  @override
  void dispose() {
    dismiss();
    title.dispose();
    super.dispose();
  }

  void update(BoardGifSettings next) {
    settings = next;
    gif = null;
    status = null;
    widget.onSettingsChanged(next);
    setState(() {});
  }

  Future<Uint8List> captureCurrent(int _) async {
    await WidgetsBinding.instance.endOfFrame;
    final render = boundary.currentContext?.findRenderObject();
    if (render is! RenderRepaintBoundary) {
      throw const GifExportException(GifExportFailure.render);
    }
    final image = await render.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw const GifExportException(GifExportFailure.render);
      }
      return Uint8List.fromList(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  }

  Future<void> generate() async {
    if (busy) return;
    setState(() {
      busy = true;
      saving = false;
      status = null;
      gif = null;
    });
    try {
      final frames = <Uint8List>[];
      for (var i = 0; i < widget.snapshot.frames.length; i++) {
        if (!active) return;
        setState(() => frameIndex = i);
        await WidgetsBinding.instance.endOfFrame;
        frames.add(await (widget.captureFrame ?? captureCurrent)(i));
      }
      if (!active) return;
      final result = await widget.encoder(
        frames,
        settings.durationsCentiseconds(frames.length),
      );
      if (active) {
        setState(() {
          gif = result;
          status = 'GIF预览已生成，可保存到本机。';
        });
      }
    } on GifExportException catch (error) {
      if (active) setState(() => status = error.message);
    } catch (_) {
      if (active) setState(() => status = '动态图生成失败，请重试。');
    } finally {
      if (mounted && !dismissed) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy || gif == null || widget.exporter == null) return;
    final token = FileExportCancellation();
    cancellation = token;
    setState(() {
      busy = true;
      saving = true;
      status = null;
    });
    try {
      final result = await widget.exporter!.saveGif(gif!, cancellation: token);
      if (active) {
        setState(
          () => status = result == RecordFileExportResult.saved
              ? 'GIF文件已保存'
              : '已取消GIF保存',
        );
      }
    } on GifExportException catch (error) {
      if (active) setState(() => status = error.message);
    } catch (_) {
      if (active) setState(() => status = 'GIF保存失败，请重试。');
    } finally {
      if (mounted && !dismissed) {
        setState(() {
          busy = false;
          saving = false;
        });
      }
    }
  }

  Widget secondsSlider({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) => Semantics(
    label: label,
    value: '${(value / 10).toStringAsFixed(1)}秒',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label ${(value / 10).toStringAsFixed(1)} 秒'),
        Slider(
          value: value.toDouble(),
          min: 2,
          max: max.toDouble(),
          divisions: max - 2,
          label: (value / 10).toStringAsFixed(1),
          onChanged: busy ? null : (next) => onChanged(next.round()),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final frame = snapshot.frames[frameIndex];
    final board = RepaintBoundary(
      key: boundary,
      child: SizedBox(
        width: 450,
        height: 540,
        child: MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling, disableAnimations: true),
          child: Theme(
            data: boardTheme!,
            child: Column(
              children: [
                SizedBox(
                  width: 450,
                  height: 500,
                  child: BoardDisplayScope(
                    showCoordinates: snapshot.showCoordinates,
                    rotateOppositePieces: snapshot.rotateOppositePieces,
                    pieceSizePercent: snapshot.pieceSizePercent,
                    arrowHead: snapshot.arrowHead,
                    lastMoveMarker: snapshot.lastMoveStyle,
                    child: BoardSurface(
                      at: frame.position.at,
                      onTap: (_) {},
                      enabled: false,
                      flipped: snapshot.flipped,
                      mirrored: snapshot.mirrored,
                      lastMove: frame.move,
                      recommendation: frame.move,
                    ),
                  ),
                ),
                ColoredBox(
                  color: boardTheme!.colorScheme.surfaceContainer,
                  child: SizedBox(
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              settings.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '第 ${frameIndex + 1} 帧 / 共 ${snapshot.frames.length} 帧',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) dismiss();
      },
      child: AlertDialog(
        scrollable: true,
        title: const Text('生成棋谱动态图'),
        content: SizedBox(
          width: 500,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('打开时的所选完整线路 · ${snapshot.frames.length} 帧（含根局面）。旁支不进入GIF。'),
              TextField(
                controller: title,
                enabled: !busy,
                maxLength: BoardGifSettings.maxTitleLength,
                decoration: const InputDecoration(labelText: '标题（可留空）'),
                onChanged: (value) => update(settings.copyWith(title: value)),
              ),
              secondsSlider(
                label: '步时',
                value: settings.stepTenths,
                max: 100,
                onChanged: (value) =>
                    update(settings.copyWith(stepTenths: value)),
              ),
              secondsSlider(
                label: '开局停留',
                value: settings.openingTenths,
                max: 300,
                onChanged: (value) =>
                    update(settings.copyWith(openingTenths: value)),
              ),
              secondsSlider(
                label: '终局停留',
                value: settings.endingTenths,
                max: 300,
                onChanged: (value) =>
                    update(settings.copyWith(endingTenths: value)),
              ),
              const Text('首尾停留替代相应帧的步时。最多64帧、12MB；超限会拒绝，不会截断线路。'),
              const SizedBox(height: 12),
              Semantics(
                container: true,
                label: gif == null ? 'GIF画面预览' : '已生成GIF动画预览',
                child: ExcludeSemantics(
                  child: ExcludeFocus(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: gif == null
                          ? board
                          : Image.memory(
                              gif!.bytes,
                              width: gif!.width.toDouble(),
                              height: gif!.height.toDouble(),
                              gaplessPlayback: true,
                            ),
                    ),
                  ),
                ),
              ),
              if (widget.exporter == null) const Text('当前设备暂不支持GIF文件保存。'),
              if (busy) const LinearProgressIndicator(),
              if (status != null)
                Text(status!, key: const ValueKey('gif-export-status')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              dismiss();
              Navigator.pop(context);
            },
            child: const Text('关闭'),
          ),
          OutlinedButton(
            onPressed: busy ? null : () => unawaited(generate()),
            child: Text(busy && !saving ? '正在生成…' : '生成预览'),
          ),
          FilledButton(
            onPressed: busy || gif == null || widget.exporter == null
                ? null
                : () => unawaited(save()),
            child: Text(busy && saving ? '正在保存…' : '保存GIF'),
          ),
        ],
      ),
    );
  }
}
