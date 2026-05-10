import 'api_client.dart';
import '../models/stocktaking.dart';

/// 库存盘点 API
/// 后端路径: /stock-taking/*
class StocktakingApi {
  final ApiClient _client = ApiClient();

  /// 查询盘库方案列表
  /// GET /stock-taking-plan/list
  Future<List<StocktakingPlan>> planList({
    List<int>? states,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (states != null && states.isNotEmpty) {
      queryParams['states'] = states.join(',');
    }

    final res = await _client.get('/stock-taking-plan/list', queryParameters: queryParams);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => StocktakingPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 查询盘库方案详情
  /// GET /stock-taking-plan/detail
  Future<List<StocktakingPlan>> planInfo({required int id}) async {
    final res = await _client.get(
      '/stock-taking-plan/detail',
      queryParameters: {'id': id},
    );
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => StocktakingPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 新增盘库记录（选择仓库后发起盘库）
  /// POST /stock-taking/add
  Future<int> addStocktaking({
    required int planID,
    required int warehouseID,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'planID': planID,
      'warehouseID': warehouseID,
    };
    if (remarks != null) body['remarks'] = remarks;

    final res = await _client.post('/stock-taking/add', data: body);
    return res.data['res'] as int? ?? 0;
  }

  /// 查询盘点日志列表
  Future<List<StocktakingLog>> list({
    List<int>? warehouseIDs,
    List<int>? statusValues,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      body['warehouseIDs'] = warehouseIDs;
    }
    if (statusValues != null && statusValues.isNotEmpty) {
      body['statusValues'] = statusValues;
    }
    if (minCreatedAt != null) body['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) body['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get(
      '/stock-taking/list',
      queryParameters: body,
    );
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => StocktakingLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取盘点日志详情
  Future<StocktakingLog?> detail(int logID) async {
    final res = await _client.get(
      '/stock-taking/detail',
      queryParameters: {'id': logID},
    );
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return StocktakingLog.fromJson(data);
  }

  /// 获取盘点数量
  Future<int> count({
    List<int>? warehouseIDs,
    List<int>? statusValues,
  }) async {
    final body = <String, dynamic>{};
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      body['warehouseIDs'] = warehouseIDs;
    }
    if (statusValues != null && statusValues.isNotEmpty) {
      body['statusValues'] = statusValues;
    }
    final res = await _client.get('/stock-taking/count', queryParameters: body);
    return res.data['res'] as int? ?? 0;
  }

  /// 结束盘库
  /// POST /stock-taking/end
  Future<bool> end(int id) async {
    final res = await _client.post('/stock-taking/end', data: {'id': id});
    return res.data['code'] == 10000;
  }

  /// 盘库（扫码提交）
  /// POST /stock-taking
  Future<bool> take({
    required int id,
    required List<Map<String, dynamic>> stockTake,
  }) async {
    final res = await _client.post('/stock-taking', data: {
      'id': id,
      'stockTake': stockTake,
    });
    return res.data['code'] == 10000;
  }

  /// 盘库仪表盘列表（最近盘库记录）
  /// GET /stock-taking/last-list
  Future<List<Stocktaking>> dashboardList({
    List<int>? states,
    List<int>? warehouseIDs,
    List<int>? planIDs,
  }) async {
    final queryParams = <String, dynamic>{};
    if (states != null && states.isNotEmpty) queryParams['states'] = states.join(',');
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      queryParams['warehouseIDs'] = warehouseIDs.join(',');
    }
    if (planIDs != null && planIDs.isNotEmpty) {
      queryParams['planIDs'] = planIDs.join(',');
    }

    final res = await _client.get(
      '/stock-taking/last-list',
      queryParameters: queryParams,
    );
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => Stocktaking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 重新盘库
  /// POST /stock-taking/restocktaking
  Future<bool> reStocktaking({required int id}) async {
    final res = await _client.post('/stock-taking/restocktaking', data: {'id': id});
    return res.data['code'] == 10000;
  }

  /// 盘库详情（带系统库存快照）
  /// GET /stock-taking/detail
  Future<Stocktaking?> stocktakingDetail({required int id}) async {
    final res = await _client.get(
      '/stock-taking/detail',
      queryParameters: {'id': id},
    );
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return Stocktaking.fromJson(data);
  }

  /// 获取当前用户负责的仓库盘库任务
  /// GET /stock-taking-on-duty/user/list
  Future<List<UserStocktakingOnDuty>> getUserOnDutyList() async {
    final res = await _client.get('/stock-taking-on-duty/user/list');
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data.map((e) => UserStocktakingOnDuty.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 盘库记录列表（新版，带完整筛选）
  /// GET /stock-taking/list
  Future<List<Stocktaking>> stocktakingLogList({
    List<int>? states,
    List<int>? warehouseIDs,
    List<int>? planIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (states != null && states.isNotEmpty) {
      queryParams['states'] = states.join(',');
    }
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      queryParams['warehouseIDs'] = warehouseIDs.join(',');
    }
    if (planIDs != null && planIDs.isNotEmpty) {
      queryParams['planIDs'] = planIDs.join(',');
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get('/stock-taking/list', queryParameters: queryParams);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => Stocktaking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 盘库记录总数
  /// GET /stock-taking/count
  Future<int> stocktakingLogCount({
    List<int>? states,
    List<int>? warehouseIDs,
    List<int>? planIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{};
    if (states != null && states.isNotEmpty) {
      queryParams['states'] = states.join(',');
    }
    if (warehouseIDs != null && warehouseIDs.isNotEmpty) {
      queryParams['warehouseIDs'] = warehouseIDs.join(',');
    }
    if (planIDs != null && planIDs.isNotEmpty) {
      queryParams['planIDs'] = planIDs.join(',');
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get('/stock-taking/count', queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }

  /// 盘库值班列表
  /// GET /stock-taking-on-duty/list
  Future<List<UserStocktakingOnDuty>> onDutyList({
    int? warehouseID,
    int? planID,
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (warehouseID != null) queryParams['warehouseID'] = warehouseID;
    if (planID != null) queryParams['planID'] = planID;

    final res = await _client.get('/stock-taking-on-duty/list', queryParameters: queryParams);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => UserStocktakingOnDuty.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 盘库值班在用列表
  /// GET /stock-taking-on-duty/in-use-list
  Future<List<UserStocktakingOnDuty>> onDutyInUseList({
    int? warehouseID,
    int? planID,
  }) async {
    final queryParams = <String, dynamic>{};
    if (warehouseID != null) queryParams['warehouseID'] = warehouseID;
    if (planID != null) queryParams['planID'] = planID;

    final res = await _client.get('/stock-taking-on-duty/in-use-list', queryParameters: queryParams);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => UserStocktakingOnDuty.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 认领盘库值班
  /// POST /stock-taking-on-duty/claim
  Future<int> onDutyClaim({required int warehouseID, required int planID}) async {
    final res = await _client.post('/stock-taking-on-duty/claim', data: {
      'warehouseID': warehouseID,
      'planID': planID,
    });
    return res.data['id'] as int? ?? 0;
  }

  /// 盘库值班交班
  /// POST /stock-taking-on-duty/handover
  Future<int> onDutyHandover({
    required int warehouseID,
    required int planID,
    required int newManager,
  }) async {
    final res = await _client.post('/stock-taking-on-duty/handover', data: {
      'warehouseID': warehouseID,
      'planID': planID,
      'newManager': newManager,
    });
    return res.data['id'] as int? ?? 0;
  }

  /// 指定盘库值班
  /// POST /stock-taking-on-duty/distribution
  Future<int> onDutyDistribution({
    required int warehouseID,
    required int planID,
    required int newManager,
  }) async {
    final res = await _client.post('/stock-taking-on-duty/distribution', data: {
      'warehouseID': warehouseID,
      'planID': planID,
      'newManager': newManager,
    });
    return res.data['id'] as int? ?? 0;
  }

  /// 确认接班
  /// POST /stock-taking-on-duty/receive
  Future<int> onDutyReceive({required int id}) async {
    final res = await _client.post('/stock-taking-on-duty/receive', data: {'id': id});
    return res.data['id'] as int? ?? 0;
  }

  /// 拒绝接班
  /// POST /stock-taking-on-duty/refuse
  Future<bool> onDutyRefuse({required int id, String? remarks}) async {
    final body = <String, dynamic>{'id': id};
    if (remarks != null) body['remarks'] = remarks;
    final res = await _client.post('/stock-taking-on-duty/refuse', data: body);
    return res.data['code'] == 10000;
  }
}
