import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// 权限包信息
class PermissionPackage {
  /// 权限包 key
  final String key;

  /// 权限 JWT（用于 Use-Permissions 请求头）
  final String? jwt;

  PermissionPackage({required this.key, this.jwt});

  factory PermissionPackage.fromJson(Map<String, dynamic> json) {
    return PermissionPackage(
      key: json['key'] as String,
      jwt: json['permissionsJWT'] as String?,
    );
  }
}

/// 权限 API 服务
class PermissionApi {
  final ApiClient _client = ApiClient();

  /// 批量获取权限包
  ///
  /// [keys] 权限包 key 列表，如 ['calendarManage', 'approvalManage']
  /// [token] 当前用户的 auth token（不走拦截器，避免循环依赖）
  Future<List<PermissionPackage>> grantPermissionPackages({
    required List<String> keys,
    required String token,
  }) async {
    final response = await _client.get(
      '/permission-package/batch-grant',
      queryParameters: {'keys': keys.join(',')},
      options: Options(
        headers: {
          'Authorization': token,
        },
      ),
    );
    final data = response.data;
    if (data['res'] == null || data['code'] != 10000) {
      throw Exception(data['message'] ?? '获取权限包失败');
    }
    final list = data['res'] as List;
    return list.map((e) => PermissionPackage.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取单个权限包
  ///
  /// [pagePath] 页面路径，如 'mobile /calendar'
  /// [token] 当前用户的 auth token
  Future<PermissionPackage?> grantPermissionByPagePath({
    required String pagePath,
    required String token,
  }) async {
    final response = await _client.get(
      '/permission-package/grant',
      queryParameters: {'pagePath': pagePath},
      options: Options(
        headers: {
          'Authorization': token,
        },
      ),
    );
    final data = response.data;
    if (data['res'] == null || data['code'] != 10000) {
      // 如果没有权限，返回 null 而不是抛异常
      debugPrint('获取页面权限失败: ${data['message']}');
      return null;
    }
    final res = data['res'] as Map<String, dynamic>;
    return PermissionPackage(
      key: res['key'] as String? ?? '',
      jwt: res['permissionsJWT'] as String?,
    );
  }
}
