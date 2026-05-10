import 'api_client.dart';
import '../models/coupon.dart';

/// 卡券 API 服务
/// 对应后端 /coupons/* 系列接口
class CouponApi {
  final ApiClient _client = ApiClient();

  /// 获取会员卡券列表
  Future<List<Coupon>> getMemberCoupons({
    required List<int> userIdents,
    List<int>? types,
    int? state,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'userIdents': userIdents.join(','),
      if (types != null) 'types': types.join(','),
      if (state != null) 'state': state,
      'limit': limit,
      'offset': offset,
    };

    // 后端 GET /coupons/member，返回 { code, res: [...] }
    final response = await _client.get('/coupons/member', queryParameters: queryParams);
    final list = response.data['res'] as List?;
    if (list is List) {
      return list.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取用户有效卡券
  Future<List<Coupon>> getCouponListByUsers({
    required List<int> users,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, dynamic>{
      'users': users.join(','),
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };

    // 后端 GET /coupons/get-by-user
    final response = await _client.get('/coupons/get-by-user', queryParameters: queryParams);
    final list = response.data['res'] as List?;
    if (list is List) {
      return list.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取卡券列表
  Future<List<Coupon>> getList({
    List<int>? ids,
    List<int>? classIds,
    List<int>? users,
    List<int>? owners,
    List<int>? departments,
    List<int>? states,
    List<int>? types,
    int? minGotAt,
    int? maxGotAt,
    int? offset,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{
      if (ids != null) 'ids': ids.join(','),
      if (classIds != null) 'classIDs': classIds.join(','),
      if (users != null) 'users': users.join(','),
      if (owners != null) 'owners': owners.join(','),
      if (departments != null) 'departments': departments.join(','),
      if (states != null) 'states': states.join(','),
      if (types != null) 'types': types.join(','),
      if (minGotAt != null) 'minGotAt': minGotAt,
      if (maxGotAt != null) 'maxGotAt': maxGotAt,
      if (offset != null) 'offset': offset,
      if (limit != null) 'limit': limit,
    };

    // 后端 GET /coupons/list
    final response = await _client.get('/coupons/list', queryParameters: queryParams);
    final list = response.data['res'] as List?;
    if (list is List) {
      return list.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取卡券总数
  Future<int> getCount({
    List<int>? states,
    List<int>? types,
    int? minGotAt,
    int? maxGotAt,
  }) async {
    final queryParams = <String, dynamic>{
      if (states != null) 'states': states.join(','),
      if (types != null) 'types': types.join(','),
      if (minGotAt != null) 'minGotAt': minGotAt,
      if (maxGotAt != null) 'maxGotAt': maxGotAt,
    };

    // 后端 GET /coupons/count-condition
    final response = await _client.get('/coupons/count-condition', queryParameters: queryParams);
    return response.data['res'] as int? ?? 0;
  }

  /// 领取优惠券
  Future<int> userGet(int couponClassId) async {
    final response = await _client.post(
      '/coupons/user-get',
      data: {'couponClassID': couponClassId},
    );
    return response.data['couponID'] as int? ?? 0;
  }

  /// 发放优惠券
  Future<bool> giveCoupons({
    required List<int> userIdents,
    required int couponClassId,
    String? remark,
  }) async {
    final body = <String, dynamic>{
      'userIdents': userIdents,
      'couponClassID': couponClassId,
      if (remark != null) 'remark': remark,
    };

    final response = await _client.post('/coupons/give-coupons', data: body);
    return response.data['code'] == 10000;
  }

  /// 检查卡券状态
  Future<Map<int, int>> checkCouponsState(List<int> couponIds) async {
    final queryParams = <String, dynamic>{
      'coupons': couponIds.join(','),
    };

    final response = await _client.get('/coupons/check', queryParameters: queryParams);
    final result = response.data['result'] as List?;

    if (result == null) return {};

    return {
      for (var item in result)
        item['id'] as int: item['state'] as int,
    };
  }

  /// 获取优惠券类别列表
  /// GET /coupon-class/list
  Future<List<CouponClass>> getCouponClassList({
    String? title,
    int? state,
    int? type,
    int? limit = 20,
    int? offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (title != null && title.isNotEmpty) 'title': title,
      if (state != null) 'state': state,
      if (type != null) 'type': type,
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
    };

    final response = await _client.get('/coupon-class/list', queryParameters: queryParams);
    final list = response.data;
    if (list is List) {
      return list.map((e) => CouponClass.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 批量发放优惠券
  /// POST /coupons/give-coupons
  Future<bool> batchGiveCoupons({
    required List<int> userIdents,
    required int couponClassId,
    String? remark,
  }) async {
    final body = <String, dynamic>{
      'userIdents': userIdents,
      'couponClassID': couponClassId,
      if (remark != null && remark.isNotEmpty) 'remark': remark,
    };

    final response = await _client.post('/coupons/give-coupons', data: body);
    return response.data['code'] == 10000 || response.data == true;
  }
}

/// 优惠券类别
class CouponClass {
  final int id;
  final String title;
  final int type;
  final String? typeName;
  final int? amount;
  final int? discount;
  final int? minAmount;
  final int? totalCount;
  final int? usedCount;
  final int state;
  final int? startGetAt;
  final int? endGetAt;
  final int? startUseAt;
  final int? endUseAt;
  final int? validDays;
  final int? maxGetPerUser;
  final int createdAt;
  final int createdBy;

  CouponClass({
    required this.id,
    required this.title,
    required this.type,
    this.typeName,
    this.amount,
    this.discount,
    this.minAmount,
    this.totalCount,
    this.usedCount,
    required this.state,
    this.startGetAt,
    this.endGetAt,
    this.startUseAt,
    this.endUseAt,
    this.validDays,
    this.maxGetPerUser,
    required this.createdAt,
    required this.createdBy,
  });

  factory CouponClass.fromJson(Map<String, dynamic> json) {
    return CouponClass(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      type: json['type'] as int? ?? 1,
      typeName: json['typeName'] as String?,
      amount: json['amount'] as int?,
      discount: json['discount'] as int?,
      minAmount: json['minAmount'] as int?,
      totalCount: json['totalCount'] as int?,
      usedCount: json['usedCount'] as int?,
      state: json['state'] as int? ?? 1,
      startGetAt: json['startGetAt'] as int?,
      endGetAt: json['endGetAt'] as int?,
      startUseAt: json['startUseAt'] as int?,
      endUseAt: json['endUseAt'] as int?,
      validDays: json['validDays'] as int?,
      maxGetPerUser: json['maxGetPerUser'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
    );
  }

  String get formattedAmount => '¥${((amount ?? 0) / 100).toStringAsFixed(2)}';
  String get formattedDiscount => '${((discount ?? 0) / 10).toStringAsFixed(1)}折';
  String get formattedMinAmount => '满${((minAmount ?? 0) / 100).toStringAsFixed(2)}';

  String get typeLabel {
    switch (type) {
      case 1: return '优惠券';
      case 2: return '代金券';
      case 3: return '电子保卡';
      case 4: return '储值卡';
      case 15: return '换新补贴';
      default: return '卡券';
    }
  }

  String get stateLabel {
    switch (state) {
      case 1: return '可用';
      case 2: return '不可用';
      default: return '未知';
    }
  }

  bool get isAvailable => state == 1;
}
