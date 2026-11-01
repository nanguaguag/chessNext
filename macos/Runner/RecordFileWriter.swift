import Cocoa
import FlutterMacOS

/// Private application bridge. File selection and user confirmation belong to
/// file_selector; this writer never chooses a destination or truncates in place.
final class RecordFileWriter {
  private let channel: FlutterMethodChannel
  private let queue = DispatchQueue(label: "dev.chessnext.record-file-writer", qos: .utility)

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "dev.chessnext/record-file-writer", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "writeAtomic" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self,
            let args = call.arguments as? [String: Any],
            let path = args["path"] as? String,
            path.hasPrefix("/"), !path.contains("\0"), path.utf8.count <= 4096,
            let bytes = args["bytes"] as? FlutterStandardTypedData,
            bytes.data.count <= 256000,
            String(data: bytes.data, encoding: .utf8) != nil else {
        result(FlutterError(code: "invalid_export", message: "Invalid text export", details: nil))
        return
      }
      let url = URL(fileURLWithPath: path)
      let data = bytes.data
      self.queue.async {
        do {
          let attributes = try? FileManager.default.attributesOfItem(atPath: path)
          if let kind = attributes?[.type] as? FileAttributeType,
             kind != .typeRegular {
            throw CocoaError(.fileWriteInvalidFileName)
          }
          try data.write(to: url, options: .atomic)
          DispatchQueue.main.async { result(nil) }
        } catch {
          // Do not pass NSError descriptions or user paths across the bridge.
          DispatchQueue.main.async {
            result(FlutterError(code: "write_failed", message: "Text export failed", details: nil))
          }
        }
      }
    }
  }
}
