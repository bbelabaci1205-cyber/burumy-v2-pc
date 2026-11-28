// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import AVFoundation
import CoreLocation
import EventKit
import EventKitUI
import Flutter
import Photos
import SystemConfiguration
import UIKit
import Speech
import SwiftUI
import NaturalLanguage
#if canImport(Translation)
import Translation
#endif
import Vision
import VisionKit
import CoreImage
#if canImport(FoundationModels)
import FoundationModels
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var screen: FlutterMethodChannel?
  private var phone: PhoneChannel?
  private var ai: AiChannel?
  private var translate: TranslateChannel?
  private var shareIn: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // iPhone cannot block screenshots for apps, but it says when the screen
    // is being recorded or mirrored: the app then covers view-once content.
    let channel = FlutterMethodChannel(name: "app.burumy/screen", binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "BurumyScreen")!.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "secure": result(nil)
      // 557: screenshots come out blank while a protected chat is open.
      case "shield":
        ScreenShield.shared.set(call.arguments as? Bool ?? false)
        result(nil)
      case "captured": result(UIScreen.main.isCaptured)
      default: result(FlutterMethodNotImplemented)
      }
    }
    screen = channel
    phone = PhoneChannel(messenger: engineBridge.pluginRegistry.registrar(forPlugin: "BurumyPhone")!.messenger())
    ai = AiChannel(messenger: engineBridge.pluginRegistry.registrar(forPlugin: "BurumyAi")!.messenger())
    translate = TranslateChannel(messenger: engineBridge.pluginRegistry.registrar(forPlugin: "BurumyTranslate")!.messenger())
    // 다른 앱에서 부루미로 보내기 (tips 350 + 182): what the share extension
    // left in the app group folder (ios/ShareExtension). Read, then cleared;
    // the files stay until the app has sent them.
    let share = FlutterMethodChannel(name: "app.burumy/share", binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "BurumyShare")!.messenger())
    share.setMethodCallHandler { call, result in
      guard call.method == "take" else { return result(FlutterMethodNotImplemented) }
      guard let box = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.app.burumy.burumy") else { return result([]) }
      let note = box.appendingPathComponent("share_in/waiting.json")
      let list = (try? JSONSerialization.jsonObject(with: Data(contentsOf: note))) as? [[String: String]] ?? []
      try? FileManager.default.removeItem(at: note)
      result(list)
    }
    shareIn = share
    NotificationCenter.default.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
      self?.screen?.invokeMethod("capturedChanged", arguments: UIScreen.main.isCaptured)
    }
    // 캡처 알림: iPhone can't refuse a screenshot, it only says one was
    // taken. The app tells the chat when protected content was showing.
    NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: .main) { [weak self] _ in
      self?.screen?.invokeMethod("screenshot", arguments: nil)
    }
  }
}

/// 공유 비활성화 on iPhone: apps can't refuse screenshots, but the system
/// leaves the contents of a secure text field out of screenshots and
/// recordings. While on, the app window's layer sits inside such a field's
/// layer; turning it off only clears isSecureTextEntry (the window stays
/// where it is, so nothing flickers). Check on a real iPhone (Mac build).
final class ScreenShield {
  static let shared = ScreenShield()
  private var field: UITextField?

  func set(_ on: Bool) {
    if let f = field {
      f.isSecureTextEntry = on
      return
    }
    guard on, let window = UIApplication.shared.connectedScenes
      .compactMap({ ($0 as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow }) }).first
    else { return }
    let f = UITextField()
    f.isSecureTextEntry = true
    f.isUserInteractionEnabled = false
    window.addSubview(f)
    window.layer.superlayer?.addSublayer(f.layer)
    // iOS 17+: the secure canvas is the last sublayer (first before that).
    let canvas = (f.layer.sublayers?.last ?? f.layer.sublayers?.first) ?? f.layer
    canvas.addSublayer(window.layer)
    field = f
  }
}

