import 'package:flutter/foundation.dart';
import '../api/permission_api.dart';
import 'token_service.dart';

/// 权限服务 - 管理权限 JWT
class PermissionService {
  final PermissionApi _api = PermissionApi();
  final TokenService _tokenService = TokenService();

  /// 权限包 key 到 JWT 的缓存
  final Map<String, String> _cache = {};

  /// 获取权限 JWT，如果缓存中有直接返回，否则从后端获取
  Future<String?> getPermissionJwt(String key) async {
    // 先从缓存获取
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    // 从后端获取
    final token = await _tokenService.getToken();
    if (token == null) return null;

    try {
      final pkg = await _api.grantPermissionByPagePath(
        pagePath: key,
        token: token,
      );
      if (pkg?.jwt != null) {
        _cache[key] = pkg!.jwt!;
        // 同时保存到 TokenService（会被 ApiClient 拦截器读取）
        await _tokenService.setPermission(pkg.jwt!);
        return pkg.jwt;
      }
    } catch (e) {
      debugPrint('获取权限失败: $e');
    }
    return null;
  }

  /// 批量获取权限包
  ///
  /// 获取成功后会自动保存到 TokenService（ApiClient 拦截器会读取）
  Future<void> fetchPermissionPackages(List<String> keys) async {
    final token = await _tokenService.getToken();
    if (token == null) return;

    try {
      final packages = await _api.grantPermissionPackages(
        keys: keys,
        token: token,
      );
      String? firstJwt;
      for (final pkg in packages) {
        if (pkg.jwt != null) {
          _cache[pkg.key] = pkg.jwt!;
          firstJwt ??= pkg.jwt;
        }
      }
      // 保存第一个权限 JWT 到 TokenService（供 ApiClient 拦截器使用）
      if (firstJwt != null) {
        await _tokenService.setPermission(firstJwt);
      }
      debugPrint('已获取 ${packages.length} 个权限包');
    } catch (e) {
      debugPrint('批量获取权限失败: $e');
    }
  }

  /// 清除缓存
  void clearCache() {
    _cache.clear();
  }

  /// 从缓存中同步获取 JWT（供 ApiClient 拦截器使用）
  String? getCachedJwt(String key) => _cache[key];
}

