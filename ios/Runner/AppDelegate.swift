import UIKit
import Flutter
import UserNotifications
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        }

        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
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

                    let defaults = UserDefaults.standard
                    defaults.set(arabic, forKey: "hourly_arabic")
                    defaults.set(translation, forKey: "hourly_translation")
                    defaults.set(reference, forKey: "hourly_reference")

                    if #available(iOS 14.0, *) {
                        #if canImport(WidgetKit)
                        WidgetCenter.shared.reloadAllTimelines()
                        #endif
                    }
                }
                result(true)

            case "stopHourlyLockScreenVerse":
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["hourly_verse_777"])
                result(true)

            case "scheduleExactAdhan":
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
