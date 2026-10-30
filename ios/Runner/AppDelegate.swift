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

    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        super.init()
    }

    @objc func image(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        completion(error == nil)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var activePhotoTarget: PhotoSaveCallbackTarget?
    private var mediaChannel: FlutterMethodChannel?
    private var cachedArtwork: MPMediaItemArtwork?
    private var remoteCommandsConfigured = false

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }

        configureBackgroundAudioSession()

        if let controller = window?.rootViewController as? FlutterViewController {
            let bridgeChannel = FlutterMethodChannel(
                name: "com.ilahi.tefekkur/native_bridge",
                binaryMessenger: controller.binaryMessenger
            )

            bridgeChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
                switch call.method {
                case "enableHourlyLockScreenVerse":
                    if let args = call.arguments as? [String: Any] {
                        let arabic = args["arabic"] as? String ?? ""
                        let translation = args["translation"] as? String ?? ""
                        let reference = args["reference"] as? String ?? ""
                        let badge = args["badge"] as? String ?? "Günün İlhamı"

                        let std = UserDefaults.standard
                        std.set(arabic, forKey: "hourly_arabic")
                        std.set(translation, forKey: "hourly_translation")
                        std.set(reference, forKey: "hourly_reference")
                        std.set(badge, forKey: "hourly_badge")

                        if let shared = UserDefaults(suiteName: "group.com.ilahi.tefekkur") {
                            shared.set(arabic, forKey: "hourly_arabic")
                            shared.set(translation, forKey: "hourly_translation")
                            shared.set(reference, forKey: "hourly_reference")
                            shared.set(badge, forKey: "hourly_badge")
                            shared.synchronize()
                        }

                        if #available(iOS 14.0, *) {
                            #if canImport(WidgetKit)
                            WidgetCenter.shared.reloadAllTimelines()
                            #endif
                        }
                    }
                    result(true)

                case "stopHourlyLockScreenVerse":
                    UNUserNotificationCenter.current().removePendingNotificationRequests(
                        withIdentifiers: ["hourly_verse_777"]
                    )
                    result(true)

                case "scheduleExactAdhan":
                    result(true)

                default:
                    result(FlutterMethodNotImplemented)
                }
            }

            let mChannel = FlutterMethodChannel(
                name: "com.ilahi.tefekkur/media",
                binaryMessenger: controller.binaryMessenger
            )
            self.mediaChannel = mChannel
            setupRemoteTransportCommands()

            mChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
                guard let self = self else {
                    result(false)
                    return
                }

                switch call.method {
                case "updateNowPlaying":
                    if let args = call.arguments as? [String: Any] {
                        self.configureBackgroundAudioSession()
                        self.updateNowPlayingMetadata(args: args)
                    }
                    result(true)

                case "clearNowPlaying":
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
                    result(true)

                case "saveImageToGallery":
                    guard let args = call.arguments as? [String: Any],
                          let typedData = args["bytes"] as? FlutterStandardTypedData,
                          let image = UIImage(data: typedData.data) else {
                        result(false)
                        return
                    }
                    self.savePhotoToLibrary(image: image, result: result)

                default:
                    result(FlutterMethodNotImplemented)
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
        } catch {
            // AudioSession arka plan yapılandırma hatası sessizce geçilir
        }
    }

    private func setupRemoteTransportCommands() {
        if remoteCommandsConfigured { return }
        remoteCommandsConfigured = true

        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.mediaChannel?.invokeMethod("remotePlay", arguments: nil)
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.mediaChannel?.invokeMethod("remotePause", arguments: nil)
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.mediaChannel?.invokeMethod("remotePlay", arguments: nil)
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.mediaChannel?.invokeMethod("remoteNext", arguments: nil)
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.mediaChannel?.invokeMethod("remotePrev", arguments: nil)
            return .success
        }
    }

    private func updateNowPlayingMetadata(args: [String: Any]) {
        let title = args["title"] as? String ?? "Huzur • Kur'ân-ı Kerîm"
        let artist = args["artist"] as? String ?? "Mishary Rashid Al-Afasy"
        let album = args["album"] as? String ?? "Huzur"
        let isPlaying = args["isPlaying"] as? Bool ?? true
        let durationSeconds = args["durationSeconds"] as? Double ?? 12.0
        let elapsedSeconds = args["elapsedSeconds"] as? Double ?? 0.0

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: album,
            MPMediaItemPropertyPlaybackDuration: durationSeconds,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsedSeconds,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        if let artwork = getOrCreateHuzurArtwork() {
            info[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func getOrCreateHuzurArtwork() -> MPMediaItemArtwork? {
        if let existing = cachedArtwork {
            return existing
        }
        let size = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let cgCtx = ctx.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                UIColor(red: 0.02, green: 0.07, blue: 0.14, alpha: 1.0).cgColor,
                UIColor(red: 0.04, green: 0.18, blue: 0.24, alpha: 1.0).cgColor,
                UIColor(red: 0.06, green: 0.28, blue: 0.32, alpha: 1.0).cgColor
            ] as CFArray
            if let grad = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 0.55, 1.0]) {
                cgCtx.drawLinearGradient(
                    grad,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: 512, y: 512),
                    options: []
                )
            }

            cgCtx.setStrokeColor(UIColor(red: 0.39, green: 1.0, blue: 0.85, alpha: 0.55).cgColor)
            cgCtx.setLineWidth(6.0)
            cgCtx.strokeEllipse(in: CGRect(x: 76, y: 76, width: 360, height: 360))

            cgCtx.setStrokeColor(UIColor(red: 1.0, green: 0.88, blue: 0.51, alpha: 0.85).cgColor)
            cgCtx.setLineWidth(4.0)
            cgCtx.strokeEllipse(in: CGRect(x: 108, y: 108, width: 296, height: 296))

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .heavy),
                .foregroundColor: UIColor(red: 1.0, green: 0.92, blue: 0.65, alpha: 1.0),
                .paragraphStyle: paragraph
            ]
            let titleStr = NSString(string: "HUZUR")
            titleStr.draw(in: CGRect(x: 40, y: 205, width: 432, height: 80), withAttributes: titleAttrs)

            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor(red: 0.39, green: 1.0, blue: 0.85, alpha: 0.95),
                .paragraphStyle: paragraph
            ]
            let subStr = NSString(string: "Kur'ân-ı Kerîm Tilaveti")
            subStr.draw(in: CGRect(x: 40, y: 285, width: 432, height: 40), withAttributes: subAttrs)
        }

        let artwork = MPMediaItemArtwork(boundsSize: size) { _ in return img }
        cachedArtwork = artwork
        return artwork
    }

    private func savePhotoToLibrary(image: UIImage, result: @escaping FlutterResult) {
        let saveBlock = {
            let target = PhotoSaveCallbackTarget { [weak self] success in
                DispatchQueue.main.async {
                    self?.activePhotoTarget = nil
                    result(success)
                }
            }
            self.activePhotoTarget = target
            UIImageWriteToSavedPhotosAlbum(
                image,
                target,
                #selector(PhotoSaveCallbackTarget.image(_:didFinishSavingWithError:contextInfo:)),
                nil
            )
        }

        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized || status == .limited {
                    DispatchQueue.main.async { saveBlock() }
                } else {
                    DispatchQueue.main.async { result(false) }
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    DispatchQueue.main.async { saveBlock() }
                } else {
                    DispatchQueue.main.async { result(false) }
                }
            }
        }
    }
}
