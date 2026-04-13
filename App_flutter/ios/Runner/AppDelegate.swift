import Flutter
import UIKit
import GoogleMaps
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  private func requiredConfigValue(forKey key: String) -> String {
    guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
          !value.isEmpty,
          !value.contains("$(") else {
      fatalError("Missing \(key) in Info.plist")
    }
    return value
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Google Maps with a local build setting.
    GMSServices.provideAPIKey(requiredConfigValue(forKey: "GOOGLE_MAPS_API_KEY"))
    
    // Configure Google Sign-In from Info.plist to avoid duplicate literals.
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(
      clientID: requiredConfigValue(forKey: "GIDClientID")
    )
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    var handled: Bool

    handled = GIDSignIn.sharedInstance.handle(url)
    if handled {
      return true
    }

    // Handle other custom URL types.
    return false
  }
}
