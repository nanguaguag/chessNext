import 'dart:typed_data';

enum PieceSkinPackageReadFailure { tooLarge, invalid, unavailable, read }

class PieceSkinPackageReadException implements Exception {
  const PieceSkinPackageReadException(this.failure);
  final PieceSkinPackageReadFailure failure;
}

abstract interface class PieceSkinPackagePicker {
  Future<Uint8List?> pickZip();
}
