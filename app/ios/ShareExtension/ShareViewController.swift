// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다른 앱에서 부루미로 보내기 (Telegram tips 350 + 182), iPhone side.
// The share sheet's "부루미" runs this small extension. It only copies the
// shared photos, videos, files and words into the app group folder that
// Burumy and this extension both own, then opens Burumy, which asks where
// to send them. The extension has no keys and talks to no server: all
// encryption and sending happen inside the app.
// Setup (Mac, Xcode): see README.md in this folder.
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  static let group = "group.app.burumy.burumy"
  private static let maxFiles = 20

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    Task { await collect() }
  }

  private func collect() async {
    guard let box = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.group) else { return finish() }
    let dir = box.appendingPathComponent("share_in", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    var list: [[String: String]] = []
    let providers = (extensionContext?.inputItems as? [NSExtensionItem] ?? []).flatMap { $0.attachments ?? [] }
    for (i, p) in providers.prefix(Self.maxFiles).enumerated() {
      if let row = await copy(p, index: i, into: dir) { list.append(row) }
    }
    // Waiting list: the app reads it, sends nothing by itself, then clears it.
    let note = dir.appendingPathComponent("waiting.json")
    var old = (try? JSONSerialization.jsonObject(with: Data(contentsOf: note))) as? [[String: String]] ?? []
    old.append(contentsOf: list)
    if let data = try? JSONSerialization.data(withJSONObject: old) { try? data.write(to: note, options: .atomic) }
    openApp()
    finish()
  }

  private func copy(_ p: NSItemProvider, index: Int, into dir: URL) async -> [String: String]? {
    // Words and links first (a web page shared from Safari).
    if p.hasItemConformingToTypeIdentifier(UTType.url.identifier), !p.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
      if let u = try? await p.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
        return ["text": u.absoluteString, "name": "text", "mime": "text/plain"]
      }
    }
    if p.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
      if let s = try? await p.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
        return ["text": String(s.prefix(4096)), "name": "text", "mime": "text/plain"]
      }
    }
    for type in [UTType.image, UTType.movie, UTType.data] where p.hasItemConformingToTypeIdentifier(type.identifier) {
      let got: URL? = await withCheckedContinuation { done in
        _ = p.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, _ in
          // The phone removes its copy when this returns: keep ours now.
          guard let url else { return done.resume(returning: nil) }
          let name = url.lastPathComponent.replacingOccurrences(of: "/", with: "_")
          let out = dir.appendingPathComponent("\(Int(Date().timeIntervalSince1970 * 1000))_\(index)_\(name)")
          do {
            try FileManager.default.copyItem(at: url, to: out)
            done.resume(returning: out)
          } catch {
            done.resume(returning: nil)
          }
        }
      }
      if let out = got {
        let mime = UTType(filenameExtension: out.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        return ["path": out.path, "name": String(out.lastPathComponent.split(separator: "_", maxSplits: 2).last ?? "file"), "mime": mime]
      }
    }
    return nil
  }

  /// Opens Burumy (the app picks up the waiting list when it comes to the
  /// front). If iOS doesn't allow it, the list waits for the next opening.
  private func openApp() {
    guard let url = URL(string: "burumy://share") else { return }
    var r: UIResponder? = self
    while let cur = r {
      if let app = cur as? UIApplication {
        app.open(url)
        return
      }
      r = cur.next
    }
  }

  private func finish() {
    DispatchQueue.main.async { self.extensionContext?.completeRequest(returningItems: nil) }
  }
}
