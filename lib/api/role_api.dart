import 'api_client.dart';
import '../models/role.dart';

/// 角色 API
/// 对应后端 /role/* 系列接口
class RoleApi {
  final ApiClient _client = ApiClient();

  /// 获取角色列表
  /// GET /role/list
  Future<List<Role>> list() async {
    final res = await _client.get('/role/list');
    final result = res.data['list'] as List<dynamic>? ?? [];
    return result
        .map((e) => Role.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
