// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
package app.burumy.burumy

import android.content.ComponentName
import android.content.pm.PackageManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Blocks screenshots and screen recording while a view-once photo or a
/// bubble is open (FLAG_SECURE: the screen shows black in captures).
class MainActivity : FlutterActivity() {
    private var phone: PhoneChannel? = null
    private var ai: AiChannel? = null
    private var translate: TranslateChannel? = null
    private var share: ShareChannel? = null

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        share?.handle(intent)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        phone?.onPermissionResult(requestCode, grantResults)
    }

    @Deprecated("FlutterActivity still routes results here")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: android.content.Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        phone?.onActivityResult(requestCode, resultCode == RESULT_OK, data)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        phone = PhoneChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        ai = AiChannel(flutterEngine.dartExecutor.binaryMessenger)
        translate = TranslateChannel(flutterEngine.dartExecutor.binaryMessenger)
        share = ShareChannel(this, flutterEngine.dartExecutor.binaryMessenger).also { it.handle(intent) }
        // App icon picker: one launcher alias on, the others off.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.burumy/icon").setMethodCallHandler { call, result ->
            if (call.method == "set") {
                val pick = (call.arguments as? String) ?: "green"
                for (k in listOf("green", "dark", "light", "mint", "buru", "burumi", "dugi", "duru", "mongi", "rumi", "logo_burrow", "logo_buzz", "logo_closedeye", "logo_lineb", "logo_nest")) {
                    val state = if (k == pick) PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                    packageManager.setComponentEnabledSetting(
                        ComponentName(packageName, "app.burumy.burumy.Icon" + k.replaceFirstChar { it.uppercase() }),
                        state,
                        PackageManager.DONT_KILL_APP,
                    )
                }
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.burumy/screen").setMethodCallHandler { call, result ->
            when (call.method) {
                "secure" -> {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
                "captured" -> result.success(false)
                else -> result.notImplemented()
            }
        }
    }
}
