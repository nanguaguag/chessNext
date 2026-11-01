import 'package:chess_next/ports/record_file_picker.dart';

class MemoryRecordPicker implements RecordFilePicker {
  MemoryRecordPicker(this.choose);
  final Future<PickedRecordText?> Function() choose;
  int calls = 0;
  @override
  Future<PickedRecordText?> openText() {
    calls++;
    return choose();
  }
}
