import 'package:z1_app/api/api_client.dart';
import '../models/order.dart';

/// 销售数据统计 API
class SalesDataApi {
  final ApiClient _client = ApiClient();

  /// 获取今日订单统计
  /// 后端 /order/statistic-condition 需要 fields 参数
  Future<Map<String, dynamic>> getTodayStatistic({int? department, int? sellerIdent}) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final queryParams = <String, dynamic>{
      'fields': ['department', 'seller', 'cashier'],
      'minCreatedDate': startOfDay.millisecondsSinceEpoch ~/ 1000,
      'maxCreatedDate': now.millisecondsSinceEpoch ~/ 1000,
    };
    if (department != null) queryParams['departments'] = [department];
    if (sellerIdent != null) queryParams['sellers'] = [sellerIdent];

    // 后端返回 { code, list: [...] }
    final response = await _client.get(
      '/order/statistic-condition',
      queryParameters: queryParams,
    );

    final list = response.data['list'];
    if (list is List && list.isNotEmpty) {
      return list.first as Map<String, dynamic>;
    }
    return {};
  }

  /// 获取本月订单统计
  Future<Map<String, dynamic>> getMonthStatistic({int? department, int? sellerIdent}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final queryParams = <String, dynamic>{
      'fields': ['department', 'seller', 'cashier', 'year', 'month'],
      'minCreatedDate': startOfMonth.millisecondsSinceEpoch ~/ 1000,
      'maxCreatedDate': now.millisecondsSinceEpoch ~/ 1000,
    };
    if (department != null) queryParams['departments'] = [department];
    if (sellerIdent != null) queryParams['sellers'] = [sellerIdent];

    // 后端返回 { code, list: [...] }
    final response = await _client.get(
      '/order/statistic-condition',
      queryParameters: queryParams,
    );

    final list = response.data['list'];
    if (list is List && list.isNotEmpty) {
      return list.first as Map<String, dynamic>;
    }
    return {};
  }

  /// 获取营业员订单排行
  Future<List<Map<String, dynamic>>> getSellerRanking({
    int? department,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      if (department != null) 'department': department,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };

    // 后端 GET /order/count/seller，返回 { code, list: [...] }
    final response = await _client.get(
      '/order/count/seller',
      queryParameters: queryParams,
    );

    final list = response.data['list'];
    if (list is List) {
      final sorted = list.cast<Map<String, dynamic>>().toList()
        ..sort((a, b) => ((b['orderCount'] ?? 0) as int).compareTo((a['orderCount'] ?? 0) as int));
      return sorted.take(limit).toList();
    }
    return [];
  }

  /// 获取营业员回收订单列表
  Future<List<Order>> getRecycleOrders({
    int? sellerIdent,
    int? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (sellerIdent != null) 'sellerIdent': sellerIdent,
      if (status != null) 'status': status,
      'limit': limit,
      'offset': offset,
    };

    // 后端返回 { code, res: { res: [...] } } 两层嵌套
    final response = await _client.get(
      '/order/list',
      queryParameters: queryParams,
    );

    final data = response.data;
    final innerRes = (data['res'] as Map<String, dynamic>?)?['res'];
    if (innerRes is List) {
      return innerRes
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .where((o) => o.genre == 'recycleOrder')
          .toList();
    }
    return [];
  }

  /// 获取近期订单
  Future<List<Order>> getRecentOrders({
    int? sellerIdent,
    int? department,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      if (sellerIdent != null) 'sellerIdent': sellerIdent,
      if (department != null) 'department': department,
      'limit': limit,
      'offset': 0,
    };

    // 后端返回 { code, res: { res: [...] } } 两层嵌套
    final response = await _client.get(
      '/order/list',
      queryParameters: queryParams,
    );

    final data = response.data;
    final innerRes = (data['res'] as Map<String, dynamic>?)?['res'];
    if (innerRes is List) {
      return innerRes
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
