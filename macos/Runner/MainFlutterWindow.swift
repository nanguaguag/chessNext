import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var recordFileWriter: RecordFileWriter?
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(NSRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: 1120, height: 850), display: true)
    self.minSize = NSSize(width: 520, height: 640)

    RegisterGeneratedPlugins(registry: flutterViewController)
    recordFileWriter = RecordFileWriter(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}
