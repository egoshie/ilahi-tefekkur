import UIKit
import Flutter
import AVFoundation
import MediaPlayer
import Photos
import UserNotifications
import MapKit
#if canImport(WidgetKit)
import WidgetKit
#endif


final class HuzurAppleWorldMapAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    let markerKind: String

    init(
        coordinate: CLLocationCoordinate2D,
        title: String,
        markerKind: String
    ) {
        self.coordinate = coordinate
        self.title = title
        self.markerKind = markerKind
        super.init()
    }
}

final class HuzurAppleWorldMapFactory: NSObject,
    FlutterPlatformViewFactory {

    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        HuzurAppleWorldMapPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            messenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }
}

final class HuzurAppleWorldMapPlatformView: NSObject,
    FlutterPlatformView, MKMapViewDelegate {

    private let mapView: MKMapView
    private let channel: FlutterMethodChannel

    private let mecca = CLLocationCoordinate2D(
        latitude: 21.4225,
        longitude: 39.8262
    )

    private var cityName = "Kadirli"
    private var cityCoordinate = CLLocationCoordinate2D(
        latitude: 37.37,
        longitude: 36.10
    )
    private var showRoute = false
    private weak var meccaAnnotationView: MKMarkerAnnotationView?
    private var routeAnimationTimer: Timer?
    private var routeDashPhase: CGFloat = 0

    private var countryMarkers: [[String: Any]] = []

    // Ülke merkezlerine yakın temsili koordinatlar.
    // Bunlar bireysel kullanıcı konumları değildir.
    private let countryCoordinates: [String: CLLocationCoordinate2D] = [
        "US": CLLocationCoordinate2D(latitude: 39.83, longitude: -98.58),
        "CA": CLLocationCoordinate2D(latitude: 56.13, longitude: -106.35),
        "MX": CLLocationCoordinate2D(latitude: 23.63, longitude: -102.55),
        "BR": CLLocationCoordinate2D(latitude: -10.0, longitude: -55.0),
        "AR": CLLocationCoordinate2D(latitude: -38.42, longitude: -63.62),
        "GB": CLLocationCoordinate2D(latitude: 55.38, longitude: -3.44),
        "FR": CLLocationCoordinate2D(latitude: 46.23, longitude: 2.21),
        "DE": CLLocationCoordinate2D(latitude: 51.17, longitude: 10.45),
        "IT": CLLocationCoordinate2D(latitude: 41.87, longitude: 12.57),
        "ES": CLLocationCoordinate2D(latitude: 40.46, longitude: -3.75),
        "NL": CLLocationCoordinate2D(latitude: 52.13, longitude: 5.29),
        "SE": CLLocationCoordinate2D(latitude: 60.13, longitude: 18.64),
        "NO": CLLocationCoordinate2D(latitude: 60.47, longitude: 8.47),
        "RU": CLLocationCoordinate2D(latitude: 61.52, longitude: 105.32),
        "UA": CLLocationCoordinate2D(latitude: 48.38, longitude: 31.17),
        "TR": CLLocationCoordinate2D(latitude: 39.0, longitude: 35.0),
        "CY": CLLocationCoordinate2D(latitude: 35.13, longitude: 33.43),
        "AZ": CLLocationCoordinate2D(latitude: 40.14, longitude: 47.58),
        "SA": CLLocationCoordinate2D(latitude: 23.89, longitude: 45.08),
        "PS": CLLocationCoordinate2D(latitude: 31.95, longitude: 35.23),
        "AE": CLLocationCoordinate2D(latitude: 23.42, longitude: 53.85),
        "EG": CLLocationCoordinate2D(latitude: 26.82, longitude: 30.80),
        "NG": CLLocationCoordinate2D(latitude: 9.08, longitude: 8.68),
        "NE": CLLocationCoordinate2D(latitude: 17.61, longitude: 8.08),
        "TD": CLLocationCoordinate2D(latitude: 15.45, longitude: 18.73),
        "SD": CLLocationCoordinate2D(latitude: 12.86, longitude: 30.22),
        "CD": CLLocationCoordinate2D(latitude: -4.04, longitude: 21.76),
        "AO": CLLocationCoordinate2D(latitude: -11.20, longitude: 17.87),
        "ZA": CLLocationCoordinate2D(latitude: -30.56, longitude: 22.94),
        "MA": CLLocationCoordinate2D(latitude: 31.79, longitude: -7.09),
        "PK": CLLocationCoordinate2D(latitude: 30.38, longitude: 69.35),
        "IN": CLLocationCoordinate2D(latitude: 20.59, longitude: 78.96),
        "ID": CLLocationCoordinate2D(latitude: -0.79, longitude: 113.92),
        "MY": CLLocationCoordinate2D(latitude: 4.21, longitude: 101.98),
        "AU": CLLocationCoordinate2D(latitude: -25.27, longitude: 133.78),
        "JP": CLLocationCoordinate2D(latitude: 36.20, longitude: 138.25),
        "CN": CLLocationCoordinate2D(latitude: 35.86, longitude: 104.20),
        "KE": CLLocationCoordinate2D(latitude: -0.02, longitude: 37.91),
        "ET": CLLocationCoordinate2D(latitude: 9.15, longitude: 40.49)
    ]

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        mapView = MKMapView(frame: frame)
        channel = FlutterMethodChannel(
            name: "com.ilahi.tefekkur/apple-world-map/\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        mapView.delegate = self
        mapView.overrideUserInterfaceStyle = .dark
        mapView.backgroundColor = UIColor(
            red: 0.025,
            green: 0.045,
            blue: 0.075,
            alpha: 1
        )

        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsTraffic = false
        mapView.showsBuildings = true
        mapView.showsUserLocation = false

        if #available(iOS 16.0, *) {
            mapView.preferredConfiguration =
                MKHybridMapConfiguration(elevationStyle: .realistic)
        } else {
            mapView.mapType = .hybrid
        }

        let params = args as? [String: Any] ?? [:]
        updateCity(from: params, rebuild: false)
        rebuildMarkers()
        showOverview(animated: false)

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else {
                result(false)
                return
            }

            switch call.method {
            case "updateCity":
                if let params = call.arguments as? [String: Any] {
                    self.updateCity(from: params)
                }
                result(true)

            case "focusOnMecca":
                self.focusOnMecca(animated: true)
                result(true)

            case "animateDhikr":
                self.animateDhikr()
                result(true)

            case "setCountryMarkers":
                if let markers = call.arguments as? [[String: Any]] {
                    self.updateCountryMarkers(markers)
                }
                result(true)

            case "showOverview":
                self.showOverview(animated: true)
                result(true)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func view() -> UIView {
        mapView
    }

    private func updateCity(
        from params: [String: Any],
        rebuild: Bool = true
    ) {
        if let value = params["cityName"] as? String,
           !value.isEmpty {
            cityName = value
        }

        if let value = params["latitude"] as? NSNumber {
            cityCoordinate.latitude = value.doubleValue
        }

        if let value = params["longitude"] as? NSNumber {
            cityCoordinate.longitude = value.doubleValue
        }

        if let value = params["showRoute"] as? Bool {
            showRoute = value
        }

        if rebuild {
            rebuildMarkers()
        }
    }

    private func updateCountryMarkers(
        _ markers: [[String: Any]]
    ) {
        let sorted = markers.sorted {
            let left = ($0["total_count"] as? NSNumber)?.intValue ?? 0
            let right = ($1["total_count"] as? NSNumber)?.intValue ?? 0
            return left > right
        }

        countryMarkers = Array(sorted.prefix(24))
        rebuildMarkers()
    }

    private func rebuildMarkers() {
        routeAnimationTimer?.invalidate()
        routeAnimationTimer = nil
        routeDashPhase = 0

        mapView.removeAnnotations(
            mapView.annotations.filter { !($0 is MKUserLocation) }
        )
        mapView.removeOverlays(mapView.overlays)

        let city = HuzurAppleWorldMapAnnotation(
            coordinate: cityCoordinate,
            title: cityName,
            markerKind: "city"
        )

        let meccaMarker = HuzurAppleWorldMapAnnotation(
            coordinate: mecca,
            title: "Mekke-i Mükerreme",
            markerKind: "mecca"
        )

        mapView.addAnnotations([city, meccaMarker])

        let countryAnnotations = countryMarkers.compactMap { item
            -> HuzurAppleWorldMapAnnotation? in

            let code = (item["country_code"] as? String ?? "").uppercased()
            guard let coordinate = countryCoordinates[code] else {
                return nil
            }

            let name = item["country_name"] as? String ?? code
            let count = (item["total_count"] as? NSNumber)?.intValue ?? 0

            return HuzurAppleWorldMapAnnotation(
                coordinate: coordinate,
                title: "\(name) · \(count) zikir",
                markerKind: count > 0 ? "country_active" : "country_zero"
            )
        }

        mapView.addAnnotations(countryAnnotations)

        if showRoute {
            let coordinates = [cityCoordinate, mecca]
            let route = MKGeodesicPolyline(
                coordinates: coordinates,
                count: coordinates.count
            )
            mapView.addOverlay(route)
        }
    }

    private func showOverview(animated: Bool) {
        let camera = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(
                latitude: 21.0,
                longitude: 39.0
            ),
            fromDistance: 8_500_000,
            pitch: 0,
            heading: 0
        )
        mapView.setCamera(camera, animated: animated)
    }

    private func focusOnMecca(animated: Bool) {
        let camera = MKMapCamera(
            lookingAtCenter: mecca,
            fromDistance: 2_800_000,
            pitch: 42,
            heading: 0
        )
        mapView.setCamera(camera, animated: animated)
    }


    private func animateDhikr() {
        focusOnMecca(animated: true)

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.35
        ) { [weak self] in
            guard let marker = self?.meccaAnnotationView else {
                return
            }

            marker.layer.removeAnimation(forKey: "huzur.dhikr.pulse")

            let pulse = CAKeyframeAnimation(
                keyPath: "transform.scale"
            )
            pulse.values = [1.0, 1.18, 1.55, 1.0]
            pulse.keyTimes = [
                NSNumber(value: 0),
                NSNumber(value: 0.30),
                NSNumber(value: 0.68),
                NSNumber(value: 1),
            ]
            pulse.duration = 0.85
            pulse.timingFunction = CAMediaTimingFunction(
                name: .easeOut
            )

            marker.layer.add(
                pulse,
                forKey: "huzur.dhikr.pulse"
            )
        }
    }

    func mapView(
        _ mapView: MKMapView,
        viewFor annotation: MKAnnotation
    ) -> MKAnnotationView? {
        guard let marker = annotation as? HuzurAppleWorldMapAnnotation else {
            return nil
        }

        let identifier = "Huzur-\(marker.markerKind)"
        let view = mapView.dequeueReusableAnnotationView(
            withIdentifier: identifier
        ) as? MKMarkerAnnotationView
        ?? MKMarkerAnnotationView(
            annotation: marker,
            reuseIdentifier: identifier
        )

        view.annotation = marker
        view.canShowCallout = true
        view.displayPriority = .required
        view.titleVisibility = .visible
        switch marker.markerKind {
        case "mecca":
            view.markerTintColor = UIColor(
                red: 1.0, green: 0.78, blue: 0.39, alpha: 1
            )
            view.glyphImage = UIImage(systemName: "moon.stars.fill")

        case "country_active":
            view.markerTintColor = UIColor(
                red: 1.0, green: 0.78, blue: 0.39, alpha: 1
            )
            view.glyphImage = UIImage(systemName: "sparkles")

        case "country_zero":
            view.markerTintColor = UIColor(
                red: 0.43, green: 0.48, blue: 0.57, alpha: 1
            )
            view.glyphImage = UIImage(systemName: "circle")

        default:
            view.markerTintColor = UIColor(
                red: 0.37, green: 0.86, blue: 0.79, alpha: 1
            )
            view.glyphImage = UIImage(systemName: "location.fill")
        }

        if marker.markerKind == "mecca" {
            meccaAnnotationView = view
        }

        return view
    }

    func mapView(
        _ mapView: MKMapView,
        rendererFor overlay: MKOverlay
    ) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }

        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor(
            red: 1.0,
            green: 0.78,
            blue: 0.39,
            alpha: 0.95
        )
        renderer.lineWidth = 2.8
        renderer.lineCap = .round
        renderer.lineDashPattern = [
            NSNumber(value: 3),
            NSNumber(value: 6)
        ]
        startRouteDashAnimation(for: renderer)

        return renderer
    }

    private func startRouteDashAnimation(for renderer: MKPolylineRenderer) {
        routeAnimationTimer?.invalidate()
        routeDashPhase = 0

        let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self, weak renderer] _ in
            guard let self = self, let renderer = renderer, self.showRoute else {
                return
            }

            self.routeDashPhase =
                (self.routeDashPhase + 0.8).truncatingRemainder(dividingBy: 9.0)
            renderer.lineDashPhase = self.routeDashPhase
            renderer.setNeedsDisplay()
        }
        routeAnimationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    deinit {
        routeAnimationTimer?.invalidate()
    }
}


