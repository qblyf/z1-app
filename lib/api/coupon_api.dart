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
}
