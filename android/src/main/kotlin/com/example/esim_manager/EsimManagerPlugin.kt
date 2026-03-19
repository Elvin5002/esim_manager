package com.example.esim_manager

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.telephony.euicc.EuiccManager
import android.telephony.euicc.DownloadableSubscription
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** EsimManagerPlugin */
class EsimManagerPlugin: FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "esim_manager")
    context = binding.applicationContext
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "isEsimSupported" -> {
        val supported = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          val euicc = context.getSystemService(EuiccManager::class.java)
          euicc != null && try { euicc.isEnabled } catch (e: Throwable) { false }
        } else {
          false
        }
        result.success(supported)
      }

      "listProfiles" -> {
        // Placeholder: real implementation requires EuiccManager APIs and device support
        result.success(emptyList<Map<String, Any>>())
      }

      "installEsim" -> {
        val lpa = call.argument<String>("lpa") ?: ""
        if (lpa.isEmpty()) {
          result.success(mapOf("status" to "failed", "message" to "lpa empty"))
          return
        }
        if (activity != null) {
          val success = installViaUniversalLink(activity!!, lpa)
          result.success(success)
        } else {
          result.success(false)
        }
      }

      "removeProfile" -> {
        // Placeholder: requires carrier/system permissions
        result.success(false)
      }

      "getActiveProfile" -> {
        // Placeholder: would return active profile details
        result.success(null)
      }

      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }

      else -> result.notImplemented()
    }
  }

  private fun installViaUniversalLink(activity: Activity, lpa: String): Boolean {
    val lpaCode = if (lpa.startsWith("LPA:")) lpa else "LPA:$lpa"
    val url = "https://esimsetup.android.com/esim_qrcode_provisioning?carddata=${Uri.encode(lpaCode)}"
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))

    return try {
      activity.startActivity(intent)
      logWithTimestamp("eSIM-Install", "eSIM launched universal link for system installer")
      true
    } catch (e: Exception) {
      logWithTimestamp("eSIM-Install", "eSIM universal link failed: ${e.message}")
      false
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun logWithTimestamp(tag: String, message: String) {
    val timestamp = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", java.util.Locale.US).format(java.util.Date())
    android.util.Log.d(tag, "[$timestamp] $message")
  }
}
