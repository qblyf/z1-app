import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// 登录状态
enum LoginStatus {
  pending, // 等待扫码
  scanned, // 已扫码，等待确认
  complete, // 登录完成
  expired, // 二维码过期
  failed, // 登录失败
}

/// 轮询结果
class PollResult {
  final LoginStatus status;
  final String? token;
  final String? userName;
  final String? message;

  PollResult({
    required this.status,
    this.token,
    this.userName,
    this.message,
  });
}

/// 登录服务 - 使用二维码扫码登录
class LoginService {
  static final LoginService _instance = LoginService._internal();
  factory LoginService() => _instance;
  LoginService._internal();

  final _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
  final _storage = const FlutterSecureStorage();

  /// 登录 token 的 key
  static const String _tokenKey = 'z1_token';

  /// 获取登录二维码 URL
  String getQrCodeUrl(String uuid) {
    // 使用 z1-pwa 的企业微信确认登录页面
    const baseUrl = 'https://z1-fun.zsqk.com.cn/staff-portal-mobile/confirm-login/login';
    return '$baseUrl?uuid=$uuid';
  }

  /// 生成新的 UUID
  String generateUuid() {
    // 使用简单的 UUID 格式
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${now.toRadixString(16)}-${random.toRadixString(16)}';
  }

  /// 轮询登录状态
  Future<PollResult> pollLoginStatus(String uuid) async {
    try {
      final response = await _dio.get(
        '/z1func/air-login/get-token',
        queryParameters: {'uuid': uuid},
      );

      final data = response.data;
      final res = data['res'];

      if (res == null) {
        return PollResult(
          status: LoginStatus.failed,
          message: '获取登录状态失败',
        );
      }

      final status = res['status'] as String?;

      if (status == 'complete') {
        // 登录完成
        final token = res['token'] as String?;
        if (token != null) {
          await saveToken(token);
          return PollResult(
            status: LoginStatus.complete,
            token: token,
          );
        }
        return PollResult(
          status: LoginStatus.failed,
          message: '未获取到有效的 token',
        );
      } else if (status == 'pending') {
        // 等待扫码
        final scanner = res['scanner'];
        if (scanner != null) {
          final name = scanner['name'] as String?;
          return PollResult(
            status: LoginStatus.scanned,
            userName: name,
          );
        }
        return PollResult(
          status: LoginStatus.pending,
        );
      }

      return PollResult(
        status: LoginStatus.pending,
      );
    } on DioException catch (e) {
      debugPrint('轮询登录状态失败: ${e.message}');
      return PollResult(
        status: LoginStatus.failed,
        message: '网络错误: ${e.message}',
      );
    } catch (e) {
      debugPrint('轮询登录状态异常: $e');
      return PollResult(
        status: LoginStatus.failed,
        message: '未知错误',
      );
    }
  }

  /// 保存 token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    debugPrint('已保存登录 token');
  }

  /// 获取保存的 token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// 清除 token
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    debugPrint('已清除登录 token');
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 通过企业微信 OAuth code 登录（备用方案）
  Future<String?> loginByWechatWorkCode(String code) async {
    try {
      final response = await _dio.post(
        '/z1func/members/qywechat-code-token',
        data: {'code': code},
      );

      final data = response.data;
      final token = data['res'] as String?;

      if (token != null) {
        await saveToken(token);
        return token;
      }

      return null;
    } catch (e) {
      debugPrint('企业微信 code 登录失败: $e');
      return null;
    }
  }
}
