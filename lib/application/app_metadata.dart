/// App release metadata mirrored from `pubspec.yaml` until build metadata is
/// provided by a platform package adapter.
abstract final class AppMetadata {
  static const name = 'chessNext';
  static const version = '0.1.0';
  static const build = 1;
  static const displayVersion = '$version+$build';
}