/// Our own bridge to the phone's built-in features (no outside plugin):
/// where I am right now, and the newest photos and videos for the "+" sheet.
/// Nothing here talks to the internet; results go only to our app.
final class PhoneChannel: NSObject, CLLocationManagerDelegate {
  private let channel: FlutterMethodChannel
  private let locations = CLLocationManager()
  private var waiting: [FlutterResult] = []

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "app.burumy/phone", binaryMessenger: messenger)
    super.init()
    locations.delegate = self
    locations.desiredAccuracy = kCLLocationAccuracyBest
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "location": locate(result)
    case "cutout":
      let data = (args?["bytes"] as? FlutterStandardTypedData)?.data ?? Data()
      DispatchQueue.global(qos: .userInitiated).async {
        let out = Self.cutout(data)
        DispatchQueue.main.async { result(out.map { FlutterStandardTypedData(bytes: $0) }) }
      }
    case "transcribe":
      // 음성 메시지를 글로 보기: Apple speech recognition, on this iPhone only.
      let data = (args?["bytes"] as? FlutterStandardTypedData)?.data ?? Data()
      // 동그란 영상 메시지 (tip 361): the sound is taken out of the video first.
      if (args?["mime"] as? String ?? "").hasPrefix("video/") {
        Self.videoSound(data) { url in
          guard let url, let sound = try? Data(contentsOf: url) else { result(nil); return }
          try? FileManager.default.removeItem(at: url)
          Self.transcribe(sound, lang: args?["lang"] as? String ?? "ko", result)
        }
      } else {
        Self.transcribe(data, lang: args?["lang"] as? String ?? "ko", result)
      }
    case "addEvent":
      // 캘린더에 추가: the iPhone's own "new event" sheet, filled in. Since
      // iOS 17 this sheet needs no calendar permission (the person saves it).
      addEvent(args ?? [:], result)
    case "scanDocument":
      // 문서 스캔: Apple's document camera finds the page edges and flattens
      // each page; we join the pages into one PDF. Nothing leaves the iPhone.
      scanDocument(result)
    case "readText":
      // 사진 속 글자 (Live Text): Apple Vision on this iPhone, nothing leaves it.
      let data = (args?["bytes"] as? FlutterStandardTypedData)?.data ?? Data()
      DispatchQueue.global(qos: .userInitiated).async {
        let out = Self.readText(data)
        DispatchQueue.main.async { result(out) }
      }
    case "saveImage":
      // Add-only Photos access (asks once; never reads the library).
      let data = (args?["bytes"] as? FlutterStandardTypedData)?.data ?? Data()
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        guard status == .authorized || status == .limited, !data.isEmpty else {
          DispatchQueue.main.async { result(false) }
          return
        }
        PHPhotoLibrary.shared().performChanges({
          PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
        }) { ok, _ in DispatchQueue.main.async { result(ok) } }
      }
    case "share":
      var items: [Any] = []
      if let text = args?["text"] as? String { items.append(text) }
      if let data = (args?["bytes"] as? FlutterStandardTypedData)?.data, let image = UIImage(data: data) { items.append(image) }
      guard !items.isEmpty,
        let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController
      else {
        result(false)
        return
      }
      let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
      // iPad: the sheet needs a place to point at.
      sheet.popoverPresentationController?.sourceView = root.view
      sheet.popoverPresentationController?.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.maxY - 80, width: 1, height: 1)
      root.present(sheet, animated: true)
      result(true)
    case "recent": recent(limit: args?["limit"] as? Int ?? 60, album: args?["album"] as? String, result)
    case "albums": albums(result)
    case "stripAudio": stripAudio((args?["bytes"] as? FlutterStandardTypedData)?.data ?? Data(), mov: args?["mov"] as? Bool ?? false, result)
    case "videoFrames":
      videoFrames((args?["bytes"] as? FlutterStandardTypedData)?.data ?? Data(), mov: args?["mov"] as? Bool ?? false,
                  count: args?["count"] as? Int ?? 10, height: args?["height"] as? Int ?? 96, result)
    case "editVideo":
      editVideo((args?["bytes"] as? FlutterStandardTypedData)?.data ?? Data(), mov: args?["mov"] as? Bool ?? false,
                startMs: args?["startMs"] as? Int ?? 0, endMs: args?["endMs"] as? Int ?? -1,
                turns: args?["turns"] as? Int ?? 0, flip: args?["flip"] as? Bool ?? false, mute: args?["mute"] as? Bool ?? false,
                height: args?["height"] as? Int ?? 0, result)
    case "load": load(id: args?["id"] as? String ?? "", result)
    case "battery":
      UIDevice.current.isBatteryMonitoringEnabled = true
      let level = UIDevice.current.batteryLevel
      result(level < 0 ? nil : Int((level * 100).rounded()))
    case "network":
      // "wifi", "cellular" or "none" (for auto-download settings).
      var flags = SCNetworkReachabilityFlags()
      if let r = SCNetworkReachabilityCreateWithName(nil, "burumy.app"), SCNetworkReachabilityGetFlags(r, &flags), flags.contains(.reachable) {
        result(flags.contains(.isWWAN) ? "cellular" : "wifi")
      } else {
        result("none")
      }
    case "settings":
      if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
      result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }

  // MARK: location

  private func locate(_ result: @escaping FlutterResult) {
    guard CLLocationManager.locationServicesEnabled() else { return result(FlutterError(code: "off", message: nil, details: nil)) }
    switch locations.authorizationStatus {
    case .denied, .restricted: return result(FlutterError(code: "denied", message: nil, details: nil))
    default: break
    }
    waiting.append(result)
    if waiting.count > 1 { return }
    if locations.authorizationStatus == .notDetermined {
      locations.requestWhenInUseAuthorization()  // the answer comes in locationManagerDidChangeAuthorization
    } else {
      locations.requestLocation()
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard !waiting.isEmpty else { return }
    switch manager.authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways: manager.requestLocation()
    case .denied, .restricted: finish(FlutterError(code: "denied", message: nil, details: nil))
    default: break
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations list: [CLLocation]) {
    guard let l = list.last else { return }
    finish(["lat": l.coordinate.latitude, "lon": l.coordinate.longitude, "accuracy": l.horizontalAccuracy >= 0 ? l.horizontalAccuracy : nil] as [String: Any?])
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    let denied = (error as? CLError)?.code == .denied
    finish(FlutterError(code: denied ? "denied" : "unavailable", message: nil, details: nil))
  }

  private func finish(_ value: Any?) {
    let all = waiting
    waiting.removeAll()
    all.forEach { $0(value) }
  }

  // MARK: 소리 끄기 (GIF)

  /// The video with only its picture track, copied as is (passthrough, no
  /// re-encode); temp files are removed right after.
  private func stripAudio(_ data: Data, mov: Bool, _ result: @escaping FlutterResult) {
    let tmp = FileManager.default.temporaryDirectory
    let src = tmp.appendingPathComponent("mute-in-\(UUID().uuidString).\(mov ? "mov" : "mp4")")
    let dst = tmp.appendingPathComponent("mute-out-\(UUID().uuidString).mp4")
    func finish(_ out: Data?) {
      try? FileManager.default.removeItem(at: src)
      try? FileManager.default.removeItem(at: dst)
      DispatchQueue.main.async { result(out.map { FlutterStandardTypedData(bytes: $0) }) }
    }
    do { try data.write(to: src) } catch { return finish(nil) }
    let asset = AVURLAsset(url: src)
    let comp = AVMutableComposition()
    guard let v = asset.tracks(withMediaType: .video).first,
          let t = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
          (try? t.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: v, at: .zero)) != nil,
          let ex = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetPassthrough) else { return finish(nil) }
    t.preferredTransform = v.preferredTransform
    ex.outputURL = dst
    ex.outputFileType = .mp4
    ex.exportAsynchronously {
      finish(ex.status == .completed ? try? Data(contentsOf: dst) : nil)
    }
  }

  /// Video editor strip (Telegram tip 56): small JPEGs from along the video.
  private func videoFrames(_ data: Data, mov: Bool, count: Int, height: Int, _ result: @escaping FlutterResult) {
    let src = FileManager.default.temporaryDirectory.appendingPathComponent("frames-\(UUID().uuidString).\(mov ? "mov" : "mp4")")
    DispatchQueue.global(qos: .userInitiated).async {
      var out: [FlutterStandardTypedData] = []
      defer {
        try? FileManager.default.removeItem(at: src)
        DispatchQueue.main.async { result(out) }
      }
      guard (try? data.write(to: src)) != nil else { return }
      let asset = AVURLAsset(url: src)
      let gen = AVAssetImageGenerator(asset: asset)
      gen.appliesPreferredTrackTransform = true
      gen.maximumSize = CGSize(width: CGFloat(height) * 3, height: CGFloat(height))
      gen.requestedTimeToleranceBefore = CMTime(value: 1, timescale: 10)
      gen.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 10)
      let secs = CMTimeGetSeconds(asset.duration)
      guard secs.isFinite, secs > 0, count > 0 else { return }
      for i in 0..<min(count, 30) {
        let at = CMTime(seconds: secs * (Double(i) + 0.5) / Double(count), preferredTimescale: 600)
        if let cg = try? gen.copyCGImage(at: at, actualTime: nil),
           let jpg = UIImage(cgImage: cg).jpegData(compressionQuality: 0.7) {
          out.append(FlutterStandardTypedData(bytes: jpg))
        }
      }
    }
  }

  /// 동영상 자르기·회전 (Telegram tip 56): a new H.264 MP4 with only
  /// [start, end) kept, turned quarter turns to the left and mirrored.
  /// Made here before encryption, so cut-off parts never leave the phone.
  // height > 0: a smaller copy whose short side is that many lines (tips 114, 479, 480).
  private func editVideo(_ data: Data, mov: Bool, startMs: Int, endMs: Int, turns: Int, flip: Bool, mute: Bool, height: Int = 0, _ result: @escaping FlutterResult) {
    let tmp = FileManager.default.temporaryDirectory
    let src = tmp.appendingPathComponent("edit-in-\(UUID().uuidString).\(mov ? "mov" : "mp4")")
    let dst = tmp.appendingPathComponent("edit-out-\(UUID().uuidString).mp4")
    func finish(_ out: Data?) {
      try? FileManager.default.removeItem(at: src)
      try? FileManager.default.removeItem(at: dst)
      DispatchQueue.main.async { result(out.map { FlutterStandardTypedData(bytes: $0) }) }
    }
    do { try data.write(to: src) } catch { return finish(nil) }
    let asset = AVURLAsset(url: src)
    guard let v = asset.tracks(withMediaType: .video).first else { return finish(nil) }
    let full = asset.duration
    let start = CMTime(value: CMTimeValue(max(0, startMs)), timescale: 1000)
    let end = endMs < 0 ? full : CMTimeMinimum(full, CMTime(value: CMTimeValue(endMs), timescale: 1000))
    guard CMTimeCompare(end, start) > 0 else { return finish(nil) }
    let range = CMTimeRange(start: start, end: end)
    let comp = AVMutableComposition()
    guard let vt = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
          (try? vt.insertTimeRange(range, of: v, at: .zero)) != nil else { return finish(nil) }
    if !mute, let a = asset.tracks(withMediaType: .audio).first,
       let at = comp.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
      try? at.insertTimeRange(range, of: a, at: .zero)
    }
    // Upright picture size first (the phone's own turn), then ours.
    let natural = v.naturalSize.applying(v.preferredTransform)
    var size = CGSize(width: abs(natural.width), height: abs(natural.height))
    var t = v.preferredTransform
    // Move the upright picture to (0, 0).
    let box = CGRect(origin: .zero, size: v.naturalSize).applying(v.preferredTransform)
    t = t.concatenating(CGAffineTransform(translationX: -box.minX, y: -box.minY))
    if flip {
      t = t.concatenating(CGAffineTransform(scaleX: -1, y: 1)).concatenating(CGAffineTransform(translationX: size.width, y: 0))
    }
    for _ in 0..<((turns % 4 + 4) % 4) {
      // A quarter turn to the left: (x, y) -> (y, w - x) in screen space.
      t = t.concatenating(CGAffineTransform(a: 0, b: -1, c: 1, d: 0, tx: 0, ty: size.width))
      size = CGSize(width: size.height, height: size.width)
    }
    let short = min(size.width, size.height)
    if height > 0 && short > CGFloat(height) {
      let k = CGFloat(height) / short
      t = t.concatenating(CGAffineTransform(scaleX: k, y: k))
      size = CGSize(width: size.width * k, height: size.height * k)
    }
    let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: vt)
    layer.setTransform(t, at: .zero)
    let ins = AVMutableVideoCompositionInstruction()
    ins.timeRange = CMTimeRange(start: .zero, duration: range.duration)
    ins.layerInstructions = [layer]
    let vc = AVMutableVideoComposition()
    vc.instructions = [ins]
    vc.renderSize = CGSize(width: round(size.width / 2) * 2, height: round(size.height / 2) * 2)
    let fps = v.nominalFrameRate > 0 ? v.nominalFrameRate : 30
    vc.frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps.rounded()))
    // Small copies use the medium bit rate; edits keep the best quality.
    let preset = height > 0 && height <= 480 ? AVAssetExportPresetMediumQuality : AVAssetExportPresetHighestQuality
    guard let ex = AVAssetExportSession(asset: comp, presetName: preset) else { return finish(nil) }
    ex.videoComposition = vc
    ex.outputURL = dst
    ex.outputFileType = .mp4
    ex.shouldOptimizeForNetworkUse = true
    ex.exportAsynchronously {
      finish(ex.status == .completed ? try? Data(contentsOf: dst) : nil)
    }
  }

  // MARK: photos

  /// Smart albums the gallery menu offers (Telegram tip 324), in iPhone Photos order.
  private static let smart: [(String, PHAssetCollectionSubtype)] = [
    ("favorites", .smartAlbumFavorites), ("videos", .smartAlbumVideos), ("selfies", .smartAlbumSelfPortraits),
    ("screenshots", .smartAlbumScreenshots), ("live", .smartAlbumLivePhotos),
  ]

  private func collection(_ album: String) -> PHAssetCollection? {
    if album.hasPrefix("c:") {
      return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [String(album.dropFirst(2))], options: nil).firstObject
    }
    guard let sub = AppDelegate.smart.first(where: { $0.0 == album })?.1 else { return nil }
    return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: sub, options: nil).firstObject
  }

  private func mediaOptions() -> PHFetchOptions {
    let o = PHFetchOptions()
    o.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    o.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
    return o
  }

  private func albums(_ result: @escaping FlutterResult) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      guard status == .authorized || status == .limited else { return DispatchQueue.main.async { result(nil) } }
      var out: [[String: Any?]] = [["id": "recents", "name": nil, "count": PHAsset.fetchAssets(with: self.mediaOptions()).count]]
      for (id, _) in AppDelegate.smart {
        guard let c = self.collection(id) else { continue }
        let n = PHAsset.fetchAssets(in: c, options: self.mediaOptions()).count
        if n > 0 { out.append(["id": id, "name": nil, "count": n]) }
      }
      PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil).enumerateObjects { c, _, _ in
        let n = PHAsset.fetchAssets(in: c, options: self.mediaOptions()).count
        if n > 0 { out.append(["id": "c:\(c.localIdentifier)", "name": c.localizedTitle ?? "", "count": n]) }
      }
      DispatchQueue.main.async { result(out) }
    }
  }

  private func recent(limit: Int, album: String?, _ result: @escaping FlutterResult) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      guard status == .authorized || status == .limited else { return DispatchQueue.main.async { result(nil) } }
      let options = self.mediaOptions()
      options.fetchLimit = max(1, min(limit, 200))
      let assets: PHFetchResult<PHAsset>
      if let album = album, album != "recents" {
        guard let c = self.collection(album) else { return DispatchQueue.main.async { result([]) } }
        assets = PHAsset.fetchAssets(in: c, options: options)
      } else {
        assets = PHAsset.fetchAssets(with: options)
      }
      let thumbs = PHImageRequestOptions()
      thumbs.isSynchronous = true
      thumbs.deliveryMode = .highQualityFormat
      thumbs.resizeMode = .fast
      thumbs.isNetworkAccessAllowed = false
      var out: [[String: Any?]] = []
      assets.enumerateObjects { a, _, _ in
        PHImageManager.default().requestImage(for: a, targetSize: CGSize(width: 240, height: 240), contentMode: .aspectFill, options: thumbs) { img, _ in
          guard let data = img?.jpegData(compressionQuality: 0.75) else { return }
          out.append([
            "id": a.localIdentifier,
            "thumb": FlutterStandardTypedData(bytes: data),
            "video": a.mediaType == .video,
            "ms": a.mediaType == .video ? Int(a.duration * 1000) : nil,
            "live": a.mediaSubtypes.contains(.photoLive),
          ])
        }
      }
      DispatchQueue.main.async { result(out) }
    }
  }

  private func load(id: String, _ result: @escaping FlutterResult) {
    guard let a = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else {
      return result(FlutterError(code: "gone", message: nil, details: nil))
    }
    let name = PHAssetResource.assetResources(for: a).first?.originalFilename ?? (a.mediaType == .video ? "video.mov" : "photo.jpg")
    let send: (Data?) -> Void = { data in
      DispatchQueue.main.async {
        if let data { result(["name": name, "bytes": FlutterStandardTypedData(bytes: data)]) } else { result(FlutterError(code: "gone", message: nil, details: nil)) }
      }
    }
    if a.mediaType == .video {
      let o = PHVideoRequestOptions()
      o.isNetworkAccessAllowed = true
      o.version = .current
      PHImageManager.default().requestAVAsset(forVideo: a, options: o) { av, _, _ in
        send((av as? AVURLAsset).flatMap { try? Data(contentsOf: $0.url) })
      }
    } else if a.mediaSubtypes.contains(.photoLive) {
      loadLive(a, name: name, result)
    } else {
      let o = PHImageRequestOptions()
      o.isNetworkAccessAllowed = true
      o.version = .current
      PHImageManager.default().requestImageDataAndOrientation(for: a, options: o) { data, _, _, _ in send(data) }
    }
  }

  /// 움직이는 사진: the still as a JPEG (no photo details: re-encoded from
  /// pixels) and the paired ~3 s clip turned into an MP4 here, with the
  /// place / phone details left out (metadata filter "for sharing" + empty
  /// metadata). Falls back to the still only if the clip can't be read.
  private func loadLive(_ a: PHAsset, name: String, _ result: @escaping FlutterResult) {
    let o = PHImageRequestOptions()
    o.isNetworkAccessAllowed = true
    o.version = .current
    PHImageManager.default().requestImageDataAndOrientation(for: a, options: o) { data, _, _, _ in
      guard let data, let img = UIImage(data: data), let jpeg = img.jpegData(compressionQuality: 0.9) else {
        return DispatchQueue.main.async { result(FlutterError(code: "gone", message: nil, details: nil)) }
      }
      let base = (name as NSString).deletingPathExtension
      let still: [String: Any] = ["name": "\(base).jpg", "bytes": FlutterStandardTypedData(bytes: jpeg)]
      guard let res = PHAssetResource.assetResources(for: a).first(where: { $0.type == .pairedVideo || $0.type == .fullSizePairedVideo }) else {
        return DispatchQueue.main.async { result(still) }
      }
      let dir = FileManager.default.temporaryDirectory
      let mov = dir.appendingPathComponent("live-\(UUID().uuidString).mov")
      let mp4 = dir.appendingPathComponent("live-\(UUID().uuidString).mp4")
      let ro = PHAssetResourceRequestOptions()
      ro.isNetworkAccessAllowed = true
      PHAssetResourceManager.default().writeData(for: res, toFile: mov, options: ro) { err in
        guard err == nil, let ex = AVAssetExportSession(asset: AVURLAsset(url: mov), presetName: AVAssetExportPreset1280x720) else {
          try? FileManager.default.removeItem(at: mov)
          return DispatchQueue.main.async { result(still) }
        }
        ex.outputURL = mp4
        ex.outputFileType = .mp4
        ex.shouldOptimizeForNetworkUse = true
        ex.metadata = []
        ex.metadataItemFilter = .forSharing()
        ex.exportAsynchronously {
          let clip = ex.status == .completed ? try? Data(contentsOf: mp4) : nil
          try? FileManager.default.removeItem(at: mov)
          try? FileManager.default.removeItem(at: mp4)
          var out = still
          if let clip, clip.count <= 20 * 1024 * 1024 { out["clip"] = FlutterStandardTypedData(bytes: clip) }
          DispatchQueue.main.async { result(out) }
        }
      }
    }
  }

  /// 스티커 만들기: the main person or thing, lifted out on this phone with
  /// Vision (iOS 17+, the same as holding a photo in Photos). PNG with a
  /// see-through background; nil when nothing was found or iOS is older.
  /// Lines of text in a photo: [{text, x, y, w, h}] with the box as parts
  /// of the picture (0-1, top-left origin). nil when Vision can't run.
  static func readText(_ data: Data) -> [[String: Any]]? {
    guard let ui = UIImage(data: data), let cg = ui.cgImage else { return nil }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["ko-KR", "en-US"]
    let handler = VNImageRequestHandler(cgImage: cg, orientation: CGImagePropertyOrientation(ui.imageOrientation), options: [:])
    do {
      try handler.perform([request])
    } catch {
      return nil
    }
    var out: [[String: Any]] = []
    for obs in request.results ?? [] {
      guard let best = obs.topCandidates(1).first else { continue }
      let b = obs.boundingBox
      out.append(["text": best.string, "x": b.minX, "y": 1 - b.maxY, "w": b.width, "h": b.height])
    }
    return out
  }

  /// Words in a voice message. Forced on-device: a language this iPhone
  /// can only do on Apple's servers answers nil (the app says it can't).
  static func transcribe(_ data: Data, lang: String, _ result: @escaping FlutterResult) {
    let locale = Locale(identifier: lang == "ko" ? "ko-KR" : (lang == "en" ? "en-US" : lang))
    SFSpeechRecognizer.requestAuthorization { auth in
      DispatchQueue.main.async {
        guard auth == .authorized, let rec = SFSpeechRecognizer(locale: locale), rec.supportsOnDeviceRecognition else {
          result(nil)
          return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("stt-\(UUID().uuidString).m4a")
        do { try data.write(to: url) } catch { result(nil); return }
        let req = SFSpeechURLRecognitionRequest(url: url)
        req.requiresOnDeviceRecognition = true
        req.shouldReportPartialResults = false
        var done = false
        rec.recognitionTask(with: req) { got, err in
          if done { return }
          if let got, got.isFinal {
            done = true
            try? FileManager.default.removeItem(at: url)
            result(got.bestTranscription.formattedString)
          } else if err != nil {
            done = true
            try? FileManager.default.removeItem(at: url)
            // "No speech detected" is an answer, not a failure.
            result((err! as NSError).code == 1110 ? "" : nil)
          }
        }
      }
    }
  }

  /// The sound track of a video as an .m4a file in the app's temp folder
  /// (nil = no sound). The video copy is removed right away.
  static func videoSound(_ data: Data, _ done: @escaping (URL?) -> Void) {
    let tmp = FileManager.default.temporaryDirectory
    let src = tmp.appendingPathComponent("stt-\(UUID().uuidString).mp4")
    let out = tmp.appendingPathComponent("stt-\(UUID().uuidString).m4a")
    do { try data.write(to: src) } catch { done(nil); return }
    let asset = AVURLAsset(url: src)
    guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
      try? FileManager.default.removeItem(at: src)
      done(nil)
      return
    }
    export.outputURL = out
    export.outputFileType = .m4a
    export.exportAsynchronously {
      try? FileManager.default.removeItem(at: src)
      DispatchQueue.main.async { done(export.status == .completed ? out : nil) }
    }
  }

  static func cutout(_ data: Data) -> Data? {
    guard #available(iOS 17.0, *), let ui = UIImage(data: data), let cg = ui.cgImage else { return nil }
    let request = VNGenerateForegroundInstanceMaskRequest()
    let handler = VNImageRequestHandler(cgImage: cg, orientation: CGImagePropertyOrientation(ui.imageOrientation), options: [:])
    do {
      try handler.perform([request])
      guard let obs = request.results?.first, !obs.allInstances.isEmpty else { return nil }
      let buffer = try obs.generateMaskedMediaFromAllInstances(fromRequestHandler: handler, croppedToInstancesExtent: true)
      let ci = CIImage(cvPixelBuffer: buffer)
      let ctx = CIContext()
      guard let out = ctx.createCGImage(ci, from: ci.extent) else { return nil }
      return UIImage(cgImage: out).pngData()
    } catch {
      return nil
    }
  }
}

