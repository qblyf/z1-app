import '../models/financial_expense.dart';
import 'api_client.dart';

final financialExpenseApi = FinancialExpenseApi();

class FinancialExpenseApi {
  final ApiClient _client = ApiClient();

  /// 财务支出列表
  Future<List<FinancialExpenseItem>> list({
    List<String>? numbers,
    int? type,
    int? status,
    String? title,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (numbers != null && numbers.isNotEmpty) 'financialExpensesNumbers': numbers.join(','),
      if (type != null) 'financialExpensesTypes': type,
      if (status != null) 'status': status,
      if (title != null && title.isNotEmpty) 'title': title,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };
    // 后端 GET /financial-expenses/list，返回 { code, res: [...] }
    final res = await _client.get('/financial-expenses/list', queryParameters: queryParams);
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => FinancialExpenseItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 财务支出详情（完整版，含 infos）
  /// 后端 GET /financial-expenses/detail，返回 { code, res: {...} } FinancialExpenses 类型
  Future<FinancialExpense?> fullDetail(int id) async {
    final res = await _client.get(
      '/financial-expenses/detail',
      queryParameters: {'financialExpensesIDs': id.toString()},
    );
    final r = res.data['res'];
    if (r == null || (r is List && r.isEmpty)) return null;
    if (r is List) return FinancialExpense.fromJson(r[0] as Map<String, dynamic>);
    if (r is Map<String, dynamic>) return FinancialExpense.fromJson(r);
    return null;
  }

  /// 创建财务结算单审批
  /// 后端 POST /financial-expenses/settle-add，返回审批ID
  Future<int?> addSettlementApproval({
    required int financialExpensesType,
    required String businessType,
    required String title,
    required String content,
    required List<SettlementInfo> infos,
    required int settleAmount,
    required String associated,
  }) async {
    final body = <String, dynamic>{
      'financialExpensesType': financialExpensesType,
      'businessType': businessType,
      'title': title,
      'content': content,
      'infos': infos.map((e) => e.toJson()).toList(),
      'settleAmount': settleAmount,
      'associated': associated,
    };
    final res = await _client.post('/financial-expenses/settle-add', data: body);
    final id = res.data['res'];
    return id is int ? id : null;
  }

  /// 财务支出数量
  Future<FinancialExpenseSummary> count({
    int? type,
    int? status,
    String? title,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{
      if (type != null) 'financialExpensesTypes': type,
      if (status != null) 'status': status,
      if (title != null && title.isNotEmpty) 'title': title,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
    };
    // 后端 GET /financial-expenses/count，返回 { code, res: { count, totalAmount } }
    final res = await _client.get('/financial-expenses/count', queryParameters: queryParams);
    final r = res.data['res'];
    if (r is Map<String, dynamic>) return FinancialExpenseSummary.fromJson(r);
    return const FinancialExpenseSummary();
  }
}
