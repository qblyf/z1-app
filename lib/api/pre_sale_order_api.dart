import 'api_client.dart';
import '../models/pre_sale_order.dart';

/// 预售订单 API
/// 对应后端 z1func/pre-sale-order-* 系列接口
class PreSaleOrderApi {
  final ApiClient _client = ApiClient();

  // ================================================================
  // 查询
  // ================================================================

  /// 预售订单列表
  /// GET /pre-sale-order/list
  Future<List<PreSaleOrder>> list({
    List<int>? departments,
    List<String>? status,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{};
    if (departments != null && departments.isNotEmpty) {
      queryParams['departments'] = departments;
    }
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    final res = await _client.get('/pre-sale-order/list',
        queryParameters: queryParams);
    final result = res.data['res'] as List<dynamic>? ?? [];
    return result
        .map((e) => PreSaleOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 预售订单总数
  /// GET /pre-sale-order/count
  Future<Map<String, int>> count({List<int>? departments}) async {
    final queryParams = <String, dynamic>{};
    if (departments != null && departments.isNotEmpty) {
      queryParams['departments'] = departments;
    }

    final res = await _client.get('/pre-sale-order/count',
        queryParameters: queryParams);
    final result = res.data['res'];
    if (result is Map<String, dynamic>) {
      return result.map((k, v) => MapEntry(k, v as int? ?? 0));
    }
    return {};
  }

  /// 预售订单详情
  /// GET /pre-sale-order/detail
  Future<PreSaleOrder?> detail(int id) async {
    final res = await _client.get('/pre-sale-order/detail',
        queryParameters: {'id': id});
    final result = res.data['res'] as List<dynamic>?;
    if (result == null || result.isEmpty) return null;
    return PreSaleOrder.fromJson(result[0] as Map<String, dynamic>);
  }

  // ================================================================
  // 操作
  // ================================================================

  /// 创建预售订单
  /// POST /pre-sale-order/add
  Future<bool> add({
    required int customer,
    required int activityProduct,
    required int amount,
    required int expandAmount,
    int? department,
    String? remarks,
    List<int>? products,
    List<int>? services,
    int? sharer,
  }) async {
    final data = <String, dynamic>{
      'customer': customer,
      'activityProduct': activityProduct,
      'amount': amount,
      'expandAmount': expandAmount,
    };
    if (department != null) data['department'] = department;
    if (remarks != null) data['remarks'] = remarks;
    if (products != null) data['products'] = products;
    if (services != null) data['services'] = services;
    if (sharer != null) data['sharer'] = sharer;

    final res = await _client.post('/pre-sale-order/add', data: data);
    return res.data['code'] == 10000;
  }

  /// 支付预售订单
  /// POST /pre-sale-order/pay
  Future<bool> pay(int id) async {
    final res = await _client.post('/pre-sale-order/pay', data: {'id': id});
    return res.data['code'] == 10000;
  }

  /// 完成预售订单（转商城单）
  /// POST /pre-sale-order/complete
  Future<bool> complete({
    required int id,
    required int preSaleProduct,
    List<int>? products,
    List<int>? services,
  }) async {
    final data = <String, dynamic>{
      'id': id,
      'preSaleProduct': preSaleProduct,
    };
    if (products != null) data['products'] = products;
    if (services != null) data['services'] = services;

    final res = await _client.post('/pre-sale-order/complete', data: data);
    return res.data['code'] == 10000;
  }

  /// 取消预售订单
  /// POST /pre-sale-order/cancel
  Future<bool> cancel(int id) async {
    final res =
        await _client.post('/pre-sale-order/cancel', data: {'id': id});
    return res.data['code'] == 10000;
  }

  /// 申请退款
  /// POST /pre-sale-order/apply-refund
  Future<bool> applyRefund({
    required int id,
    String? refundReason,
  }) async {
    final data = <String, dynamic>{'id': id};
    if (refundReason != null) data['refundReason'] = refundReason;

    final res =
        await _client.post('/pre-sale-order/apply-refund', data: data);
    return res.data['code'] == 10000;
  }

  /// 审核退款
  /// POST /pre-sale-order/audit-refund
  Future<bool> auditRefund(int id) async {
    final res =
        await _client.post('/pre-sale-order/audit-refund', data: {'id': id});
    return res.data['code'] == 10000;
  }

  /// 取消退款申请
  /// POST /pre-sale-order/cancel-refund
  Future<bool> cancelRefund(int id) async {
    final res =
        await _client.post('/pre-sale-order/cancel-refund', data: {'id': id});
    return res.data['code'] == 10000;
  }

  /// 拒绝退款
  /// POST /pre-sale-order/reject-refund
  Future<bool> rejectRefund(int id) async {
    final res =
        await _client.post('/pre-sale-order/reject-refund', data: {'id': id});
    return res.data['code'] == 10000;
  }

  /// 修改预售订单
  /// POST /pre-sale-order/edit
  Future<bool> edit({
    required int id,
    int? department,
    String? remarks,
    String? emplRemarks,
  }) async {
    final data = <String, dynamic>{'id': id};
    if (department != null) data['department'] = department;
    if (remarks != null) data['remarks'] = remarks;
    if (emplRemarks != null) data['emplRemarks'] = emplRemarks;

    final res = await _client.post('/pre-sale-order/edit', data: data);
    return res.data['code'] == 10000;
  }

  /// 切换部门
  /// POST /pre-sale-order/change-dept
  Future<bool> changeDept({
    required int id,
    required int department,
  }) async {
    final res = await _client.post('/pre-sale-order/change-dept', data: {
      'id': id,
      'department': department,
    });
    return res.data['code'] == 10000;
  }
}
