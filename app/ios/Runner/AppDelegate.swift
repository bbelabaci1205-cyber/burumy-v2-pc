// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import AVFoundation
import CoreLocation
import Flutter
import Photos
import SystemConfiguration
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var screen: FlutterMethodChannel?
  private var phone: PhoneChannel?

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
      case "captured": result(UIScreen.main.isCaptured)
      default: result(FlutterMethodNotImplemented)
      }
    }
    screen = channel
    phone = PhoneChannel(messenger: engineBridge.pluginRegistry.registrar(forPlugin: "BurumyPhone")!.messenger())
    NotificationCenter.default.addObserver(forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
      self?.screen?.invokeMethod("capturedChanged", arguments: UIScreen.main.isCaptured)
    }
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
    case "recent": recent(limit: args?["limit"] as? Int ?? 60, result)
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

  // MARK: photos

  private func recent(limit: Int, _ result: @escaping FlutterResult) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      guard status == .authorized || status == .limited else { return DispatchQueue.main.async { result(nil) } }
      let options = PHFetchOptions()
      options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      options.predicate = NSPredicate(format: "mediaType == %d || mediaType == %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
      options.fetchLimit = max(1, min(limit, 200))
      let assets = PHAsset.fetchAssets(with: options)
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
    } else {
      let o = PHImageRequestOptions()
      o.isNetworkAccessAllowed = true
      o.version = .current
      PHImageManager.default().requestImageDataAndOrientation(for: a, options: o) { data, _, _, _ in send(data) }
    }
  }
}
