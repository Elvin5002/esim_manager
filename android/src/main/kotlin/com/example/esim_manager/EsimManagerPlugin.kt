package com.example.esim_manager

import android.content.Context
import android.os.Build
import android.telephony.euicc.EuiccManager
import android.telephony.euicc.DownloadableSubscription
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** EsimManagerPlugin */
class EsimManagerPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

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

      "installFromActivationCode" -> {
        val activationCode = call.argument<String>("activationCode") ?: ""
        if (activationCode.isEmpty()) {
          result.success(mapOf("status" to "failed", "message" to "activationCode empty", "profileId" to null))
          return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          try {
            val euicc = context.getSystemService(EuiccManager::class.java)
            val ds = try {
              DownloadableSubscription.createFromActivationCode(activationCode)
            } catch (e: Throwable) {
              result.success(mapOf("status" to "failed", "message" to "invalid activation code: ${e.message}", "profileId" to null))
              return
            }

            val requestId = startDownload(euicc, ds, result)
            if (requestId == null) {
              result.success(mapOf("status" to "failed", "message" to "download failed to start", "profileId" to null))
            } else {
              result.success(mapOf("status" to "pending", "message" to "started", "profileId" to null, "requestId" to requestId))
            }
          } catch (e: SecurityException) {
            result.success(mapOf("status" to "failed", "message" to "SecurityException: ${e.message}", "profileId" to null))
          } catch (e: Throwable) {
            result.success(mapOf("status" to "failed", "message" to "error: ${e.message}", "profileId" to null))
          }
        } else {
          result.success(mapOf("status" to "failed", "message" to "Android API < 29 not supported", "profileId" to null))
        }
      }

      "installFromSmDp" -> {
        val smdpUrl = call.argument<String>("smdpUrl") ?: ""
        val confirmationCode = call.argument<String>("confirmationCode")
        if (smdpUrl.isEmpty()) {
          result.success(mapOf("status" to "failed", "message" to "smdpUrl empty", "profileId" to null))
          return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          try {
            val euicc = context.getSystemService(EuiccManager::class.java)

            val ds = buildDownloadableFromSmDp(smdpUrl, confirmationCode)

            if (ds == null) {
              result.success(mapOf("status" to "failed", "message" to "unable to construct DownloadableSubscription from SM-DP+", "profileId" to null))
              return
            }

            val requestId = startDownload(euicc, ds, result)
            if (requestId == null) {
              result.success(mapOf("status" to "failed", "message" to "download failed to start", "profileId" to null))
            } else {
              result.success(mapOf("status" to "pending", "message" to "started", "profileId" to null, "requestId" to requestId))
            }

          } catch (e: SecurityException) {
            result.success(mapOf("status" to "failed", "message" to "SecurityException: ${e.message}", "profileId" to null))
          } catch (e: Throwable) {
            result.success(mapOf("status" to "failed", "message" to "error: ${e.message}", "profileId" to null))
          }
        } else {
          result.success(mapOf("status" to "failed", "message" to "Android API < 29 not supported", "profileId" to null))
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

  private fun buildDownloadableFromSmDp(smdpUrl: String, confirmationCode: String?): DownloadableSubscription? {
    try {
      val dsBuilderClass = Class.forName("android.telephony.euicc.DownloadableSubscription").getDeclaredClasses().firstOrNull { it.simpleName == "Builder" }
      if (dsBuilderClass != null) {
        val builder = dsBuilderClass.getConstructor().newInstance()
        try {
          val setSmdp = dsBuilderClass.getMethod("setSmdpAddress", String::class.java)
          setSmdp.invoke(builder, smdpUrl)
        } catch (_: Exception) {}
        try {
          val setConfirmationCode = dsBuilderClass.getMethod("setConfirmationCode", String::class.java)
          if (confirmationCode != null) setConfirmationCode.invoke(builder, confirmationCode)
        } catch (_: Exception) {}
        val buildMethod = dsBuilderClass.getMethod("build")
        return buildMethod.invoke(builder) as? DownloadableSubscription
      }
    } catch (e: Throwable) {
      // ignore and fallthrough
    }
    return null
  }

  private fun startDownload(euicc: EuiccManager, ds: DownloadableSubscription, result: MethodChannel.Result): String? {
    val action = "com.example.esim_manager.DOWNLOAD_RESULT_${System.currentTimeMillis()}"
    val filter = android.content.IntentFilter(action)

    val receiver = object : android.content.BroadcastReceiver() {
      override fun onReceive(context: Context?, intent: android.content.Intent?) {
        val extras = intent?.extras
        val mapResult = HashMap<String, Any?>()
        extras?.keySet()?.forEach { key -> mapResult[key] = extras.get(key) }

        channel.invokeMethod("onInstallResult", mapOf("requestId" to action, "result" to mapResult))

        try {
          context?.unregisterReceiver(this)
        } catch (_: Exception) {}
      }
    }

    context.registerReceiver(receiver, filter)

    val intent = android.content.Intent(action)
    val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
      android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
    } else {
      android.app.PendingIntent.FLAG_UPDATE_CURRENT
    }
    val pendingIntent = android.app.PendingIntent.getBroadcast(context, 0, intent, flags)

    return try {
      euicc.downloadSubscription(ds, false, pendingIntent)
      action
    } catch (e: SecurityException) {
      try { context.unregisterReceiver(receiver) } catch (_: Exception) {}
      null
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
