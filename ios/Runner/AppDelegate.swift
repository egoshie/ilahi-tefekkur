import UIKit
import Flutter
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

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }

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

            let mediaChannel = FlutterMethodChannel(
                name: "com.ilahi.tefekkur/media",
                binaryMessenger: controller.binaryMessenger
            )

            mediaChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
                guard call.method == "saveImageToGallery" else {
                    result(FlutterMethodNotImplemented)
                    return
                }

                guard let args = call.arguments as? [String: Any],
                      let typedData = args["bytes"] as? FlutterStandardTypedData,
                      let image = UIImage(data: typedData.data) else {
                    result(false)
                    return
                }

                let saveBlock = {
                    let target = PhotoSaveCallbackTarget { success in
                        DispatchQueue.main.async {
                            self?.activePhotoTarget = nil
                            result(success)
                        }
                    }
                    self?.activePhotoTarget = target
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
                            DispatchQueue.main.async {
                                saveBlock()
                            }
                        } else {
                            DispatchQueue.main.async {
                                result(false)
                            }
                        }
                    }
                } else {
                    PHPhotoLibrary.requestAuthorization { status in
                        if status == .authorized {
                            DispatchQueue.main.async {
                                saveBlock()
                            }
                        } else {
                            DispatchQueue.main.async {
                                result(false)
                            }
                        }
                    }
                }
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
