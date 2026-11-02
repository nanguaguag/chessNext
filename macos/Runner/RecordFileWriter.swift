import Cocoa
import FlutterMacOS
import ImageIO

/// Private application bridge. File selection and user confirmation belong to
/// file_selector; this writer never chooses a destination or truncates in place.
final class RecordFileWriter {
  private let channel: FlutterMethodChannel
  private let queue = DispatchQueue(label: "dev.chessnext.record-file-writer", qos: .utility)

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "dev.chessnext/record-file-writer", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "writeAtomic" || call.method == "writePngAtomic" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let self = self,
            let args = call.arguments as? [String: Any],
            let path = args["path"] as? String,
            path.hasPrefix("/"), !path.contains("\0"), path.utf8.count <= 4096,
            let bytes = args["bytes"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "invalid_export", message: "Invalid export", details: nil))
        return
      }
      let isPng = call.method == "writePngAtomic"
      guard isPng
              ? Self.isBoundedPng(bytes.data)
              : bytes.data.count <= 256000 && String(data: bytes.data, encoding: .utf8) != nil else {
        result(FlutterError(
          code: "invalid_export",
          message: isPng ? "Invalid PNG export" : "Invalid text export",
          details: nil
        ))
        return
      }
      let url = URL(fileURLWithPath: path)
      let data = bytes.data
      self.queue.async {
        do {
          if isPng && !Self.isDecodablePng(data) {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
          }
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
            result(FlutterError(
              code: "write_failed",
              message: isPng ? "PNG export failed" : "Text export failed",
              details: nil
            ))
          }
        }
      }
    }
  }

  private static func isBoundedPng(_ data: Data) -> Bool {
    let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    guard data.count >= 33, data.count <= 8 * 1024 * 1024,
          Array(data.prefix(8)) == signature else { return false }
    return data[8] == 0 && data[9] == 0 && data[10] == 0 && data[11] == 13 &&
      data[12] == 73 && data[13] == 72 && data[14] == 68 && data[15] == 82
  }

  private static func isDecodablePng(_ data: Data) -> Bool {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          CGImageSourceGetCount(source) == 1,
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      return false
    }
    let width = image.width
    let height = image.height
    return width > 0 && height > 0 && width <= 4096 && height <= 4096 &&
      width * height <= 4_000_000
  }
}
