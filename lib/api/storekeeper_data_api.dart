import '../models/storekeeper_data.dart';
import 'api_client.dart';

final storekeeperDataApi = StorekeeperDataApi();

class StorekeeperDataApi {
  final ApiClient _client = ApiClient();

  /// 门店排行
  /// 后端 GET /weight-distribution/monthly-goals/store-rank-top
  Future<List<StoreRankItem>> getStoreRank({
    required int departmentId,
    required int start,
    required int end,
    String orderByKey = 'mainProductCount',
    String sort = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'departmentID': departmentId,
      'start': start,
      'end': end,
      'orderBy': [
        {'key': orderByKey, 'sort': sort}
      ],
    };
    // 后端 GET /weight-distribution/monthly-goals/store-rank-top
    // 返回 { code, res: [...] }
    final res = await _client.get(
      '/weight-distribution/monthly-goals/store-rank-top',
      queryParameters: queryParams,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => StoreRankItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 员工销售排行
  /// 后端 GET /sales-statistic/seller-sales-ranking
  Future<List<EmployeeSalesItem>> getEmployeeSalesRanking({
    required int departmentId,
    required int minCreatedAt,
    required int maxCreatedAt,
    String orderByKey = 'mainProductCount',
    String sort = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'departmentID': departmentId,
      'minCreatedAt': minCreatedAt,
      'maxCreatedAt': maxCreatedAt,
    };
    // 后端 GET /sales-statistic/seller-sales-ranking
    // 返回 { code, res: [...] }
    final res = await _client.get(
      '/sales-statistic/seller-sales-ranking',
      queryParameters: queryParams,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => EmployeeSalesItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 重点产品统计
  /// 后端 GET /product/main-products-statistic
  Future<List<MainProductItem>> getMainProducts({
    required int departmentId,
    required int minCreatedAt,
    required int maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{
      'departmentID': departmentId,
      'minCreatedAt': minCreatedAt,
      'maxCreatedAt': maxCreatedAt,
    };
    // 后端 GET /product/main-products-statistic
    // 返回 { code, res: [...] }
    final res = await _client.get(
      '/product/main-products-statistic',
      queryParameters: queryParams,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => MainProductItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 重点产品员工销售详情
  /// 后端 GET /product/main-products-employee-statistic
  Future<List<MainProductEmplItem>> getMainProductsEmplStatistic({
    required int departmentId,
    required int productId,
    required int minCreatedAt,
    required int maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{
      'departmentID': departmentId,
      'productID': productId,
      'minCreatedAt': minCreatedAt,
      'maxCreatedAt': maxCreatedAt,
    };
    // 后端 GET /product/main-products-employee-statistic
    // 返回 { code, res: [...] }
    final res = await _client.get(
      '/product/main-products-employee-statistic',
      queryParameters: queryParams,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => MainProductEmplItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 资金周转
  /// 后端 GET /capital-turnover
  Future<List<CapitalTurnoverItem>> getCapitalTurnover({
    required int departmentId,
    String orderByKey = 'recentDiscountAmount',
    String sort = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'departmentID': departmentId,
      'orderBy': [
        {'key': orderByKey, 'sort': sort}
      ],
    };
    // 后端 GET /capital-turnover
    // 返回 { code, res: [...] }
    final res = await _client.get(
      '/capital-turnover',
      queryParameters: queryParams,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => CapitalTurnoverItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 目标总览
  /// 后端 GET /weight-distribution/monthly-goals/task-target-actual-value
  Future<MonthlyGoalsPandect> getMonthlyGoalsPandect({
    required int departmentId,
    int? year,
    int? month,
  }) async {
    final queryParams = <String, dynamic>{
      'department': departmentId,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    };
    // 后端 GET /weight-distribution/monthly-goals/task-target-actual-value
    // 返回 { code, res: { taskProgressRes: [...], actualValueRes: [...] } }
    final res = await _client.get(
      '/weight-distribution/monthly-goals/task-target-actual-value',
      queryParameters: queryParams,
    );
    return MonthlyGoalsPandect.fromJson(res.data['res'] as Map<String, dynamic>);
  }

  /// SPU排行
  /// 后端 GET /sales-statistic/spu-ranking
  Future<List<SPURankingItem>> getSPURanking({
    required int departmentId,
    required int minCreatedAt,
    required int maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{
      'departmentID': departmentId,
      'minCreatedAt': minCreatedAt,
      'maxCreatedAt': maxCreatedAt,
    };
    // 后端 GET /sales-statistic/spu-ranking
    // 返回 { code, res: [...] }
    final res = await _client.get(
      '/sales-statistic/spu-ranking',
      queryParameters: queryParams,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => SPURankingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// SKU排行
  /// 后端 GET /sales-statistic/sku-ranking
  Future<List<SKURankingItem>> getSKURanking({
    required int departmentId,
    required int minCreatedAt,
    required int maxCreatedAt,
    int? spuId,
  }) async {
    final queryParams = <String, dynamic>{
      'departmentID': departmentId,
      'minCreatedAt': minCreatedAt,
      'maxCreatedAt': maxCreatedAt,
      if (spuId != null) 'spuID': spuId,
    };
    // 后端 GET /sales-statistic/sku-ranking
    // 返回 { code, res: [...] }
    final res = await _client.get(
      '/sales-statistic/sku-ranking',
      queryParameters: queryParams,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => SKURankingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 区域排行
  /// 后端 GET /weight-distribution/monthly-goals/area-rank-top
  Future<List<AreaRankItem>> getAreaRankTop({
    required int departmentId,
    required int startAt,
    required int endAt,
    String orderByKey = 'mainProductCount',
    String sort = 'desc',
  }) async {
    final queryParams = <String, dynamic>{
      'departmentID': departmentId,
      'startAt': startAt,
      'endAt': endAt,
      'areaOrderBy': {'key': orderByKey, 'sort': sort},
    };
    // 后端 GET /weight-distribution/monthly-goals/area-rank-top
    // 返回 { code, res: [...] }
    final res = await _client.get(
      '/weight-distribution/monthly-goals/area-rank-top',
      queryParameters: queryParams,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => AreaRankItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 门店详情
  /// 后端 GET /department/detail
  Future<StoreDetail> getStoreDetail({
    required int departmentId,
  }) async {
    final queryParams = <String, dynamic>{
      'departmentID': departmentId,
    };
    // 后端 GET /department/detail
    // 返回 { code, res: { ... } }
    final res = await _client.get(
      '/department/detail',
      queryParameters: queryParams,
    );
    // 后端返回的是数组，取第一个元素
    final list = (res.data['res'] as List?) ?? [];
    if (list.isEmpty) {
      throw Exception('门店详情为空');
    }
    return StoreDetail.fromJson(list[0] as Map<String, dynamic>);
  }

  /// 经营助手首页数据（经营分析）
  /// 后端 GET /weight-distribution/monthly-goals/get-task-progress-actual-value
  /// [departmentId] 部门ID
  /// [startAt] 开始时间(unix秒)
  /// [endAt] 结束时间(unix秒)
  Future<TypePhaseStats> getTaskProgressActualValue({
    required int departmentId,
    required int startAt,
    required int endAt,
  }) async {
    final queryParams = <String, dynamic>{
      'departments': [departmentId],
      'startAt': startAt,
      'endAt': endAt,
    };
    // 后端 GET /weight-distribution/monthly-goals/get-task-progress-actual-value
    // 返回 { code, res: { count[], gross[], amount[], cost[], averageGross[], relatedRate[], other[] } }
    final res = await _client.get(
      '/weight-distribution/monthly-goals/get-task-progress-actual-value',
      queryParameters: queryParams,
    );
    return TypePhaseStats.fromJson(
      (res.data['res'] as Map<String, dynamic>?) ?? {},
    );
  }
}
