import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:xiangqi_core/xiangqi_core.dart';
import '../../application/board_image_snapshot.dart';
import '../../ports/png_file_exporter.dart';
import '../../ports/image_clipboard.dart';
import '../board/board_display_scope.dart';
import '../board/xiangqi_board.dart';

typedef BoardPngCapture = Future<PngImage> Function();

class BoardImageDialog extends StatefulWidget {
  const BoardImageDialog({
    super.key,
    required this.snapshot,
    this.exporter,
    this.clipboard,
    this.capture,
  });
  final BoardImageSnapshot snapshot;
  final PngFileExporter? exporter;
  final ImageClipboard? clipboard;

  /// A test seam for render cancellation; production always captures this board.
  final BoardPngCapture? capture;
  @override
  State<BoardImageDialog> createState() => _BoardImageDialogState();
}

class _BoardImageDialogState extends State<BoardImageDialog> {
  final boundary = GlobalKey();
  ThemeData? boardTheme;
  bool busy = false, copying = false, dismissed = false;
  PngImage? cached;
  String? status;
  FileExportCancellation? cancellation;
  ImageCopyCancellation? copyCancellation;
  bool get active =>
      mounted && !dismissed && ModalRoute.of(context)?.isCurrent == true;
  void dismiss() {
    dismissed = true;
    cancellation?.cancel();
    copyCancellation?.cancel();
  }

  @override
  void dispose() {
    dismiss();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boardTheme ??= Theme.of(context);
  }

  Future<PngImage> capture() async {
    await WidgetsBinding.instance.endOfFrame;
    final render = boundary.currentContext?.findRenderObject();
    if (render is! RenderRepaintBoundary) {
      throw const PngExportException(PngExportFailure.render);
    }
    final image = await render.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw const PngExportException(PngExportFailure.render);
      }
      return PngImage.fromBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    } finally {
      image.dispose();
    }
  }

  Future<void> save() async {
    if (busy || widget.exporter == null) return;
    final token = FileExportCancellation();
    cancellation = token;
    setState(() {
      busy = true;
      status = null;
    });
    try {
      cached ??= await (widget.capture ?? capture)();
      if (!active || token.isCancelled) return;
      final result = await widget.exporter!.savePng(
        cached!,
        cancellation: token,
      );
      if (active) {
        setState(
          () => status = result == RecordFileExportResult.saved
              ? '图片文件已保存'
              : '已取消图片保存',
        );
      }
    } on PngExportException catch (e) {
      if (active) setState(() => status = e.message);
    } catch (_) {
      if (active) setState(() => status = '棋盘图片生成或保存失败，请重试。');
    } finally {
      if (mounted && !dismissed) setState(() => busy = false);
    }
  }

  Future<void> copy() async {
    if (busy || widget.clipboard == null) return;
    final token = ImageCopyCancellation();
    copyCancellation = token;
    setState(() {
      busy = true;
      copying = true;
      status = null;
    });
    try {
      cached ??= await (widget.capture ?? capture)();
      if (!active || token.isCancelled) return;
      final result = await widget.clipboard!.copyPng(
        cached!,
        cancellation: token,
      );
      if (active) {
        setState(
          () =>
              status = result == ImageCopyResult.copied ? '棋盘图片已复制' : '已取消图片复制',
        );
      }
    } on PngExportException catch (e) {
      if (active) setState(() => status = e.message);
    } on ImageCopyException catch (e) {
      if (active) setState(() => status = e.message);
    } catch (_) {
      if (active) setState(() => status = '棋盘图片生成或复制失败，请重试。');
    } finally {
      if (mounted && !dismissed) {
        setState(() {
          busy = false;
          copying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) dismiss();
      },
      child: AlertDialog(
        scrollable: true,
        title: const Text('导出棋盘图片'),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('打开时的当前棋盘快照 · PNG 900×1000。后来的读谱或分析不会改变本图。'),
              const SizedBox(height: 12),
              Semantics(
                container: true,
                label: 'PNG局面快照',
                value:
                    '${s.position.turn == Side.red ? '红方' : '黑方'}行棋，${s.flipped ? '黑方在下' : '红方在下'}，${s.mirrored ? '左右镜像' : '正常左右'}',
                child: ExcludeSemantics(
                  child: ExcludeFocus(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RepaintBoundary(
                        key: boundary,
                        child: SizedBox(
                          width: 450,
                          height: 500,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaler: TextScaler.noScaling,
                              disableAnimations: true,
                            ),
                            child: Theme(
                              data: boardTheme!,
                              child: BoardDisplayScope(
                                showCoordinates: s.showCoordinates,
                                rotateOppositePieces: s.rotateOppositePieces,
                                boardSkin: s.boardSkin,
                                selectedBoardSkinId: s.selectedBoardSkinId,
                                nightBoardInDarkMode: s.nightBoardInDarkMode,
                                geometry: s.geometry,
                                boardSkinImages: s.boardSkinImages,
                                pieceSkin: s.pieceSkin,
                                pieceSkinShadow: s.pieceSkinShadow,
                                pieceImages: s.pieceImages,
                                pieceSizePercent: s.pieceSizePercent,
                                pieceSkinSizePercent: s.pieceSkinSizePercent,
                                pieceSkinOffsetXPercent:
                                    s.pieceSkinOffsetXPercent,
                                pieceSkinOffsetYPercent:
                                    s.pieceSkinOffsetYPercent,
                                arrowHead: s.arrowHead,
                                lastMoveMarker: s.lastMoveStyle,
                                child: BoardSurface(
                                  at: s.position.at,
                                  onTap: (_) {},
                                  enabled: false,
                                  flipped: s.flipped,
                                  mirrored: s.mirrored,
                                  lastMove: s.lastMove,
                                  recommendation: s.recommendation,
                                  reply: s.reply,
                                  variations: s.variations,
                                  assessment: s.assessment,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('仅棋盘及已显示的分析标记；不含侧栏、局势条或当前选子提示。保存不改变棋谱。'),
              if (widget.exporter == null) const Text('当前设备暂不支持图片文件保存。'),
              if (widget.clipboard == null) const Text('当前设备暂不支持图片复制。'),
              if (busy) const LinearProgressIndicator(),
              if (status != null)
                Text(status!, key: const ValueKey('png-export-status')),
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
            onPressed: busy || widget.clipboard == null
                ? null
                : () => unawaited(copy()),
            child: Text(busy && copying ? '正在复制…' : '复制图片'),
          ),
          FilledButton(
            onPressed: busy || widget.exporter == null
                ? null
                : () => unawaited(save()),
            child: Text(busy && !copying ? '正在保存…' : '保存图片'),
          ),
        ],
      ),
    );
  }
}