extension CGImagePropertyOrientation {
  init(_ o: UIImage.Orientation) {
    switch o {
    case .up: self = .up
    case .down: self = .down
    case .left: self = .left
    case .right: self = .right
    case .upMirrored: self = .upMirrored
    case .downMirrored: self = .downMirrored
    case .leftMirrored: self = .leftMirrored
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}

/// AI 편집기: Apple's built-in model (Apple Intelligence, iOS 26+), on the
/// phone only. Other iPhones answer "unsupported" and the app hides its AI
/// buttons. Nothing here talks to the internet.
final class AiChannel {
  private let channel: FlutterMethodChannel
  private var busy = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "app.burumy/ai", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    switch call.method {
    case "status": result(Self.status())
    case "run":
      let args = call.arguments as? [String: Any]
      run(rules: args?["rules"] as? String ?? "", text: args?["text"] as? String ?? "", result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private static func status() -> String {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      switch SystemLanguageModel.default.availability {
      case .available: return "ready"
      case .unavailable(.modelNotReady): return "preparing"
      default: return "unsupported"
      }
    }
    #endif
    return "unsupported"
  }

  private func run(rules: String, text: String, _ result: @escaping FlutterResult) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      guard Self.status() == "ready" else { return result(FlutterError(code: "unsupported", message: nil, details: nil)) }
      guard !busy else { return result(FlutterError(code: "busy", message: nil, details: nil)) }
      busy = true
      Task { @MainActor in
        defer { self.busy = false }
        do {
          // A new session each time: no memory between messages.
          let session = LanguageModelSession(instructions: rules)
          let answer = try await session.respond(to: text)
          result(answer.content)
        } catch let e as LanguageModelSession.GenerationError {
          switch e {
          case .guardrailViolation, .refusal: result(FlutterError(code: "refused", message: nil, details: nil))
          default: result(FlutterError(code: "failed", message: nil, details: nil))
          }
        } catch {
          result(FlutterError(code: "failed", message: nil, details: nil))
        }
      }
      return
    }
    #endif
    result(FlutterError(code: "unsupported", message: nil, details: nil))
  }
}

/// 문서 스캔 (VisionKit document camera → one PDF, A4-free: page = scan size).
final class DocumentScanner: NSObject, VNDocumentCameraViewControllerDelegate {
  static var current: DocumentScanner?
  private let done: FlutterResult
  init(_ done: @escaping FlutterResult) { self.done = done }

  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
    let pages = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
    controller.dismiss(animated: true)
    DispatchQueue.global(qos: .userInitiated).async {
      let first = pages.first?.size ?? CGSize(width: 595, height: 842)
      let pdf = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: first)).pdfData { ctx in
        for page in pages {
          ctx.beginPage(withBounds: CGRect(origin: .zero, size: page.size), pageInfo: [:])
          page.draw(in: CGRect(origin: .zero, size: page.size))
        }
      }
      DispatchQueue.main.async {
        self.done(pages.isEmpty ? nil : FlutterStandardTypedData(bytes: pdf))
        DocumentScanner.current = nil
      }
    }
  }

  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true)
    done(nil)
    DocumentScanner.current = nil
  }

  func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
    controller.dismiss(animated: true)
    done(nil)
    DocumentScanner.current = nil
  }
}

