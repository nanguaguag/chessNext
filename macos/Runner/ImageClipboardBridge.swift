import Cocoa
import FlutterMacOS
import ImageIO

/// Private binary clipboard bridge. Production writes the general pasteboard;
/// integration tests may select an isolated named pasteboard to preserve user data.
final class ImageClipboardBridge {
  private let channel: FlutterMethodChannel
  private static let testName = NSPasteboard.Name("dev.chessnext.integration-tests")

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "dev.chessnext/image-clipboard", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "copyPng",
            let args = call.arguments as? [String: Any],
            let typed = args["bytes"] as? FlutterStandardTypedData,
            Self.validPng(typed.data) else {
        result(FlutterError(code: "invalid_image", message: "Invalid PNG image", details: nil))
        return
      }
      let data = typed.data
      let testing = args["testPasteboard"] as? Bool == true
      let pasteboard = testing ? NSPasteboard(name: Self.testName) : .general
      pasteboard.declareTypes([.png], owner: nil)
      guard pasteboard.setData(data, forType: .png),
            pasteboard.data(forType: .png) == data else {
        result(FlutterError(code: "clipboard_failed", message: "PNG clipboard write failed", details: nil))
        return
      }
      result(nil)
    }
  }

  private static func validPng(_ data: Data) -> Bool {
    let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    guard data.count >= 33, data.count <= 8 * 1024 * 1024,
          Array(data.prefix(8)) == signature,
          let source = CGImageSourceCreateWithData(data as CFData, nil),
          CGImageSourceGetCount(source) == 1,
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      return false
    }
    return image.width > 0 && image.height > 0 && image.width <= 4096 &&
      image.height <= 4096 && image.width * image.height <= 4_000_000
  }
}
