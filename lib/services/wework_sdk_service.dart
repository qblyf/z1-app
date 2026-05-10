import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 企业微信嵌入 SDK 服务
///
/// 支持一键登录、内容分享等功能
class WeworkSdkService {
  static final WeworkSdkService _instance = WeworkSdkService._internal();
  factory WeworkSdkService() => _instance;
  WeworkSdkService._internal();

  static const MethodChannel _channel = MethodChannel('com.z1.z1_app/wework_sdk');

  // 企业微信配置
  static const String _corpId = 'ww00cc4c12ff49ae86';
  static const String _agentId = '1000003';

  /// 回调监听器
  final _callbackController = StreamController<WeworkCallback>.broadcast();
  Stream<WeworkCallback> get onCallback => _callbackController.stream;

  /// 初始化企业微信 SDK
  /// 注意: 嵌入 SDK 仅支持 Android 和 iOS 真机，macOS 模拟器会抛出异常
  Future<void> init() async {
    try {
      await _channel.invokeMethod('initWeworkSdk', {
        'corpId': _corpId,
        'agentId': _agentId,
      });
    } on PlatformException catch (e) {
      // macOS 模拟器不支持企业微信 SDK，这是预期行为
      // 静默忽略，让调用方通过 isSdkAvailable() 判断
      debugPrint('企业微信 SDK 初始化跳过（模拟器或未安装）: ${e.message}');
      return;
    }

    // 设置方法通道回调监听
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// 处理来自 Native 的回调
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onWeworkCallback':
        _handleCallback(call.arguments as Map<dynamic, dynamic>);
        break;
      case 'onShareSuccess':
        _callbackController.add(WeworkCallback.shareSuccess());
        break;
      case 'onShareFailed':
        _callbackController.add(WeworkCallback.shareFailed(call.arguments['error'] ?? '未知错误'));
        break;
    }
  }

  /// 处理回调数据
  void _handleCallback(Map<dynamic, dynamic> data) {
    final type = data['type'] as String?;
    final code = data['code'] as String?;
    final state = data['state'] as String?;
    final error = data['error'] as String?;

    switch (type) {
      case 'login':
        if (code != null) {
          _callbackController.add(WeworkCallback.loginSuccess(code: code, state: state));
        } else if (error != null) {
          _callbackController.add(WeworkCallback.loginFailed(error));
        }
        break;
      case 'auth':
        if (code != null) {
          _callbackController.add(WeworkCallback.authSuccess(code: code));
        } else if (error != null) {
          _callbackController.add(WeworkCallback.authFailed(error));
        }
        break;
    }
  }

  /// 企业微信一键登录
  Future<void> login() async {
    try {
      await _channel.invokeMethod('weworkLogin', {
        'corpId': _corpId,
        'agentId': _agentId,
      });
    } on PlatformException catch (e) {
      throw Exception('企业微信登录失败: ${e.message}');
    }
  }

  /// 分享文本到企业微信
  Future<void> shareText({
    required String title,
    required String content,
    String? scene, // "session" | "timeline" | "favorite"
  }) async {
    try {
      await _channel.invokeMethod('weworkShareText', {
        'title': title,
        'content': content,
        'scene': scene ?? 'session',
      });
    } on PlatformException catch (e) {
      throw Exception('分享失败: ${e.message}');
    }
  }

  /// 分享链接到企业微信
  Future<void> shareUrl({
    required String title,
    required String content,
    required String url,
    String? thumbUrl,
    String? scene,
  }) async {
    try {
      await _channel.invokeMethod('weworkShareUrl', {
        'title': title,
        'content': content,
        'url': url,
        'thumbUrl': thumbUrl,
        'scene': scene ?? 'session',
      });
    } on PlatformException catch (e) {
      throw Exception('分享失败: ${e.message}');
    }
  }

  /// 分享图片到企业微信
  Future<void> shareImage({
    required String title,
    required String imagePath,
    String? scene,
  }) async {
    try {
      await _channel.invokeMethod('weworkShareImage', {
        'title': title,
        'imagePath': imagePath,
        'scene': scene ?? 'session',
      });
    } on PlatformException catch (e) {
      throw Exception('分享失败: ${e.message}');
    }
  }

  /// 检查企业微信是否安装
  Future<bool> isWeWorkInstalled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isWeWorkInstalled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 检查企业微信 SDK 是否可用
  Future<bool> isSdkAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSdkAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 销毁资源
  void dispose() {
    _callbackController.close();
  }
}

/// 企业微信回调事件
class WeworkCallback {
  final String type;
  final String? code;
  final String? state;
  final String? error;

  WeworkCallback._({
    required this.type,
    this.code,
    this.state,
    this.error,
  });

  factory WeworkCallback.loginSuccess({required String code, String? state}) {
    return WeworkCallback._(type: 'login_success', code: code, state: state);
  }

  factory WeworkCallback.loginFailed(String error) {
    return WeworkCallback._(type: 'login_failed', error: error);
  }

  factory WeworkCallback.authSuccess({required String code}) {
    return WeworkCallback._(type: 'auth_success', code: code);
  }

  factory WeworkCallback.authFailed(String error) {
    return WeworkCallback._(type: 'auth_failed', error: error);
  }

  factory WeworkCallback.shareSuccess() {
    return WeworkCallback._(type: 'share_success');
  }

  factory WeworkCallback.shareFailed(String error) {
    return WeworkCallback._(type: 'share_failed', error: error);
  }

  @override
  String toString() {
    return 'WeworkCallback(type: $type, code: $code, state: $state, error: $error)';
  }
}
