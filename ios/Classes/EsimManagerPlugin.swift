import Flutter
import UIKit
import Foundation

// CoreTelephony APIs may be used if available at runtime.
// We add them conditionally and use runtime checks to avoid compile/runtime issues on older SDKs.

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

    case "installFromActivationCode":
      guard let args = call.arguments as? [String: Any], let activationCode = args["activationCode"] as? String else {
        result(["status": "failed", "message": "activationCode missing"])
        return
      }
      installFromActivationCode(activationCode: activationCode, result: result)

    case "installFromSmDp":
      guard let args = call.arguments as? [String: Any], let smdpUrl = args["smdpUrl"] as? String else {
        result(["status": "failed", "message": "smdpUrl missing"])
        return
      }
      let confirmationCode = args["confirmationCode"] as? String
      installFromSmDp(smdpUrl: smdpUrl, confirmationCode: confirmationCode, result: result)

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

    case "installIosViaLpa":
      guard let args = call.arguments as? [String: Any], let lpa = args["lpaString"] as? String else {
        result(false)
        return
      }
      installIosViaLpa(lpaString: lpa, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func isEsimSupported() -> Bool {
    if #available(iOS 12.1, *) {
      // Check whether CTCellularPlanProvisioning class is available at runtime
      return NSClassFromString("CTCellularPlanProvisioning") != nil
    }
    return false
  }

  private func installFromActivationCode(activationCode: String, result: @escaping FlutterResult) {
    guard isEsimSupported() else {
      result(["status": "failed", "message": "eSIM not supported on this device or iOS version < 12.1"])
      return
    }

    // Attempt to perform provisioning using CTCellularPlanProvisioning via runtime selectors so this code
    // compiles against older SDKs and only runs when the classes/methods exist at runtime.
    guard let provClass = NSClassFromString("CTCellularPlanProvisioning"),
          let reqClass = NSClassFromString("CTCellularPlanProvisioningRequest") as? NSObject.Type else {
      result(["status": "failed", "message": "CTCellularPlanProvisioning classes not available at runtime"])
      return
    }

    // Build request using KVC (best-effort: set activationCode if supported)
    let request = reqClass.init()
    do {
      try request.setValue(activationCode, forKey: "activationCode")
    } catch {
      // ignore if KVC is not supported — we'll still try to call addPlan
    }

    // Instantiate provisioning
    let provisioning = (provClass as! NSObject.Type).init()

    // Prepare to call addPlanWith:completionHandler:
    let selector = NSSelectorFromString("addPlanWith:completionHandler:")
    if provisioning.responds(to: selector) {
      let block: @convention(block) (Bool, Any?) -> Void = { accepted, err in
        var res: [String: Any] = [:]
        if let error = err as? NSError {
          res["status"] = "failed"
          res["message"] = error.localizedDescription
        } else {
          res["status"] = accepted ? "success" : "failed"
          res["message"] = accepted ? "user accepted" : "user declined"
        }
        // Send callback to Dart via method channel
        self.channel.invokeMethod("onInstallResult", arguments: ["requestId": "ios:", "result": res])
      }

      let imp = provisioning.method(for: selector)
      typealias Func = @convention(c) (AnyObject, Selector, AnyObject, @escaping @convention(block) (Bool, Any?) -> Void) -> Void
      let f = unsafeBitCast(imp, to: Func.self)
      f(provisioning, selector, request, block)

      result(["status": "pending", "message": "started", "requestId": "ios:"])
    } else {
      result(["status": "failed", "message": "addPlanWith:completionHandler: not available on this iOS build"])
    }
  }

  private func installFromSmDp(smdpUrl: String, confirmationCode: String?, result: @escaping FlutterResult) {
    guard isEsimSupported() else {
      result(["status": "failed", "message": "eSIM not supported on this device or iOS version < 12.1"])
      return
    }

    guard let provClass = NSClassFromString("CTCellularPlanProvisioning"),
          let reqClass = NSClassFromString("CTCellularPlanProvisioningRequest") as? NSObject.Type else {
      result(["status": "failed", "message": "CTCellularPlanProvisioning classes not available at runtime"])
      return
    }

    let request = reqClass.init()
    // KVC: set SM‑DP address and confirmation code if supported
    do {
      try request.setValue(smdpUrl, forKey: "smdpAddress")
      if let code = confirmationCode { try request.setValue(code, forKey: "confirmationCode") }
    } catch {
      // ignore if KVC not supported; still try to call addPlan
    }

    let provisioning = (provClass as! NSObject.Type).init()
    let selector = NSSelectorFromString("addPlanWith:completionHandler:")
    if provisioning.responds(to: selector) {
      let block: @convention(block) (Bool, Any?) -> Void = { accepted, err in
        var res: [String: Any] = [:]
        if let error = err as? NSError {
          res["status"] = "failed"
          res["message"] = error.localizedDescription
        } else {
          res["status"] = accepted ? "success" : "failed"
          res["message"] = accepted ? "user accepted" : "user declined"
        }
        self.channel.invokeMethod("onInstallResult", arguments: ["requestId": "ios:", "result": res])
      }

      let imp = provisioning.method(for: selector)
      typealias Func = @convention(c) (AnyObject, Selector, AnyObject, @escaping @convention(block) (Bool, Any?) -> Void) -> Void
      let f = unsafeBitCast(imp, to: Func.self)
      f(provisioning, selector, request, block)

      result(["status": "pending", "message": "started", "requestId": "ios:"])
    } else {
      result(["status": "failed", "message": "addPlanWith:completionHandler: not available on this iOS build"])
    }
  }

  private func installIosViaLpa(lpaString: String, result: @escaping FlutterResult) {
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

