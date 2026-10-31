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
        let isPlaying = args["isPlaying"] as? Bool ?? true
        let dur = args["durationSeconds"] as? Double ?? 12.0
        let elp = args["elapsedSeconds"] as? Double ?? 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyPlaybackDuration: dur,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elp,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
    }
    private func savePhotoToLibrary(image: UIImage, result: @escaping FlutterResult) {
        let target = PhotoSaveCallbackTarget { [weak self] ok in DispatchQueue.main.async { self?.activePhotoTarget = nil; result(ok) } }
        self.activePhotoTarget = target
        UIImageWriteToSavedPhotosAlbum(image, target, #selector(PhotoSaveCallbackTarget.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
}
