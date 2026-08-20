import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    registerTimezoneChannel()
    return launched
  }

  private func registerTimezoneChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "flutter_native_timezone",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getLocalTimezone":
        result(TimeZone.current.identifier)
      case "openNotificationSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
          result(nil)
        } else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "Cannot open notification settings",
              details: nil
            )
          )
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
