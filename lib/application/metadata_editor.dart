import 'package:xiangqi_core/xiangqi_core.dart';
import 'board_session.dart';

/// Optimistic content snapshot. Reading navigation does not invalidate editing,
/// but another document or any content edit requires reopening the editor.
class MetadataEditor {
  MetadataEditor(this.session)
    : original = session.metadata,
      epoch = session.epoch,
      revision = session.revision;
  final BoardSession session;
  final GameMetadata original;
  final int epoch, revision;
  String? error;
  bool apply(Map<String, String?> edits) {
    if (session.epoch != epoch || session.revision != revision) {
      error = '棋谱内容已变化，请关闭资料窗口后重新打开。';
      return false;
    }
    try {
      session.updateMetadata(original.copyWith(edits));
      error = null;
      return true;
    } on ArgumentError catch (e) {
      error = e.message?.toString() ?? '资料无效，请检查后重试';
      return false;
    }
  }
}