class PhotoSaveCallbackTarget: NSObject {
    private let completion: (Bool) -> Void
    init(completion: @escaping (Bool) -> Void) { self.completion = completion; super.init() }
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) { completion(error == nil) }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    private var activePhotoTarget: PhotoSaveCallbackTarget?
    private var mediaChannel: FlutterMethodChannel?
    private var nativeBridgeChannel: FlutterMethodChannel?
    private var cachedArtwork: MPMediaItemArtwork?
    private var remoteCommandsConfigured = false



    func didInitializeImplicitFlutterEngine(
        _ engineBridge: FlutterImplicitEngineBridge
    ) {
        GeneratedPluginRegistrant.register(
            with: engineBridge.pluginRegistry
        )

        if let registrar = engineBridge.pluginRegistry.registrar(
            forPlugin: "HuzurAppleWorldMapPlugin"
        ) {
            let factory = HuzurAppleWorldMapFactory(
                messenger: registrar.messenger()
            )

            registrar.register(
                factory,
                withId: "com.ilahi.tefekkur/apple-world-map"
            )
        }

        let bridgeChannel = FlutterMethodChannel(name: "com.ilahi.tefekkur/native_bridge", binaryMessenger: engineBridge.applicationRegistrar.messenger())
        self.nativeBridgeChannel = bridgeChannel
        bridgeChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "enableHourlyLockScreenVerse":
                if let args = call.arguments as? [String: Any] {
                    let ar = args["arabic"] as? String ?? ""
                    let tr = args["translation"] as? String ?? ""
                    let rf = args["reference"] as? String ?? ""
                    let source = args["source"] as? String ?? "auto"
                    let offset = args["offset"] as? Int ?? 0
                    UserDefaults.standard.set(source, forKey: "hourly_source")
                    UserDefaults.standard.set(ar, forKey: "hourly_arabic")
                    UserDefaults.standard.set(tr, forKey: "hourly_translation")
                    UserDefaults.standard.set(rf, forKey: "hourly_reference")
                    if let sh = UserDefaults(suiteName: "group.com.ilahi.tefekkur") {
                        sh.set(source, forKey: "hourly_source")
                        sh.set(ar, forKey: "hourly_arabic")
                        sh.set(tr, forKey: "hourly_translation")
                        sh.set(rf, forKey: "hourly_reference")
                        sh.set(offset, forKey: "hourly_manual_offset")
                        sh.synchronize()
                    }
                    if #available(iOS 14.0, *) {
#if canImport(WidgetKit)
WidgetCenter.shared.reloadAllTimelines()
#endif
}
                }
                result(true)
            case "getLocalTimeZone":
                result(TimeZone.current.identifier)
            case "openExternalUrl":
                if let args = call.arguments as? [String: Any], let uStr = args["url"] as? String, let u = URL(string: uStr) {
                    DispatchQueue.main.async { UIApplication.shared.open(u, options: [:], completionHandler: nil) }
                }
                result(true)
            default: result(true)
            }
        }
        let mChannel = FlutterMethodChannel(name: "com.ilahi.tefekkur/media", binaryMessenger: engineBridge.applicationRegistrar.messenger())
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

    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if #available(iOS 10.0, *) { UNUserNotificationCenter.current().delegate = self }
        configureBackgroundAudioSession()
        if #available(iOS 14.0, *) {
#if canImport(WidgetKit)
WidgetCenter.shared.reloadAllTimelines()
#endif
}
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
