import 'package:z1_app/api/api_client.dart';
import '../models/discount_log.dart';

/// 折扣日志 API
class DiscountLogApi {
  final ApiClient _client = ApiClient();

  /// 获取折扣审批订单详情
  /// 后端 GET /discount-log/approval-detail?zid=X
  Future<List<DiscountLog>> getApprovalDetail(String zid) async {
    final response = await _client.get(
      '/discount-log/approval-detail',
      queryParameters: {'zid': zid},
    );
    final data = response.data;
    final res = data['res'];
    if (res is List) {
      return res
          .map((e) => DiscountLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取折扣日志列表
  /// 后端 GET /discount-log/list
  Future<List<DiscountLog>> getList({
    List<int>? states,
    List<String>? mallNumbers,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client.get(
      '/discount-log/list',
      queryParameters: {
        if (states != null) 'states': states.join(','),
        if (mallNumbers != null) 'mallNumbers': mallNumbers.join(','),
        'limit': limit,
        'offset': offset,
      },
    );
    final data = response.data;
    final res = data['res'];
    if (res is List) {
      return res
          .map((e) => DiscountLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取折扣日志总数
  /// 后端 GET /discount-log/count
  Future<int> getCount({
    List<int>? states,
    List<String>? mallNumbers,
  }) async {
    final response = await _client.get(
      '/discount-log/count',
      queryParameters: {
        if (states != null) 'states': states.join(','),
        if (mallNumbers != null) 'mallNumbers': mallNumbers.join(','),
      },
    );
    final data = response.data;
    final res = data['res'];
    return (res is num) ? res.toInt() : 0;
  }

  /// 折扣信息审核通过
  /// 后端 POST /discount-log/audit
  /// 参数: { logIDs: number[] }
  Future<bool> audit(List<int> logIDs) async {
    final response = await _client.post(
      '/discount-log/audit',
      data: {'logIDs': logIDs},
    );
    return response.data['res'] == 1 || response.data['res'] == true;
  }

  /// 折扣信息审核拒绝
  /// 后端 POST /discount-log/reject
  /// 参数: { logIDs: number[] }
  Future<bool> reject(List<int> logIDs) async {
    final response = await _client.post(
      '/discount-log/reject',
      data: {'logIDs': logIDs},
    );
    return response.data['res'] == 1 || response.data['res'] == true;
  }

  /// 撤销折扣日志
  /// 后端 POST /discount-log/revoke
  /// 参数: { logID: number }
  Future<bool> revoke(int logID) async {
    final response = await _client.post(
      '/discount-log/revoke',
      data: {'logID': logID},
    );
    return response.data['res'] == 1 || response.data['res'] == true;
  }

  /// 折扣金额统计
  /// 后端 GET /discount-log/statistic
  Future<Map<String, dynamic>> statistic({
    List<int>? departmentIDs,
    int? minTime,
    int? maxTime,
  }) async {
    final response = await _client.get(
      '/discount-log/statistic',
      queryParameters: {
        if (departmentIDs != null) 'departmentIDs': departmentIDs.join(','),
        if (minTime != null) 'minTime': minTime,
        if (maxTime != null) 'maxTime': maxTime,
      },
    );
    return response.data['res'] as Map<String, dynamic>? ?? {};
  }
}
