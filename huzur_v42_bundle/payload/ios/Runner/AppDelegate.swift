import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private static let mediaChannelName = "com.ilahi.tefekkur/media"
    private static let appGroupIdentifier = "group.com.ilahi.tefekkur"
    private var pendingGalleryResult: FlutterResult?

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
        guard let pluginRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "HuzurMediaBridge") else {
            return
        }
        let channel = FlutterMethodChannel(
            name: AppDelegate.mediaChannelName,
            binaryMessenger: pluginRegistrar.messenger()
        )
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(FlutterError(code: "APP_DEALLOCATED", message: "Uygulama köprüsü kullanılamıyor.", details: nil))
                return
            }
            switch call.method {
            case "saveImageToGallery":
                guard let typedData = call.arguments as? FlutterStandardTypedData,
                      let image = UIImage(data: typedData.data) else {
                    result(FlutterError(code: "INVALID_IMAGE", message: "PNG verisi okunamadı.", details: nil))
                    return
                }
                guard self.pendingGalleryResult == nil else {
                    result(FlutterError(code: "SAVE_IN_PROGRESS", message: "Önceki galeri kaydı tamamlanıyor.", details: nil))
                    return
                }
                self.pendingGalleryResult = result
                UIImageWriteToSavedPhotosAlbum(
                    image,
                    self,
                    #selector(self.image(_:didFinishSavingWithError:contextInfo:)),
                    nil
                )
            case "updateWidgetVerse":
                guard let payload = call.arguments as? [String: String] else {
                    result(FlutterError(code: "INVALID_WIDGET_DATA", message: "Widget verisi geçersiz.", details: nil))
                    return
                }
                let defaults = UserDefaults(suiteName: AppDelegate.appGroupIdentifier)
                defaults?.set(payload["arabic"] ?? "", forKey: "huzur_widget_arabic")
                defaults?.set(payload["turkish"] ?? "", forKey: "huzur_widget_turkish")
                defaults?.set(payload["reference"] ?? "", forKey: "huzur_widget_reference")
                defaults?.synchronize()
                WidgetCenter.shared.reloadAllTimelines()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @objc private func image(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer?
    ) {
        let callback = pendingGalleryResult
        pendingGalleryResult = nil
        if let error = error {
            callback?(FlutterError(code: "PHOTO_SAVE_FAILED", message: error.localizedDescription, details: nil))
        } else {
            callback?(true)
        }
    }
}
