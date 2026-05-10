import 'api_client.dart';
import '../models/invoice.dart';

/// 发票 API
/// 后端 GET /invoice/* 系列接口
class InvoiceApi {
  final ApiClient _client = ApiClient();

  /// 查询发票列表
  /// 后端 GET /invoice/list，返回 { code, res: [...] }
  Future<List<Invoice>> list({
    List<String>? statuses,
    List<int>? departmentIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'orderBy': [
        {'key': 'createdAt', 'sort': 'desc'}
      ],
    };
    if (statuses != null && statuses.isNotEmpty) queryParams['statuses'] = statuses;
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      queryParams['departmentIDs'] = departmentIDs;
    }
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    // 后端 GET /invoice/list，返回 { code, res: [...] }
    final res = await _client.get('/invoice/list', queryParameters: queryParams);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取发票详情
  /// 后端 GET /invoice/detail，返回 { code, res: { ... } }
  Future<Invoice?> detail(int invoiceID) async {
    // 后端 GET /invoice/detail
    final res = await _client.get('/invoice/detail', queryParameters: {
      'invoiceID': invoiceID,
    });
    final data = res.data['res'];
    if (data == null) return null;
    return Invoice.fromJson(data as Map<String, dynamic>);
  }

  /// 获取发票数量
  /// 后端 GET /invoice/count，返回 { code, res: N }
  Future<int> count({
    List<String>? statuses,
    int? minCreatedAt,
    int? maxCreatedAt,
  }) async {
    final queryParams = <String, dynamic>{};
    if (statuses != null && statuses.isNotEmpty) queryParams['statuses'] = statuses;
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    // 后端 GET /invoice/count
    final res = await _client.get('/invoice/count', queryParameters: queryParams);
    return res.data['res'] as int? ?? 0;
  }

  /// ============================================================
  /// 发票申请相关 API
  /// ============================================================

  /// 校验订单是否可开票（有订单申请）
  /// POST /invoice/check
  Future<InvoiceCheckResult> checkOrder({
    required List<String> orderNumbers,
  }) async {
    final res = await _client.post('/invoice/check', data: {
      'orderNumbers': orderNumbers,
    });
    return InvoiceCheckResult.fromJson(res.data['res'] as Map<String, dynamic>);
  }

  /// 校验无订单是否可开票
  /// POST /invoice/no-order-check
  Future<InvoiceNoOrderCheckResult> checkNoOrder({
    required List<InvoiceNoOrderProduct> orderInfos,
  }) async {
    final res = await _client.post('/invoice/no-order-check', data: {
      'orderInfos': orderInfos.map((e) => e.toJson()).toList(),
    });
    return InvoiceNoOrderCheckResult.fromJson(res.data['res'] as Map<String, dynamic>);
  }

  /// 提交有订单发票申请
  /// POST /invoice/add-audit
  Future<bool> applyWithOrder({
    required String invoiceHeader,
    required String phone,
    required UnitProperties unitProperties,
    required InvoiceMethod invoiceMethod,
    required InvoiceType invoiceType,
    required int invoiceUsci,
    String? email,
    String? taxID,
    String? companyAddress,
    String? companyPhone,
    String? openingBank,
    String? bankAccountNumber,
    required List<String> orderNumbers,
    String? remarks,
  }) async {
    final data = <String, dynamic>{
      'invoiceHeader': invoiceHeader,
      'phone': phone,
      'unitProperties': unitProperties.value,
      'invoiceMethod': invoiceMethod.value,
      'invoiceType': invoiceType.value,
      'invoiceUsci': invoiceUsci,
      'orderNumbers': orderNumbers,
    };
    if (email != null) data['email'] = email;
    if (taxID != null) data['taxID'] = taxID;
    if (companyAddress != null) data['companyAddress'] = companyAddress;
    if (companyPhone != null) data['companyPhone'] = companyPhone;
    if (openingBank != null) data['openingBank'] = openingBank;
    if (bankAccountNumber != null) data['bankAccountNumber'] = bankAccountNumber;
    if (remarks != null) data['remarks'] = remarks;

    final res = await _client.post('/invoice/add-audit', data: data);
    return res.data['res'] as bool? ?? false;
  }

  /// 提交无订单发票申请
  /// POST /invoice/add
  Future<bool> applyNoOrder({
    required String invoiceHeader,
    required String phone,
    required UnitProperties unitProperties,
    required InvoiceMethod invoiceMethod,
    required InvoiceType invoiceType,
    required int invoiceUsci,
    String? email,
    String? taxID,
    String? companyAddress,
    String? companyPhone,
    String? openingBank,
    String? bankAccountNumber,
    String? remarks,
    required List<InvoiceNoOrderProduct> orderInfos,
  }) async {
    final data = <String, dynamic>{
      'invoiceHeader': invoiceHeader,
      'phone': phone,
      'unitProperties': unitProperties.value,
      'invoiceMethod': invoiceMethod.value,
      'invoiceType': invoiceType.value,
      'invoiceUsci': invoiceUsci,
      'orderInfos': orderInfos.map((e) => e.toJson()).toList(),
    };
    if (email != null) data['email'] = email;
    if (taxID != null) data['taxID'] = taxID;
    if (companyAddress != null) data['companyAddress'] = companyAddress;
    if (companyPhone != null) data['companyPhone'] = companyPhone;
    if (openingBank != null) data['openingBank'] = openingBank;
    if (bankAccountNumber != null) data['bankAccountNumber'] = bankAccountNumber;
    if (remarks != null) data['remarks'] = remarks;

    final res = await _client.post('/invoice/add', data: data);
    return res.data['res'] as bool? ?? false;
  }

  /// 获取可开票订单列表（根据手机号查询）
  /// GET /invoice/order-info?memberIdent=xxx
  Future<List<InvoiceCheckOrderInfo>> getOrderInfoByMember(int memberIdent) async {
    final res = await _client.get('/invoice/order-info', queryParameters: {
      'memberIdent': memberIdent,
    });
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => InvoiceCheckOrderInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取系统设置（税率）
  /// GET /sys-setting/list
  Future<Map<String, dynamic>?> getSysSetting({
    required List<String> keys,
  }) async {
    try {
      final res = await _client.get('/sys-setting/list', queryParameters: {
        'keys': keys.join(','),
      });
      return res.data['res'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }
}
