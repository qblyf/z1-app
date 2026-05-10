import 'package:z1_app/api/api_client.dart';

/// 提成统计 API
/// 对应后端 /commission/* 系列接口
class CommissionApi {
  final ApiClient _client = ApiClient();

  /// 订单提成列表
  /// GET /commission/order
  Future<List<CommissionOrderItem>> getOrderCommission({
    required String orderNumber,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? employee,
    int? department,
  }) async {
    final queryParams = <String, dynamic>{
      'orderNumber': orderNumber,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      if (employee != null) 'employee': employee,
      if (department != null) 'department': department,
    };

    final res = await _client.get(
      '/commission/order',
      queryParameters: queryParams,
    );
    final list = (res.data['list'] as List<dynamic>?) ?? [];
    return list.map((e) => CommissionOrderItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 订单商品提成列表
  /// GET /commission/order/product
  Future<List<CommissionProductItem>> getProductCommission({
    required String orderNumber,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? employee,
  }) async {
    final queryParams = <String, dynamic>{
      'orderNumber': orderNumber,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      if (employee != null) 'employee': employee,
    };

    final res = await _client.get(
      '/commission/order/product',
      queryParameters: queryParams,
    );
    final list = (res.data['list'] as List<dynamic>?) ?? [];
    return list.map((e) => CommissionProductItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 订单服务提成列表
  /// GET /commission/order/service
  Future<List<CommissionServiceItem>> getServiceCommission({
    required String orderNumber,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? employee,
  }) async {
    final queryParams = <String, dynamic>{
      'orderNumber': orderNumber,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      if (employee != null) 'employee': employee,
    };

    final res = await _client.get(
      '/commission/order/service',
      queryParameters: queryParams,
    );
    final list = (res.data['list'] as List<dynamic>?) ?? [];
    return list.map((e) => CommissionServiceItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// 订单提成条目
class CommissionOrderItem {
  final int id;
  final int? department;
  final int? employee;
  final String? orderNumber;
  final int price; // 单位：分
  final int? createdAt;
  final String? remarks;
  final int? orderType;
  final int? orderGenre;
  final int? totalCommissionPrice; // 总提成金额（分）

  CommissionOrderItem({
    required this.id,
    this.department,
    this.employee,
    this.orderNumber,
    required this.price,
    this.createdAt,
    this.remarks,
    this.orderType,
    this.orderGenre,
    this.totalCommissionPrice,
  });

  factory CommissionOrderItem.fromJson(Map<String, dynamic> json) {
    return CommissionOrderItem(
      id: json['id'] as int? ?? 0,
      department: json['department'] as int?,
      employee: json['employee'] as int?,
      orderNumber: json['orderNumber'] as String?,
      price: json['price'] as int? ?? 0,
      createdAt: json['createdAt'] as int?,
      remarks: json['remarks'] as String?,
      orderType: json['orderType'] as int?,
      orderGenre: json['orderGenre'] as int?,
      totalCommissionPrice: json['totalCommissionPrice'] as int?,
    );
  }
}

/// 商品提成条目
class CommissionProductItem {
  final int id;
  final int? employee;
  final int? productID;
  final String? serial;
  final int discountCent; // 优惠后金额（分）
  final int price; // 提成金额（分）
  final int? commissionRuleID;
  final int? orderNumberID;

  CommissionProductItem({
    required this.id,
    this.employee,
    this.productID,
    this.serial,
    required this.discountCent,
    required this.price,
    this.commissionRuleID,
    this.orderNumberID,
  });

  factory CommissionProductItem.fromJson(Map<String, dynamic> json) {
    return CommissionProductItem(
      id: json['id'] as int? ?? 0,
      employee: json['employee'] as int?,
      productID: json['productID'] as int?,
      serial: json['serial'] as String?,
      discountCent: json['discountCent'] as int? ?? 0,
      price: json['price'] as int? ?? 0,
      commissionRuleID: json['commissionRuleID'] as int?,
      orderNumberID: json['orderNumberID'] as int?,
    );
  }
}

/// 服务提成条目
class CommissionServiceItem {
  final int id;
  final int? employee;
  final int? serviceID;
  final String? sn;
  final int discountCent; // 优惠后金额（分）
  final int price; // 提成金额（分）
  final int? commissionRuleID;
  final int? orderNumberID;
  final List<int>? couponIDs;

  CommissionServiceItem({
    required this.id,
    this.employee,
    this.serviceID,
    this.sn,
    required this.discountCent,
    required this.price,
    this.commissionRuleID,
    this.orderNumberID,
    this.couponIDs,
  });

  factory CommissionServiceItem.fromJson(Map<String, dynamic> json) {
    return CommissionServiceItem(
      id: json['id'] as int? ?? 0,
      employee: json['employee'] as int?,
      serviceID: json['serviceID'] as int?,
      sn: json['sn'] as String?,
      discountCent: json['discountCent'] as int? ?? 0,
      price: json['price'] as int? ?? 0,
      commissionRuleID: json['commissionRuleID'] as int?,
      orderNumberID: json['orderNumberID'] as int?,
      couponIDs: (json['couponIDs'] as List<dynamic>?)?.cast<int>(),
    );
  }
}
