import 'api_client.dart';
import '../models/points_redeem_order.dart';

class PointsRedeemOrderApi {
  final _client = ApiClient();

  /// 用户积分兑换订单列表
  Future<List<PointsRedeemOrder>> userList({
    int limit = 20,
    int offset = 0,
    bool descending = true,
  }) async {
    final res = await _client.get(
      '/points-redeem/order/list/user',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'orderBy': [
          {'key': 'created_at', 'sort': descending ? 'DESC' : 'ASC'}
        ],
      },
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => PointsRedeemOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 兑换订单列表（通用）
  Future<List<PointsRedeemOrder>> list({
    PointsRedeemOrderStatus? status,
    int limit = 20,
    int offset = 0,
    bool descending = true,
  }) async {
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'orderBy': [
        {'key': 'created_at', 'sort': descending ? 'DESC' : 'ASC'}
      ],
    };
    if (status != null) body['status'] = status.value;

    final res = await _client.get('/points-redeem/order/list', queryParameters: body);
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => PointsRedeemOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 订单总数
  Future<int> count({PointsRedeemOrderStatus? status}) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status.value;

    final res = await _client.get('/points-redeem/order/count', queryParameters: body);
    return (res.data['res'] as int?) ?? 0;
  }

  /// 订单详情
  Future<PointsRedeemOrder?> detail(int id) async {
    final res = await _client.get('/points-redeem/order/detail', queryParameters: {'id': id});
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return PointsRedeemOrder.fromJson(data);
  }

  /// 审核通过退款（已支付状态的退款申请）
  /// 对应 PWA auditPointsRedeemOrderRefundApply
  Future<bool> auditRefund(int id) async {
    final res = await _client.post(
      '/points-redeem/order/audit-refund',
      data: {'id': id},
    );
    return res.data['code'] == 0;
  }

  /// 拒绝退款（取消退款申请）
  /// 对应 PWA rejectPointsRedeemOrderRefundApply
  Future<bool> rejectRefund(int id) async {
    final res = await _client.post(
      '/points-redeem/order/reject-refund',
      data: {'id': id},
    );
    return res.data['code'] == 0;
  }

  /// 添加备注
  /// 对应 PWA pointsRedeemOrderAddRemarks
  Future<bool> addRemarks(int id, String remarks) async {
    final res = await _client.post(
      '/points-redeem/order/add-remarks',
      data: {'id': id, 'remarks': remarks},
    );
    return res.data['code'] == 0;
  }
}
