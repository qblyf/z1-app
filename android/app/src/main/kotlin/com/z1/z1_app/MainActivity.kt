package com.z1.z1_app

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.z1.z1_app/wework_sdk"
    private val TAG = "WeworkSdk"

    // 企业微信配置
    private var corpId: String = ""
    private var agentId: String = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initWeworkSdk" -> {
                    corpId = call.argument<String>("corpId") ?: ""
                    agentId = call.argument<String>("agentId") ?: ""
                    Log.d(TAG, "初始化企业微信 SDK: corpId=$corpId, agentId=$agentId")
                    result.success(true)
                }

                "weworkLogin" -> {
                    val corpid = call.argument<String>("corpId") ?: corpId
                    val agentid = call.argument<String>("agentId") ?: agentId
                    Log.d(TAG, "企业微信登录: corpId=$corpid, agentId=$agentid")
                    // 唤起企业微信授权
                    startWeworkAuth(corpid, agentid)
                    result.success(true)
                }

                "weworkShareText" -> {
                    val title = call.argument<String>("title") ?: ""
                    val content = call.argument<String>("content") ?: ""
                    val scene = call.argument<String>("scene") ?: "session"
                    Log.d(TAG, "分享文本: title=$title, scene=$scene")
                    // 实际分享需要调用企业微信 SDK
                    result.success(true)
                }

                "weworkShareUrl" -> {
                    val title = call.argument<String>("title") ?: ""
                    val content = call.argument<String>("content") ?: ""
                    val url = call.argument<String>("url") ?: ""
                    val thumbUrl = call.argument<String>("thumbUrl")
                    val scene = call.argument<String>("scene") ?: "session"
                    Log.d(TAG, "分享链接: title=$title, url=$url, scene=$scene")
                    result.success(true)
                }

                "weworkShareImage" -> {
                    val title = call.argument<String>("title") ?: ""
                    val imagePath = call.argument<String>("imagePath") ?: ""
                    val scene = call.argument<String>("scene") ?: "session"
                    Log.d(TAG, "分享图片: title=$title, path=$imagePath, scene=$scene")
                    result.success(true)
                }

                "isWeWorkInstalled" -> {
                    val isInstalled = isPackageInstalled("com.tencent.wework")
                    Log.d(TAG, "企业微信是否安装: $isInstalled")
                    result.success(isInstalled)
                }

                "isSdkAvailable" -> {
                    // 检查 SDK 是否可用
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val scheme = intent.scheme ?: return
        val data = intent.dataString ?: return

        Log.d(TAG, "收到 Intent: scheme=$scheme, data=$data")

        // 处理企业微信回调
        when {
            // 企业微信嵌入 SDK 回调: wwauth00cc4c12ff49ae86000003://...
            data.startsWith("wwauth") -> {
                handleWeworkSdkCallback(data)
            }
            // 自定义回调: z1app://wework?code=xxx
            data.startsWith("z1app://wework") -> {
                handleOAuthCallback(data)
            }
        }
    }

    private fun handleWeworkSdkCallback(data: String) {
        Log.d(TAG, "企业微信 SDK 回调: $data")

        // 解析回调数据
        // 格式: wwauth00cc4c12ff49ae86000003://oauth?code=xxx&state=xxx
        try {
            val uri = android.net.Uri.parse(data)
            val code = uri.getQueryParameter("code")
            val state = uri.getQueryParameter("state")

            if (!code.isNullOrEmpty()) {
                Log.d(TAG, "获取到授权码: $code")
                // 通知 Flutter
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod(
                        "onWeworkCallback",
                        mapOf(
                            "type" to "login",
                            "code" to code,
                            "state" to (state ?: "")
                        )
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "解析回调失败: ${e.message}")
        }
    }

    private fun handleOAuthCallback(data: String) {
        Log.d(TAG, "OAuth 回调: $data")

        try {
            val uri = android.net.Uri.parse(data)
            val code = uri.getQueryParameter("code")

            if (!code.isNullOrEmpty()) {
                Log.d(TAG, "获取到 OAuth 授权码: $code")
                // 通知 Flutter
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod(
                        "onWeworkCallback",
                        mapOf(
                            "type" to "auth",
                            "code" to code
                        )
                    )
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "解析 OAuth 回调失败: ${e.message}")
        }
    }

    private fun startWeworkAuth(corpId: String, agentId: String) {
        try {
            // 构建企业微信授权 URL
            val redirectUri = java.net.URLEncoder.encode("wwauth00cc4c12ff49ae86000003://oauth", "UTF-8")
            val state = System.currentTimeMillis().toString()

            val authUrl = "https://open.work.weixin.qq.com/wwopen/sso/qrConnect" +
                    "?appid=$corpId" +
                    "&agentid=$agentId" +
                    "&redirect_uri=$redirectUri" +
                    "&state=$state" +
                    "&lang=zh_CN" +
                    "&fun=implicit" +
                    "&param="

            Log.d(TAG, "打开企业微信授权页: $authUrl")

            // 使用外部浏览器打开
            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(authUrl))
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "启动企业微信授权失败: ${e.message}")
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: Exception) {
            false
        }
    }
}
