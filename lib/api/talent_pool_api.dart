import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/talent_pool.dart';

/// 人才库 API 服务
/// 对接 z1-mid 后端 API
/// 特殊：使用 uuid 作为身份标识（不是 token），uuid 通过请求 header 传递
class TalentPoolApi {
  final ApiClient _client = ApiClient();

  /// 获取访客详情（人才池记录）
  /// GET /talent-pool/visitor/detail
  /// uuid 通过 header 传递（不是 query 参数）
  Future<TalentPool?> getVisitorDetail(String uuid) async {
    try {
      final response = await _client.get(
        '/talent-pool/visitor/detail',
        options: Options(
          headers: {'uuid': uuid},
        ),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final res = data['res'];
        if (res is Map<String, dynamic>) {
          return TalentPool.fromJson(res);
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  /// 编辑访客信息（人才池记录）
  /// POST /talent-pool/visitor/edit
  /// uuid 通过 header 传递，body 使用 pickDiff 只传变更字段
  Future<bool> editVisitorInfo(
    Map<String, dynamic> body,
    String uuid,
  ) async {
    final response = await _client.post(
      '/talent-pool/visitor/edit',
      data: body,
      options: Options(
        headers: {'uuid': uuid},
      ),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      // 后端返回 { code, res } 格式，res 为影响行数或布尔值
      final res = data['res'];
      if (res is bool) return res;
      if (res is int) return res > 0;
      return data['code'] == 0 || data['code'] == 200;
    }
    return false;
  }
}
