import 'package:flutter/material.dart';

import '../../application/board_skin_geometry.dart';
import '../../ports/board_skin_library.dart';
import 'board_geometry_editor.dart';

final class BoardSkinGeometryDraftDialog extends StatefulWidget {
  const BoardSkinGeometryDraftDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  final BoardSkinDefinition profile;
  final Future<bool> Function(BoardSkinGeometry geometry) onSave;

  @override
  State<BoardSkinGeometryDraftDialog> createState() =>
      _BoardSkinGeometryDraftDialogState();
}

final class _BoardSkinGeometryDraftDialogState
    extends State<BoardSkinGeometryDraftDialog> {
  late BoardSkinGeometry _draft = widget.profile.geometry;
  bool _saving = false;
  String? _error;

  void _update(BoardSkinGeometry Function(BoardSkinGeometry) change) {
    setState(() => _draft = change(_draft));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await widget.onSave(_draft);
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = '棋盘皮肤未能保存在本机，请重试。';
      });
    }
  }

  Widget _edge(
    String label,
    double value,
    double min,
    double max,
    BoardSkinGeometry Function(double) change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label ${value.toStringAsFixed(1)}%'),
      Slider(
        key: ValueKey('board-skin-draft-edge-$label'),
        value: value,
        min: min,
        max: max,
        divisions: ((max - min) * 2).round().clamp(1, 196),
        label: '${value.toStringAsFixed(1)}%',
        semanticFormatterCallback: (v) => '${v.toStringAsFixed(1)}%',
        onChanged: _saving
            ? null
            : (next) => _update((current) => change(next)),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('编辑${widget.profile.name}'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BoardGeometryEditor(
              geometry: _draft,
              enabled: !_saving,
              onChanged: (next) => setState(() => _draft = next),
            ),
            const SizedBox(height: 16),
            const Text('格点与边距'),
            _edge(
              '左边距',
              _draft.leftPercent,
              BoardSkinGeometry.minEdgePercent,
              _draft.rightPercent - BoardSkinGeometry.minSpanPercent,
              (value) => _draft.copyWith(leftPercent: value),
            ),
            _edge(
              '右边距',
              _draft.rightPercent,
              _draft.leftPercent + BoardSkinGeometry.minSpanPercent,
              BoardSkinGeometry.maxEdgePercent,
              (value) => _draft.copyWith(rightPercent: value),
            ),
            _edge(
              '上边距',
              _draft.topPercent,
              BoardSkinGeometry.minEdgePercent,
              _draft.bottomPercent - BoardSkinGeometry.minSpanPercent,
              (value) => _draft.copyWith(topPercent: value),
            ),
            _edge(
              '下边距',
              _draft.bottomPercent,
              _draft.topPercent + BoardSkinGeometry.minSpanPercent,
              BoardSkinGeometry.maxEdgePercent,
              (value) => _draft.copyWith(bottomPercent: value),
            ),
            Text('棋子缩放 ${_draft.pieceScalePercent}%'),
            Slider(
              key: const ValueKey('board-skin-draft-piece-scale'),
              value: _draft.pieceScalePercent.toDouble(),
              min: BoardSkinGeometry.minPieceScalePercent.toDouble(),
              max: BoardSkinGeometry.maxPieceScalePercent.toDouble(),
              divisions:
                  BoardSkinGeometry.maxPieceScalePercent -
                  BoardSkinGeometry.minPieceScalePercent,
              label: '${_draft.pieceScalePercent}%',
              semanticFormatterCallback: (value) => '${value.round()}%',
              onChanged: _saving
                  ? null
                  : (value) => _update(
                      (current) =>
                          current.copyWith(pieceScalePercent: value.round()),
                    ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('落点标记旋转'),
              value: _draft.rotateLandingMarker,
              onChanged: _saving
                  ? null
                  : (value) => _update(
                      (current) => current.copyWith(rotateLandingMarker: value),
                    ),
            ),
            TextButton.icon(
              onPressed: _saving
                  ? null
                  : () => setState(
                      () => _draft = const BoardSkinGeometry.standard(),
                    ),
              icon: const Icon(Icons.restart_alt),
              label: const Text('恢复默认几何'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('保存'),
      ),
    ],
  );
}