extension PhoneChannel {
  func scanDocument(_ result: @escaping FlutterResult) {
    guard VNDocumentCameraViewController.isSupported, DocumentScanner.current == nil,
      let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController
    else {
      result(nil)
      return
    }
    let scanner = DocumentScanner(result)
    DocumentScanner.current = scanner
    let camera = VNDocumentCameraViewController()
    camera.delegate = scanner
    root.present(camera, animated: true)
  }
}

/// 캘린더에 추가: shows EventKit's editor; closes itself when done.
final class EventSheet: NSObject, EKEventEditViewDelegate {
  static var current: EventSheet?
  let store = EKEventStore()
  private let done: FlutterResult
  init(_ done: @escaping FlutterResult) { self.done = done }

  func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
    controller.dismiss(animated: true)
    done(action == .saved)
    EventSheet.current = nil
  }
}

extension PhoneChannel {
  func addEvent(_ args: [String: Any], _ result: @escaping FlutterResult) {
    guard EventSheet.current == nil,
      let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController
    else {
      result(false)
      return
    }
    let sheet = EventSheet(result)
    EventSheet.current = sheet
    let event = EKEvent(eventStore: sheet.store)
    event.title = args["title"] as? String ?? ""
    event.startDate = Date(timeIntervalSince1970: Double(args["start"] as? Int ?? 0) / 1000)
    event.endDate = Date(timeIntervalSince1970: Double(args["end"] as? Int ?? 0) / 1000)
    if let place = args["place"] as? String, !place.isEmpty { event.location = place }
    event.addAlarm(EKAlarm(relativeOffset: -3600))
    let editor = EKEventEditViewController()
    editor.eventStore = sheet.store
    editor.event = event
    editor.editViewDelegate = sheet
    root.present(editor, animated: true)
  }
}

