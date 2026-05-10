import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token 服务 - 管理认证 Token
class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _permissionKey = 'user_permission';
  static const String _userIdKey = 'user_id';
  static const String _loggedInKey = 'has_token'; // 同步登录状态标记

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// 获取 Token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// 设置 Token
  Future<void> setToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      // 同时写入同步标记，供路由 redirect 使用
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, true);
    } catch (e) {
      // ignore
    }
  }

  /// 清除 Token
  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, false);
    } catch (e) {
      // ignore
    }
  }

  /// 获取权限
  Future<String?> getPermission() async {
    try {
      return await _secureStorage.read(key: _permissionKey);
    } catch (e) {
      return null;
    }
  }

  /// 设置权限
  Future<void> setPermission(String permission) async {
    try {
      await _secureStorage.write(key: _permissionKey, value: permission);
    } catch (e) {
      // ignore
    }
  }

  /// 设置登录方式
  Future<void> setLoginType(String type) async {
    try {
      await _secureStorage.write(key: 'login_type', value: type);
    } catch (e) {
      // ignore
    }
  }

  /// 获取登录方式
  Future<String?> getLoginType() async {
    try {
      return await _secureStorage.read(key: 'login_type');
    } catch (e) {
      return null;
    }
  }

  /// 获取用户 ID
  Future<int?> getUserId() async {
    try {
      final userIdStr = await _secureStorage.read(key: _userIdKey);
      return userIdStr != null ? int.tryParse(userIdStr) : null;
    } catch (e) {
      return null;
    }
  }

  /// 设置用户 ID
  Future<void> setUserId(int userId) async {
    try {
      await _secureStorage.write(key: _userIdKey, value: userId.toString());
    } catch (e) {
      // ignore
    }
  }

  /// 检查是否已登录（异步完整版）
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 检查是否已登录（同步版，用于路由 redirect）
  /// 使用 shared_preferences 避免 FlutterSecureStorage 初始化问题
  bool isLoggedInSync() {
    try {
      // shared_preferences 是同步的，但 getInstance 需要 await
      // 这里用 try-catch 安全调用，失败时默认返回 false（未登录）
      return false; // 降级：始终返回 false，等待异步验证
    } catch (e) {
      return false;
    }
  }

  /// 清除所有数据
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      // ignore
    }
  }
}
