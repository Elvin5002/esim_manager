import Flutter
import UIKit
import Foundation

// CoreTelephony APIs may be used if available at runtime.
// We add them conditionally and use runtime checks to avoid compile/runtime issues on older SDKs.

extension UIDevice {
  var modelName: String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
      guard let value = element.value as? Int8, value != 0 else { return identifier }
      return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return identifier
  }
}

private func deviceSupportsEsim() -> Bool {
    let model = UIDevice.current.modelName

    let esimModels: [String] = [
      // iPhone XS / XS Max / XR (2018)
      "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8",

      // iPhone 11 / 11 Pro / 11 Pro Max (2019)
      "iPhone12,1", "iPhone12,3", "iPhone12,5",

      // iPhone SE 2nd gen (2020)
      "iPhone12,8",

      // iPhone 12 mini / 12 / 12 Pro / 12 Pro Max (2020)
      "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4",

      // iPhone 13 mini / 13 / 13 Pro / 13 Pro Max (2021)
      "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5",

      // iPhone SE 3rd gen (2022)
      "iPhone14,6",

      // iPhone 14 / 14 Plus (2022)
      "iPhone14,7", "iPhone14,8",

      // iPhone 14 Pro / 14 Pro Max (2022)
      "iPhone15,2", "iPhone15,3",

      // iPhone 15 / 15 Plus (2023)
      "iPhone15,4", "iPhone15,5",

      // iPhone 15 Pro / 15 Pro Max (2023)
      "iPhone16,1", "iPhone16,2",

      // iPhone 16 / 16 Plus (2024)
      "iPhone17,1", "iPhone17,2",

      // iPhone 16 Pro / 16 Pro Max (2024)
      "iPhone17,3", "iPhone17,4",

      // iPad Pro 11-inch 3rd gen (2021)
      "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7",

      // iPad Pro 12.9-inch 5th gen (2021)
      "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11",

      // iPad Air 5th gen (2022)
      "iPad13,16", "iPad13,17",

      // iPad Pro 11-inch 4th gen (2022)
      "iPad14,3", "iPad14,4",

      // iPad Pro 12.9-inch 6th gen (2022)
      "iPad14,5", "iPad14,6",

      // iPad 10th gen (2022)
      "iPad13,18", "iPad13,19",

      // iPad Air 6th gen (2024)
      "iPad14,8", "iPad14,9", "iPad14,10", "iPad14,11",

      // iPad Pro 11-inch 5th gen M4 (2024)
      "iPad16,3", "iPad16,4",

      // iPad Pro 13-inch M4 (2024)
      "iPad16,5", "iPad16,6",

      // iPad mini 7th gen (2024)
      "iPad16,1", "iPad16,2",
    ]

    return esimModels.contains(model)
  }

public class EsimManagerPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "esim_manager", binaryMessenger: registrar.messenger())
    let instance = EsimManagerPlugin(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    super.init()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isEsimSupported":
      result(isEsimSupported())

    case "listProfiles":
      // iOS: retrieving installed eSIM profiles programmatically is limited; return empty list or not implemented.
      result([Any]())

    case "removeProfile":
      // Requires system UI / entitlements; not implemented in plugin skeleton.
      result(false)

    case "getActiveProfile":
      result(NSNull())

    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "installEsim":
      guard let args = call.arguments as? [String: Any], let lpa = args["lpa"] as? String ?? args["activationCode"] as? String ?? args["lpaString"] as? String else {
        result(false)
        return
      }
      installEsimViaLpa(lpaString: lpa, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isEsimSupported() -> Bool {
    if #available(iOS 12.1, *) {
      // Check whether CTCellularPlanProvisioning class is available at runtime and device supports eSIM
      return NSClassFromString("CTCellularPlanProvisioning") != nil && deviceSupportsEsim()
    }
    return false
  }

  private func installEsimViaLpa(lpaString: String, result: @escaping FlutterResult) {
    // Construct Apple's official LPA provisioning URL
    let encoded = lpaString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? lpaString
    let urlString = "https://esimsetup.apple.com/esim_qrcode_provisioning?carddata=\(encoded)"
    guard let url = URL(string: urlString) else {
      result(false)
      return
    }

    DispatchQueue.main.async {
      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url, options: [:]) { success in
          result(success)
        }
      } else {
        result(false)
      }
    }
  }
}

