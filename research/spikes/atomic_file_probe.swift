// Project-owned probe. No Flutter UI and no user paths are touched.
import Foundation

let manager = FileManager.default
let folder = manager.temporaryDirectory.appendingPathComponent("chessnext-atomic-\(UUID().uuidString)")
try manager.createDirectory(at: folder, withIntermediateDirectories: false)
defer { try? manager.removeItem(at: folder) }
let target = folder.appendingPathComponent("self-created.pgn")
let old = Data("原内容".utf8)
let replacement = Data("新PGN内容".utf8)
try old.write(to: target, options: .atomic)
let first = try Data(contentsOf: target)
precondition(first == old)
try replacement.write(to: target, options: .atomic)
try verifyReplacement()
func verifyReplacement() throws {
  let actual = try Data(contentsOf: target)
  precondition(actual == replacement)
}
let child = target.appendingPathComponent("impossible.pgn")
do {
  try old.write(to: child, options: .atomic)
  fatalError("A file cannot be used as a parent directory")
} catch { /* expected */ }
try verifyReplacement()
do {
  try old.write(to: folder, options: .atomic)
  fatalError("A directory cannot be replaced as a text file")
} catch { /* expected */ }
try verifyReplacement()
print("PASS: new file, atomic replacement, failed child, failed directory; old target preserved")