/// 번역: Apple's Translation framework on the phone (iOS 18+ checks, iOS 26+
/// translates; language packs come from iOS itself). NaturalLanguage guesses
/// the language. Nothing is sent to a translation server by the app.
final class TranslateChannel {
  private let channel: FlutterMethodChannel
  private var host: UIViewController?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "app.burumy/translate", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in self?.handle(call, result) }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    let text = args?["text"] as? String ?? ""
    let from = args?["from"] as? String ?? ""
    let to = args?["to"] as? String ?? ""
    switch call.method {
    case "detect":
      let r = NLLanguageRecognizer()
      r.processString(text)
      let lang = r.dominantLanguage?.rawValue
      result(lang == nil || lang == "und" ? nil : lang)
    case "status":
      #if canImport(Translation)
      if #available(iOS 18.0, *) {
        Task { @MainActor in
          let st = await LanguageAvailability().status(from: Locale.Language(identifier: from), to: Locale.Language(identifier: to))
          switch st {
          case .installed:
            if #available(iOS 26.0, *) { result("ready") } else { result("unsupported") }
          case .supported: result("download")
          default: result("unsupported")
          }
        }
        return
      }
      #endif
      result("unsupported")
    case "translate":
      #if canImport(Translation)
      if #available(iOS 26.0, *) {
        Task { @MainActor in
          do {
            let session = TranslationSession(installedSource: Locale.Language(identifier: from), target: Locale.Language(identifier: to))
            let out = try await session.translate(text)
            result(out.targetText)
          } catch {
            result(FlutterError(code: "download", message: nil, details: nil))
          }
        }
        return
      }
      #endif
      result(FlutterError(code: "unsupported", message: nil, details: nil))
    case "download":
      #if canImport(Translation)
      if #available(iOS 18.0, *) { return download(from: from, to: to, result) }
      #endif
      result(false)
    default: result(FlutterMethodNotImplemented)
    }
  }

  #if canImport(Translation)
  /// iOS's own "download language" sheet, from an invisible SwiftUI view.
  @available(iOS 18.0, *)
  private func download(from: String, to: String, _ result: @escaping FlutterResult) {
    guard let top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first else { return result(false) }
    var done = false
    let finish: (Bool) -> Void = { [weak self] ok in
      guard !done else { return }
      done = true
      self?.host?.dismiss(animated: false)
      self?.host = nil
      result(ok)
    }
    let view = TranslationPrep(config: TranslationSession.Configuration(source: Locale.Language(identifier: from), target: Locale.Language(identifier: to)), finish: finish)
    let vc = UIHostingController(rootView: view)
    vc.view.backgroundColor = .clear
    vc.modalPresentationStyle = .overFullScreen
    host = vc
    var shown = top
    while let next = shown.presentedViewController { shown = next }
    shown.present(vc, animated: false)
  }
  #endif
}

#if canImport(Translation)
@available(iOS 18.0, *)
private struct TranslationPrep: View {
  let config: TranslationSession.Configuration
  let finish: (Bool) -> Void
  var body: some View {
    Color.clear.translationTask(config) { session in
      do {
        try await session.prepareTranslation()
        await MainActor.run { finish(true) }
      } catch {
        await MainActor.run { finish(false) }
      }
    }
  }
}
#endif
