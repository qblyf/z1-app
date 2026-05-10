import 'api_client.dart';
import '../models/cashier_daily_report.dart';

/// 收银日报 API
/// 后端路径: /cashier-daily-report/*
class CashierDailyReportApi {
  final ApiClient _client = ApiClient();

  /// 查询收银日报列表
  Future<List<CashierDailyReport>> list({
    int? minCashierTime,
    int? maxCashierTime,
    List<int>? departmentIDs,
    List<String>? states,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (minCashierTime != null) queryParams['minCashierTime'] = minCashierTime;
    if (maxCashierTime != null) queryParams['maxCashierTime'] = maxCashierTime;
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      queryParams['departmentIDs'] = departmentIDs.join(',');
    }
    if (states != null && states.isNotEmpty) {
      queryParams['states'] = states.join(',');
    }

    final res = await _client.get('/cashier-daily-report/list', queryParameters: queryParams);
    // 后端返回 { code, list }
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data
        .map((e) => CashierDailyReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 查询收银日报列表数量
  Future<int> count({
    int? minCashierTime,
    int? maxCashierTime,
    List<int>? departmentIDs,
    List<String>? states,
  }) async {
    final queryParams = <String, dynamic>{};
    if (minCashierTime != null) queryParams['minCashierTime'] = minCashierTime;
    if (maxCashierTime != null) queryParams['maxCashierTime'] = maxCashierTime;
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      queryParams['departmentIDs'] = departmentIDs.join(',');
    }
    if (states != null && states.isNotEmpty) {
      queryParams['states'] = states.join(',');
    }

    final res = await _client.get('/cashier-daily-report/count', queryParameters: queryParams);
    // 后端返回 { code, res: { count: N } }
    final r = res.data['res'];
    if (r is Map<String, dynamic>) return r['count'] as int? ?? 0;
    return 0;
  }

  /// 获取收银日报详情
  Future<CashierDailyReport?> detail({
    required String date,
    required int departmentID,
  }) async {
    final res = await _client.get(
      '/cashier-daily-report/detail',
      queryParameters: {
        'date': date,
        'departmentID': departmentID,
      },
    );
    // 后端返回 { code, res: {...} }
    final data = res.data['res'];
    if (data == null) return null;
    return CashierDailyReport.fromJson(data as Map<String, dynamic>);
  }

  /// 创建收银日报表
  Future<int> add({
    required String date,
    required List<Map<String, dynamic>> posIncome,
    required List<Map<String, dynamic>> otherIncome,
    String? remarks,
    List<Map<String, dynamic>>? bankAccountIncome,
    List<String>? images,
  }) async {
    final body = <String, dynamic>{
      'date': date,
      'posIncome': posIncome,
      'otherIncome': otherIncome,
    };
    if (remarks != null) body['remarks'] = remarks;
    if (bankAccountIncome != null) {
      body['bankAccountIncome'] = bankAccountIncome;
    }
    if (images != null) body['images'] = images;

    final res = await _client.post('/cashier-daily-report/add', data: body);
    return res.data['res'] as int? ?? 0;
  }

  /// 编辑收银日报表
  Future<bool> edit({
    required int id,
    required List<Map<String, dynamic>> posIncome,
    required List<Map<String, dynamic>> otherIncome,
    String? remarks,
    List<Map<String, dynamic>>? bankAccountIncome,
    List<String>? images,
  }) async {
    final body = <String, dynamic>{
      'id': id,
      'posIncome': posIncome,
      'otherIncome': otherIncome,
    };
    if (remarks != null) body['remarks'] = remarks;
    if (bankAccountIncome != null) {
      body['bankAccountIncome'] = bankAccountIncome;
    }
    if (images != null) body['images'] = images;

    final res = await _client.post('/cashier-daily-report/edit', data: body);
    return res.data['res'] == true;
  }

  /// 审核收银日报表
  Future<bool> audit({
    required String date,
    required List<int> departmentIDs,
    String? remarks,
    int? voucherTime,
  }) async {
    final body = <String, dynamic>{
      'date': date,
      'departmentIDs': departmentIDs,
    };
    if (remarks != null) body['remarks'] = remarks;
    if (voucherTime != null) body['voucherTime'] = voucherTime;

    // 后端审核路径是 /cashier-daily-report/audited
    final res = await _client.post('/cashier-daily-report/audited', data: body);
    return res.data['res'] == true;
  }
}
