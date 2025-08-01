import Flutter
import UIKit
import GoogleMaps
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure Google Maps with iOS key
    GMSServices.provideAPIKey("REMOVED_IOS_GOOGLE_MAPS_API_KEY")
    
    // Configure Google Sign-In
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "339865363997-hfjddn5s4j39ftiooc1jal6i78i5v9l6.apps.googleusercontent.com")
    
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
