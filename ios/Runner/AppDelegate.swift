import UIKit
import Flutter
import AVFoundation
import MediaPlayer
import Photos
import UserNotifications
#if canImport(WidgetKit)
import WidgetKit
#endif

class PhotoSaveCallbackTarget: NSObject {
    private let completion: (Bool) -> Void
    init(completion: @escaping (Bool) -> Void) { self.completion = completion; super.init() }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) { completion(error == nil) }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var activePhotoTarget: PhotoSaveCallbackTarget?
    private var mediaChannel: FlutterMethodChannel?
    private var cachedArtwork: MPMediaItemArtwork?
    private var remoteCommandsConfigured = false

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 10.0, *) { UNUserNotificationCenter.current().delegate = self }
        configureBackgroundAudioSession()
        if #available(iOS 14.0, *) {
#if canImport(WidgetKit)
WidgetCenter.shared.reloadAllTimelines()
#endif
}
        if let controller = window?.rootViewController as? FlutterViewController {
            let bridgeChannel = FlutterMethodChannel(name: "com.ilahi.tefekkur/native_bridge", binaryMessenger: controller.binaryMessenger)
            bridgeChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
                switch call.method {
                case "enableHourlyLockScreenVerse":
                    if let args = call.arguments as? [String: Any] {
                        let ar = args["arabic"] as? String ?? ""
                        let tr = args["translation"] as? String ?? ""
                        let rf = args["reference"] as? String ?? ""
                        UserDefaults.standard.set(ar, forKey: "hourly_arabic")
                        UserDefaults.standard.set(tr, forKey: "hourly_translation")
                        UserDefaults.standard.set(rf, forKey: "hourly_reference")
                        if let sh = UserDefaults(suiteName: "group.com.ilahi.tefekkur") {
                            sh.set(ar, forKey: "hourly_arabic"); sh.set(tr, forKey: "hourly_translation"); sh.set(rf, forKey: "hourly_reference"); sh.synchronize()
                        }
                        if #available(iOS 14.0, *) {
#if canImport(WidgetKit)
WidgetCenter.shared.reloadAllTimelines()
#endif
}
                    }
                    result(true)
                case "checkFounderDevice":
                    let founderUDID = "00008140-001D793E2230801C"
                    let vendorId = UIDevice.current.identifierForVendor?.uuidString ?? ""
                    var isFounder = false
                    if vendorId.uppercased() == founderUDID.uppercased() {
                        isFounder = true
                    }
                    if let provPath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
                       let provData = try? Data(contentsOf: URL(fileURLWithPath: provPath)),
                       let provStr = String(data: provData, encoding: .isoLatin1),
                       provStr.uppercased().contains(founderUDID.uppercased()) {
                        isFounder = true
                    }
                    result(["isFounder": isFounder, "vendorId": vendorId, "udid": founderUDID])
                case "openExternalUrl":
                    if let args = call.arguments as? [String: Any], let uStr = args["url"] as? String, let u = URL(string: uStr) {
                        DispatchQueue.main.async { UIApplication.shared.open(u, options: [:], completionHandler: nil) }
                    }
                    result(true)
                default: result(true)
                }
            }
            let mChannel = FlutterMethodChannel(name: "com.ilahi.tefekkur/media", binaryMessenger: controller.binaryMessenger)
            self.mediaChannel = mChannel
            setupRemoteTransportCommands()
            mChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
                guard let self = self else { result(false); return }
                switch call.method {
                case "updateNowPlaying":
                    if let args = call.arguments as? [String: Any] { self.configureBackgroundAudioSession(); self.updateNowPlayingMetadata(args: args) }
                    result(true)
                case "clearNowPlaying": MPNowPlayingInfoCenter.default().nowPlayingInfo = nil; result(true)
                case "shareToInstagramStory":
                    guard let args = call.arguments as? [String: Any],
                          let td = args["bytes"] as? FlutterStandardTypedData else { result(false); return }
                    self.launchInstagramStory(imageData: td.data, result: result)
                case "shareToWhatsAppDirect":
                    guard let args = call.arguments as? [String: Any],
                          let td = args["bytes"] as? FlutterStandardTypedData,
                          let img = UIImage(data: td.data) else { result(false); return }
                    self.launchWhatsAppShare(image: img, text: args["text"] as? String ?? "", result: result)
                case "saveImageToGallery":
                    guard let args = call.arguments as? [String: Any], let td = args["bytes"] as? FlutterStandardTypedData, let img = UIImage(data: td.data) else { result(false); return }
                    self.savePhotoToLibrary(image: img, result: result)
                default: result(true)
                }
            }
        }
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    private func configureBackgroundAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {}
    }
    private func setupRemoteTransportCommands() {
        if remoteCommandsConfigured { return }
        remoteCommandsConfigured = true
        let cc = MPRemoteCommandCenter.shared()
        cc.playCommand.isEnabled = true
        cc.playCommand.addTarget { [weak self] _ in self?.mediaChannel?.invokeMethod("remotePlay", arguments: nil); return .success }
        cc.pauseCommand.isEnabled = true
        cc.pauseCommand.addTarget { [weak self] _ in self?.mediaChannel?.invokeMethod("remotePause", arguments: nil); return .success }
        cc.nextTrackCommand.isEnabled = true
        cc.nextTrackCommand.addTarget { [weak self] _ in self?.mediaChannel?.invokeMethod("remoteNext", arguments: nil); return .success }
        cc.previousTrackCommand.isEnabled = true
        cc.previousTrackCommand.addTarget { [weak self] _ in self?.mediaChannel?.invokeMethod("remotePrev", arguments: nil); return .success }
    }
    private func updateNowPlayingMetadata(args: [String: Any]) {
        let title = args["title"] as? String ?? "Huzur"
        let artist = args["artist"] as? String ?? "Mishary Rashid Al-Afasy"
        let album = args["album"] as? String ?? "Huzur • İlahi Tilavet"
        let isPlaying = args["isPlaying"] as? Bool ?? true
        let dur = args["durationSeconds"] as? Double ?? 12.0
        let elp = args["elapsedSeconds"] as? Double ?? 0.0
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: album,
            MPMediaItemPropertyPlaybackDuration: dur,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elp,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let artwork = getOrCreateHuzurArtwork() {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func getOrCreateHuzurArtwork() -> MPMediaItemArtwork? {
        if let existing = cachedArtwork { return existing }
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(red: 0.03, green: 0.14, blue: 0.19, alpha: 1.0).cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
            cg.setStrokeColor(UIColor(red: 0.39, green: 1.0, blue: 0.85, alpha: 0.85).cgColor)
            cg.setLineWidth(10.0)
            cg.strokeEllipse(in: CGRect(x: 64, y: 64, width: 384, height: 384))
            cg.setFillColor(UIColor(red: 1.0, green: 0.88, blue: 0.51, alpha: 0.95).cgColor)
            cg.fillEllipse(in: CGRect(x: 156, y: 156, width: 200, height: 200))
            cg.setFillColor(UIColor(red: 0.03, green: 0.14, blue: 0.19, alpha: 1.0).cgColor)
            cg.fillEllipse(in: CGRect(x: 192, y: 140, width: 185, height: 185))
        }
        let art = MPMediaItemArtwork(boundsSize: size) { _ in return img }
        cachedArtwork = art
        return art
    }
    private func savePhotoToLibrary(image: UIImage, result: @escaping FlutterResult) {
        let target = PhotoSaveCallbackTarget { [weak self] ok in DispatchQueue.main.async { self?.activePhotoTarget = nil; result(ok) } }
        self.activePhotoTarget = target
        UIImageWriteToSavedPhotosAlbum(image, target, #selector(PhotoSaveCallbackTarget.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    private func launchInstagramStory(imageData: Data, result: @escaping FlutterResult) {
        guard let url = URL(string: "instagram-stories://share?source_application=com.ilahi.tefekkur") else { result(false); return }
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(url) {
                let pasteboardItems: [[String: Any]] = [[
                    "com.instagram.sharedSticker.backgroundImage": imageData,
                    "com.instagram.sharedSticker.backgroundTopColor": "#030B18",
                    "com.instagram.sharedSticker.backgroundBottomColor": "#0E3842"
                ]]
                let options: [UIPasteboard.OptionsKey: Any] = [.expirationDate: Date().addingTimeInterval(300)]
                UIPasteboard.general.setItems(pasteboardItems, options: options)
                UIApplication.shared.open(url, options: [:]) { ok in result(ok) }
            } else {
                result(false)
            }
        }
    }

    private func launchWhatsAppShare(image: UIImage, text: String, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            UIPasteboard.general.image = image
            let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let waUrl = URL(string: "whatsapp://send?text=\(encoded)"), UIApplication.shared.canOpenURL(waUrl) {
                UIApplication.shared.open(waUrl, options: [:]) { ok in result(ok) }
            } else {
                result(false)
            }
        }
    }
}
