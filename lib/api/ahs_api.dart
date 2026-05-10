import 'api_client.dart';
import '../models/ahs_order.dart';

/// 爱回收(AHS) API
/// 对应后端 /ahs/* API
class AhsApi {
  final ApiClient _client = ApiClient();

  /// 获取掌上回收单详情
  /// [number] 回收单编号
  Future<AhsOrder?> getOrderInfo(String number) async {
    final response = await _client.get(
      '/ahs/order/info',
      queryParameters: {'number': number},
    );
    final data = response.data;
    if (data == null || data['res'] == null) return null;
    return AhsOrder.fromJson(data['res']);
  }

  /// 部门回收统计
  /// GET /ahs/statistics/deptment
  Future<List<AhsDeptStatistic>> deptStatistics({
    required int minCreatedAt,
    required int maxCreatedAt,
  }) async {
    final params = <String, dynamic>{
      'minCreatedAt': minCreatedAt,
      'maxCreatedAt': maxCreatedAt,
    };
    final res = await _client.get('/ahs/statistics/deptment', queryParameters: params);
    final data = res.data;
    if (data is List) {
      return data.map((e) => AhsDeptStatistic.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 职员回收统计
  /// GET /ahs/statistics/employee
  Future<List<AhsEmplStatistic>> emplStatistics({
    required int minCreatedAt,
    required int maxCreatedAt,
    List<int>? departmentIDs,
  }) async {
    final params = <String, dynamic>{
      'minCreatedAt': minCreatedAt,
      'maxCreatedAt': maxCreatedAt,
      if (departmentIDs != null && departmentIDs.isNotEmpty) 'departmentIDs': departmentIDs.join(','),
    };
    final res = await _client.get('/ahs/statistics/employee', queryParameters: params);
    final data = res.data;
    if (data is List) {
      return data.map((e) => AhsEmplStatistic.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}

/// 部门回收统计数据
class AhsDeptStatistic {
  final int department;
  final List<int> chain;
  final int mainProdCount;
  final int itemProdCount;
  final int estimateCount;
  final int recycleCount;
  final int recycleAmount;
  final int recycleCost;
  final int valuableCount;
  final int noValueCount;
  final int resaleCount;
  final int resaleAmount;
  final int resaleCost;
  final int unSoldCount;
  final int unSoldAmount;

  AhsDeptStatistic({
    required this.department,
    required this.chain,
    required this.mainProdCount,
    required this.itemProdCount,
    required this.estimateCount,
    required this.recycleCount,
    required this.recycleAmount,
    required this.recycleCost,
    required this.valuableCount,
    required this.noValueCount,
    required this.resaleCount,
    required this.resaleAmount,
    required this.resaleCost,
    required this.unSoldCount,
    required this.unSoldAmount,
  });

  factory AhsDeptStatistic.fromJson(Map<String, dynamic> json) {
    return AhsDeptStatistic(
      department: json['department'] as int? ?? 0,
      chain: (json['chain'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      mainProdCount: json['mainProdCount'] as int? ?? 0,
      itemProdCount: json['itemProdCount'] as int? ?? 0,
      estimateCount: json['estimateCount'] as int? ?? 0,
      recycleCount: json['recycleCount'] as int? ?? 0,
      recycleAmount: json['recycleAmount'] as int? ?? 0,
      recycleCost: json['recycleCost'] as int? ?? 0,
      valuableCount: json['valuableCount'] as int? ?? 0,
      noValueCount: json['noValueCount'] as int? ?? 0,
      resaleCount: json['resaleCount'] as int? ?? 0,
      resaleAmount: json['resaleAmount'] as int? ?? 0,
      resaleCost: json['resaleCost'] as int? ?? 0,
      unSoldCount: json['unSoldCount'] as int? ?? 0,
      unSoldAmount: json['unSoldAmount'] as int? ?? 0,
    );
  }

  /// 回收金额格式化
  String get formattedRecycleAmount => '¥${(recycleAmount / 100).toStringAsFixed(2)}';

  /// 预估毛利
  int get estimatedProfit => recycleAmount - recycleCost;
  String get formattedProfit => '¥${(estimatedProfit / 100).toStringAsFixed(2)}';
}

/// 职员回收统计数据
class AhsEmplStatistic {
  final int emplIdent;
  final int mainProdCount;
  final int itemProdCount;
  final int estimateCount;
  final int recycleCount;
  final int recycleAmount;
  final int recycleCost;
  final int valuableCount;
  final int noValueCount;
  final int resaleCount;
  final int resaleAmount;
  final int resaleCost;
  final int unSoldCount;
  final int unSoldAmount;

  AhsEmplStatistic({
    required this.emplIdent,
    required this.mainProdCount,
    required this.itemProdCount,
    required this.estimateCount,
    required this.recycleCount,
    required this.recycleAmount,
    required this.recycleCost,
    required this.valuableCount,
    required this.noValueCount,
    required this.resaleCount,
    required this.resaleAmount,
    required this.resaleCost,
    required this.unSoldCount,
    required this.unSoldAmount,
  });

  factory AhsEmplStatistic.fromJson(Map<String, dynamic> json) {
    return AhsEmplStatistic(
      emplIdent: json['emplIdent'] as int? ?? 0,
      mainProdCount: json['mainProdCount'] as int? ?? 0,
      itemProdCount: json['itemProdCount'] as int? ?? 0,
      estimateCount: json['estimateCount'] as int? ?? 0,
      recycleCount: json['recycleCount'] as int? ?? 0,
      recycleAmount: json['recycleAmount'] as int? ?? 0,
      recycleCost: json['recycleCost'] as int? ?? 0,
      valuableCount: json['valuableCount'] as int? ?? 0,
      noValueCount: json['noValueCount'] as int? ?? 0,
      resaleCount: json['resaleCount'] as int? ?? 0,
      resaleAmount: json['resaleAmount'] as int? ?? 0,
      resaleCost: json['resaleCost'] as int? ?? 0,
      unSoldCount: json['unSoldCount'] as int? ?? 0,
      unSoldAmount: json['unSoldAmount'] as int? ?? 0,
    );
  }

  String get formattedRecycleAmount => '¥${(recycleAmount / 100).toStringAsFixed(2)}';
  int get estimatedProfit => recycleAmount - recycleCost;
  String get formattedProfit => '¥${(estimatedProfit / 100).toStringAsFixed(2)}';
}
