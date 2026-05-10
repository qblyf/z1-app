import 'api_client.dart';
import '../models/flash_sale_order.dart';

/// 秒杀订单 API
/// 对应后端 z1func/flash-sale-order-* 系列接口
/// 响应格式: { code: 10000, message: string, res: ... }
class FlashSaleOrderApi {
  final ApiClient _client = ApiClient();

  // ================================================================
  // 查询
  // ================================================================

  /// 职员端秒杀订单列表
  /// GET /flash-sale-order/emp-list
  Future<List<FlashSaleOrder>> empList({
    List<int>? numbers,
    String? number,
    List<int>? customers,
    int? department,
    List<String>? status,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? minPayAt,
    int? maxPayAt,
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (numbers != null && numbers.isNotEmpty) queryParams['numbers'] = numbers;
    if (number != null && number.isNotEmpty) queryParams['number'] = number;
    if (customers != null && customers.isNotEmpty) {
      queryParams['customers'] = customers;
    }
    if (department != null) queryParams['department'] = department;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;
    if (minPayAt != null) queryParams['minPayAt'] = minPayAt;
    if (maxPayAt != null) queryParams['maxPayAt'] = maxPayAt;

    final res = await _client.get('/flash-sale-order/emp-list',
        queryParameters: queryParams);
    final result = res.data['res'] as List<dynamic>? ?? [];
    return result
        .map((e) => FlashSaleOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 职员端秒杀订单总数
  /// GET /flash-sale-order/emp-count
  Future<int> empCount({
    List<int>? numbers,
    String? number,
    List<int>? customers,
    int? department,
    List<String>? status,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{};
    if (numbers != null && numbers.isNotEmpty) queryParams['numbers'] = numbers;
    if (number != null && number.isNotEmpty) queryParams['number'] = number;
    if (customers != null && customers.isNotEmpty) {
      queryParams['customers'] = customers;
    }
    if (department != null) queryParams['department'] = department;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get('/flash-sale-order/emp-count',
        queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }

  /// 秒杀订单详情
  /// GET /flash-sale-order/details
  Future<FlashSaleOrder?> detail(List<int> ids) async {
    if (ids.isEmpty) return null;
    final res = await _client.get('/flash-sale-order/details',
        queryParameters: {'ids': ids});
    final result = res.data['res'] as List<dynamic>?;
    if (result == null || result.isEmpty) return null;
    return FlashSaleOrder.fromJson(result[0] as Map<String, dynamic>);
  }

  /// 秒杀订单详情（通过ID）
  Future<FlashSaleOrder?> detailById(int id) async {
    return detail([id]);
  }

  // ================================================================
  // 状态操作
  // ================================================================

  /// 创建秒杀订单
  /// POST /flash-sale-order/add
  Future<bool> add({
    required int activityProduct,
    required int skuId,
    required int customer,
    String? transport,
    required int department,
    String? remarks,
    int? sharer,
  }) async {
    final data = <String, dynamic>{
      'activityProduct': activityProduct,
      'skuID': skuId,
      'customer': customer,
      'department': department,
    };
    if (transport != null) data['transport'] = transport;
    if (remarks != null) data['remarks'] = remarks;
    if (sharer != null) data['sharer'] = sharer;

    final res = await _client.post('/flash-sale-order/add', data: data);
    return res.data['code'] == 10000;
  }

  /// 取消秒杀订单
  /// POST /flash-sale-order/cancel
  Future<bool> cancel(List<int> ids) async {
    final res = await _client.post('/flash-sale-order/cancel', data: {
      'ids': ids,
    });
    return res.data['code'] == 10000;
  }

  /// 申请退款
  /// POST /flash-sale-order/apply-refund
  Future<bool> applyRefund({
    required int id,
    String? refundReason,
  }) async {
    final data = <String, dynamic>{'id': id};
    if (refundReason != null) data['refundReason'] = refundReason;

    final res = await _client.post('/flash-sale-order/apply-refund', data: data);
    return res.data['code'] == 10000;
  }

  /// 审核退款（同意退款）
  /// POST /flash-sale-order/audit-refund
  Future<bool> auditRefund(int id) async {
    final res = await _client.post('/flash-sale-order/audit-refund', data: {
      'id': id,
    });
    return res.data['code'] == 10000;
  }

  /// 取消退款申请
  /// POST /flash-sale-order/cancel-refund
  Future<bool> cancelRefund(int id) async {
    final res = await _client.post('/flash-sale-order/cancel-refund', data: {
      'id': id,
    });
    return res.data['code'] == 10000;
  }

  /// 拒绝退款
  /// POST /flash-sale-order/reject-refund
  Future<bool> rejectRefund(int id) async {
    final res = await _client.post('/flash-sale-order/reject-refund', data: {
      'id': id,
    });
    return res.data['code'] == 10000;
  }

  /// 处理秒杀单（转商城单）
  /// POST /flash-sale-order/add-mall-order
  Future<bool> addMallOrder(String flashOrderNumber) async {
    final res =
        await _client.post('/flash-sale-order/add-mall-order', data: {
      'flashOrderNumber': flashOrderNumber,
    });
    return res.data['code'] == 10000;
  }
}
