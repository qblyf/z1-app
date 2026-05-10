import 'package:z1_app/api/api_client.dart';
import '../models/order.dart';

/// 订单 API 服务
/// 与 z1-mid 后端 API 对接
///
/// genre 参数对应后端 SalesMode（数字）:
/// - 1: 店内零售
/// - 2: 网销
/// - 3: 批发
/// - 4: 维修
class OrderApi {
  final ApiClient _client = ApiClient();

  /// 获取订单列表
  /// 后端 GET /order/list，返回 { code, res: { res: [...] } }
  Future<List<Order>> getList({
    String? orderBy,
    int? status,
    int? department,
    int? sellerIdent,
    int? handlerIdent,
    int? customerIdent,
    int? genre,
    int? type,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (orderBy != null) 'orderBy': orderBy,
      if (status != null) 'status': status,
      if (department != null) 'department': department,
      if (sellerIdent != null) 'sellerIdent': sellerIdent,
      if (handlerIdent != null) 'handlerIdent': handlerIdent,
      if (customerIdent != null) 'customerIdent': customerIdent,
      if (genre != null) 'genre': genre,
      if (type != null) 'type': type,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get(
      '/order/list',
      queryParameters: queryParams,
    );

    final data = response.data;
    // 后端返回 { code, res: { res: [...] } }，需取嵌套的 res
    final res = (data['res'] as Map<String, dynamic>?)?['res'];
    if (res is List) {
      return res.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取订单详情
  /// 后端 GET /order/detail
  Future<Order> getDetail(String orderNumber) async {
    final response = await _client.get(
      '/order/detail',
      queryParameters: {'p': orderNumber},
    );

    final data = response.data;
    return Order.fromJson(data['res'] as Map<String, dynamic>);
  }

  /// 获取订单总数
  /// 后端 GET /order/count，返回 { code, res: { res: N } }
  Future<int> getCount({
    int? status,
    int? department,
    int? sellerIdent,
    int? handlerIdent,
    int? customerIdent,
    int? genre,
    int? type,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      if (department != null) 'department': department,
      if (sellerIdent != null) 'sellerIdent': sellerIdent,
      if (handlerIdent != null) 'handlerIdent': handlerIdent,
      if (customerIdent != null) 'customerIdent': customerIdent,
      if (genre != null) 'genre': genre,
      if (type != null) 'type': type,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };

    final response = await _client.get(
      '/order/count',
      queryParameters: queryParams,
    );

    final data = response.data;
    // 后端返回 { code, res: { res: N } }
    final res = (data['res'] as Map<String, dynamic>?)?['res'];
    return res as int? ?? 0;
  }

  /// 根据用户和类型获取订单（代下单订单一览表）
  /// 后端 GET /order/genre/customer，返回 { code, list: [...] }
  Future<List<Order>> getByUserAndGenre({
    required int userIdent,
    String? genre,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'user': userIdent,
      if (genre != null) 'genre': genre,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get(
      '/order/genre/customer',
      queryParameters: queryParams,
    );

    final data = response.data;
    final list = data['list'];

    if (list is List) {
      return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 店内零售订单列表
  /// 后端 POST /order/shop-sale-list，返回 { code, res: { res: [...] } }
  Future<List<Order>> getShopSaleList({
    int? status,
    int? department,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final body = <String, dynamic>{
      if (status != null) 'status': status,
      if (department != null) 'department': department,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.post(
      '/order/shop-sale-list',
      data: body,
    );

    final data = response.data;
    // 后端返回 { code, res: { res: [...] } }
    final res = (data['res'] as Map<String, dynamic>?)?['res'];
    if (res is List) {
      return res.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 店内零售订单总数
  Future<int> getShopSaleCount({
    int? status,
    int? department,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      if (department != null) 'department': department,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };

    final response = await _client.get(
      '/order/shop-sale-count',
      queryParameters: queryParams,
    );

    final data = response.data;
    return data['res'] as int? ?? 0;
  }

  /// 网销订单列表
  /// 后端 GET /order/net-sale-list，返回 { code, res: { res: [...] } }
  Future<List<Order>> getNetSaleList({
    String? orderBy,
    int? status,
    int? department,
    int? sellerIdent,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (orderBy != null) 'orderBy': orderBy,
      if (status != null) 'status': status,
      if (department != null) 'department': department,
      if (sellerIdent != null) 'sellerIdent': sellerIdent,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get(
      '/order/net-sale-list',
      queryParameters: queryParams,
    );

    final data = response.data;
    // 后端返回 { code, res: { res: [...] } }
    final res = (data['res'] as Map<String, dynamic>?)?['res'];
    if (res is List) {
      return res.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 服务订单列表
  /// 后端 GET /order/service-sale-list，返回 { code, res: { res: [...] } }
  Future<List<Order>> getServiceSaleList({
    int? status,
    int? department,
    int? sellerIdent,
    int? handlerIdent,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      if (department != null) 'department': department,
      if (sellerIdent != null) 'sellerIdent': sellerIdent,
      if (handlerIdent != null) 'handlerIdent': handlerIdent,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get(
      '/order/service-sale-list',
      queryParameters: queryParams,
    );

    final data = response.data;
    // 后端返回 { code, res: { res: [...] } }
    final res = (data['res'] as Map<String, dynamic>?)?['res'];
    if (res is List) {
      return res.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 销售统计查询
  /// 后端 GET /order/statistic-condition，返回 { code, list: [...] }
  /// 必须传 fields 参数
  Future<Map<String, dynamic>> getOrderStatistic({
    required List<String> fields,
    int? department,
    int? sellerIdent,
    int? minCreatedAt,
    int? maxCreatedAt,
    String? orderBy,
  }) async {
    final queryParams = <String, dynamic>{
      'fields': fields,
      if (department != null) 'department': department,
      if (sellerIdent != null) 'sellerIdent': sellerIdent,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      if (orderBy != null) 'orderBy': orderBy,
    };

    final response = await _client.get(
      '/order/statistic-condition',
      queryParameters: queryParams,
    );

    final data = response.data;
    // 后端返回 { code, list: [...] }
    final list = data['list'];
    if (list is List && list.isNotEmpty) {
      return list[0] as Map<String, dynamic>;
    }
    return {};
  }

  /// 部门订单数量统计
  /// 后端 GET /order/count/department，返回 { code, list: [...] }
  Future<List<Map<String, dynamic>>> getOrderCountByDepartment({
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };

    final response = await _client.get(
      '/order/count/department',
      queryParameters: queryParams,
    );

    final data = response.data;
    final list = data['list'];

    if (list is List) {
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  /// 营业员订单数量统计
  /// 后端 GET /order/count/seller，返回 { code, list: [...] }
  Future<List<Map<String, dynamic>>> getOrderCountBySeller({
    int? department,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{
      if (department != null) 'department': department,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };

    final response = await _client.get(
      '/order/count/seller',
      queryParameters: queryParams,
    );

    final data = response.data;
    final list = data['list'];

    if (list is List) {
      return list.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  // ── 商城订单（MallOrder）────────────────────────────────

  /// 获取商城订单列表
  /// status: 0=待付款, 1=已付款待发货, 2=已发货待收货, 3=已完成, 4=已取消, 5=退款中, 6=已退款
  /// 后端 GET /mall-order/list，返回 { code, res: [...] }
  Future<List<MallOrder>> getMallOrderList({
    int? status,
    int? department,
    int? customerIdent,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      if (department != null) 'department': department,
      if (customerIdent != null) 'customerIdent': customerIdent,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get(
      '/mall-order/list',
      queryParameters: queryParams,
    );

    final data = response.data;
    // 后端返回 { code, res: [...] }
    final res = data['res'];
    if (res is List) {
      return res.map((e) => MallOrder.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取商城订单总数
  /// 后端 GET /mall-order/count，返回 { code, res: { res: N } }
  Future<int> getMallOrderCount({
    int? status,
    int? department,
    int? customerIdent,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      if (department != null) 'department': department,
      if (customerIdent != null) 'customerIdent': customerIdent,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };

    final response = await _client.get(
      '/mall-order/count',
      queryParameters: queryParams,
    );

    // 后端返回 { code, res: { res: N } }
    final res = response.data['res'];
    final count = (res is Map<String, dynamic>) ? res['res'] : res;
    return count as int? ?? 0;
  }

  /// 获取商城订单完整详情（网销订单版）
  /// 后端 GET /mall-order/new-order-mall-order-detail?mallOrderNumber=X
  /// 返回更丰富的订单信息，包含网销订单、商品、服务、赠品等
  Future<MallOrderFullDetail> getNewOrderDetailByMallNumber(String orderNumber) async {
    final response = await _client.get(
      '/mall-order/new-order-mall-order-detail',
      queryParameters: {'mallOrderNumber': orderNumber},
    );
    final data = response.data;
    // 后端返回 { code, res: { ... } }
    final res = data['res'] ?? data;
    if (res is Map<String, dynamic>) {
      return MallOrderFullDetail.fromJson(res);
    }
    throw Exception('未找到订单详情');
  }

  /// 获取商城订单详情
  /// 后端 GET /mall-order/detail
  Future<MallOrder> getMallOrderDetail(String orderNumber) async {
    final response = await _client.get(
      '/mall-order/detail',
      queryParameters: {'p': orderNumber},
    );

    final data = response.data;
    // 后端返回 { code, res: { ... } }
    final res = data['res'] ?? data;
    if (res is Map<String, dynamic>) {
      return MallOrder.fromJson(res);
    }
    throw Exception('未找到订单详情');
  }

  /// 确认收货（顾客）
  /// 后端 POST /mall-order/customer-confirm-received
  Future<bool> mallOrderConfirmReceived(String orderNumber) async {
    final response = await _client.post(
      '/mall-order/customer-confirm-received',
      data: {'p': orderNumber},
    );
    return response.data['res'] == true;
  }

  /// 商家发货
  /// 后端 POST /mall-order/outed-of-warehouse
  Future<bool> mallOrderShipped(String orderNumber, {String? expressName, String? expressNumber}) async {
    final response = await _client.post(
      '/mall-order/outed-of-warehouse',
      data: {
        'p': orderNumber,
        if (expressName != null) 'expressName': expressName,
        if (expressNumber != null) 'expressNumber': expressNumber,
      },
    );
    return response.data['res'] == true;
  }

  /// 取消未支付订单
  /// 后端 POST /mall-order/unpaid-cancel
  Future<bool> mallOrderUnpaidCancel(String orderNumber) async {
    final response = await _client.post(
      '/mall-order/unpaid-cancel',
      data: {'p': orderNumber},
    );
    return response.data['res'] == 1;
  }

  /// 取消已支付订单（需权限审批）
  /// 后端 POST /mall-order/paid-cancel
  Future<bool> mallOrderPaidCancel(String orderNumber) async {
    final response = await _client.post(
      '/mall-order/paid-cancel',
      data: {'p': orderNumber},
    );
    return response.data['res'] == 1;
  }

  /// 按状态统计商城订单数量
  /// 后端 GET /mall-order/all
  Future<Map<String, int>> getMallOrderStatistics() async {
    final response = await _client.get('/mall-order/all');
    final data = response.data;
    // 后端返回 { code, res: { res: { status: count } } }
    final res = data['res'];
    if (res is Map<String, dynamic>) {
      final innerRes = res['res'];
      if (innerRes is Map<String, dynamic>) {
        return innerRes.map((k, v) => MapEntry(k, v as int));
      }
    }
    return {};
  }

  // ── 代下单 ──────────────────────────────────────────────

  /// 员工代下单（零售单）
  /// 后端 POST /mall-order/empl-add，返回 { code, res: "订单号" }
  Future<bool> emplAddMallOrder({
    required int customerIdent,
    required List<Map<String, dynamic>> products,
    int? departmentId,
    String? remark,
  }) async {
    final response = await _client.post(
      '/mall-order/empl-add',
      data: {
        'customerIdent': customerIdent,
        'info': products,
        if (departmentId != null) 'departmentID': departmentId,
        if (remark != null) 'remark': remark,
      },
    );
    // 后端返回 { code, res: "订单号" }
    final res = response.data['res'];
    return res is String && res.isNotEmpty;
  }

  /// ── 订单支付明细 ─────────────────────────────────────
  /// 根据订单号获取支付明细列表
  /// 后端 GET /payment-detail/list?orderNumbers=X
  Future<List<OrderPaymentDetail>> getPaymentDetailListByOrder(String orderNumber) async {
    final response = await _client.get(
      '/payment-detail/list',
      queryParameters: {
        'orderNumbers': orderNumber,
        'limit': 50,
        'offset': 0,
      },
    );
    final data = response.data;
    // 后端返回 { code, res: { res: [...] } } 或 { code, list: [...] }
    final res = (data['res'] is Map<String, dynamic>)
        ? (data['res'] as Map<String, dynamic>)['res']
        : data['res'];
    if (res is List) {
      return res.map((e) => OrderPaymentDetail.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// ── 订单积分变动 ─────────────────────────────────────
  /// 根据订单号获取积分变动
  /// 后端 GET /coin-detail/by-order-numbers?orderNumbers=X
  Future<OrderCoinChange?> getCoinDetailByOrder(String orderNumber) async {
    try {
      final response = await _client.get(
        '/coin-detail/by-order-numbers',
        queryParameters: {'orderNumbers': orderNumber},
      );
      final data = response.data;
      final res = data is List ? data : (data['res'] as List?);
      if (res == null || res.isEmpty) return null;
      final item = res[0] as Map<String, dynamic>;
      return OrderCoinChange.fromJson(item);
    } catch (_) {
      return null;
    }
  }
}

/// 订单支付明细
class OrderPaymentDetail {
  final int paymentDetailID;
  final String paymentDetailNumber;
  final String orderNumber;
  final int paymentTypeID;
  final int amount;
  final String? status;
  final String? platformNumber;
  final String? remarks;
  final int? createdAt;
  final String? paymentTypeName;

  const OrderPaymentDetail({
    required this.paymentDetailID,
    required this.paymentDetailNumber,
    required this.orderNumber,
    required this.paymentTypeID,
    required this.amount,
    this.status,
    this.platformNumber,
    this.remarks,
    this.createdAt,
    this.paymentTypeName,
  });

  factory OrderPaymentDetail.fromJson(Map<String, dynamic> json) {
    return OrderPaymentDetail(
      paymentDetailID: json['paymentDetailID'] as int? ?? 0,
      paymentDetailNumber: json['paymentDetailNumber'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      paymentTypeID: json['paymentTypeID'] as int? ?? 0,
      amount: json['amount'] as int? ?? 0,
      status: json['status'] as String?,
      platformNumber: json['platformNumber'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] as int?,
      paymentTypeName: json['paymentTypeName'] as String? ?? json['paymentType'] as String?,
    );
  }
}

/// 订单积分变动
class OrderCoinChange {
  final int increase;
  final int decrease;
  final int? orderNumber;

  const OrderCoinChange({
    required this.increase,
    required this.decrease,
    this.orderNumber,
  });

  factory OrderCoinChange.fromJson(Map<String, dynamic> json) {
    return OrderCoinChange(
      increase: json['increase'] as int? ?? 0,
      decrease: json['decrease'] as int? ?? 0,
      orderNumber: json['orderNumber'] as int?,
    );
  }
}
