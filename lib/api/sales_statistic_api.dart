import 'api_client.dart';

/// 员工销售排行统计
class SellerSalesRankingItem {
  final int sellerIdent;
  final int mainProductQuantity;
  final int discountAmount;
  final int grossProfit;
  final int totalCommissionPrice;

  SellerSalesRankingItem({
    required this.sellerIdent,
    required this.mainProductQuantity,
    required this.discountAmount,
    required this.grossProfit,
    required this.totalCommissionPrice,
  });

  factory SellerSalesRankingItem.fromJson(Map<String, dynamic> json) {
    return SellerSalesRankingItem(
      sellerIdent: json['sellerIdent'] ?? 0,
      mainProductQuantity: json['mainProductQuantity'] ?? 0,
      discountAmount: json['discountAmount'] ?? 0,
      grossProfit: json['grossProfit'] ?? 0,
      totalCommissionPrice: json['totalCommissionPrice'] ?? 0,
    );
  }
}

/// 销售统计数据 API
class SalesStatisticApi {
  final ApiClient _client = ApiClient();

  /// 员工销售排行统计
  /// [minCreatedAt] 开始时间(unix时间戳)
  /// [maxCreatedAt] 结束时间(unix时间戳)
  /// [departmentId] 部门ID(可选)
  Future<List<SellerSalesRankingItem>> sellerSalesRanking({
    required int minCreatedAt,
    required int maxCreatedAt,
    int? departmentId,
  }) async {
    final queryParams = <String, dynamic>{
      'minCreatedAt': minCreatedAt,
      'maxCreatedAt': maxCreatedAt,
    };
    if (departmentId != null) {
      queryParams['departmentID'] = departmentId;
    }
    final response = await _client.get(
      '/sales-statistic/seller-sales-ranking',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data == null || data['res'] == null) return [];
    final list = data['res'] as List;
    return list.map((e) => SellerSalesRankingItem.fromJson(e)).toList();
  }
}
