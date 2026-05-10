import 'api_client.dart';
import '../models/accounting_voucher.dart';

class AccountingVoucherApi {
  final _client = ApiClient();

  /// 凭证列表
  /// 后端 GET /voucher/list，返回 { code, list: [...] }
  Future<List<AccountingVoucher>> list({
    int? year,
    int? month,
    int? state,
    int? type,
    int? sysVoucherType,
    int? creator,
    int? auditor,
    int limit = 20,
    int offset = 0,
    bool descending = true,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (year != null) queryParams['year'] = year;
    if (month != null) queryParams['month'] = month;
    if (state != null) queryParams['state'] = state;
    if (type != null) queryParams['type'] = type;
    if (sysVoucherType != null) queryParams['sysVoucherType'] = sysVoucherType;
    if (creator != null) queryParams['creator'] = creator;
    if (auditor != null) queryParams['auditor'] = auditor;

    final res = await _client.get('/voucher/list', queryParameters: queryParams);
    // 后端返回 { code, list: [...] }
    final list = res.data['list'] as List?;
    if (list == null) return [];
    return list.map((e) => AccountingVoucher.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 凭证总数
  /// 后端 GET /voucher/count，返回 { code, count: N }
  Future<int> count({
    int? year,
    int? month,
    int? state,
    int? type,
  }) async {
    final queryParams = <String, dynamic>{};
    if (year != null) queryParams['year'] = year;
    if (month != null) queryParams['month'] = month;
    if (state != null) queryParams['state'] = state;
    if (type != null) queryParams['type'] = type;

    final res = await _client.get('/voucher/count', queryParameters: queryParams);
    // 后端返回 { code, count: N }
    return res.data['count'] as int? ?? 0;
  }

  /// 凭证详情（含审核相关字段）
  /// 后端 GET /voucher/details?voucherIDs=X
  /// 返回 { code, res: [...] }
  Future<AccountingVoucher?> details(List<int> ids) async {
    if (ids.isEmpty) return null;
    final res = await _client.get(
      '/voucher/details',
      queryParameters: {'voucherIDs': ids.join(',')},
    );
    final data = res.data;
    final list = data is Map<String, dynamic>
        ? (data['res'] as List?)
        : (data['list'] as List?);
    if (list == null || list.isEmpty) return null;
    return AccountingVoucher.fromJson(list[0] as Map<String, dynamic>);
  }

  /// 凭证分录列表
  /// 后端 GET /journal-entry/list?ids=X
  /// 返回 { code, list: [...] }
  Future<List<JournalEntry>> journalEntryList(List<int> voucherIds) async {
    if (voucherIds.isEmpty) return [];
    final res = await _client.get(
      '/journal-entry/list',
      queryParameters: {'ids': voucherIds.join(',')},
    );
    final list = res.data['list'] as List?;
    if (list == null) return [];
    return list.map((e) => JournalEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 审核凭证
  /// 后端 POST /voucher/audit，body: {voucherID: X}
  Future<bool> audit(int voucherID) async {
    final res = await _client.post(
      '/voucher/audit',
      data: {'voucherID': voucherID},
    );
    final code = res.data['code'];
    return code == 10000 || code == 0 || code == 200;
  }

  /// 驳回凭证
  /// 后端 POST /voucher/reject，body: {voucherID: X}
  Future<bool> reject(int voucherID) async {
    final res = await _client.post(
      '/voucher/reject',
      data: {'voucherID': voucherID},
    );
    final code = res.data['code'];
    return code == 10000 || code == 0 || code == 200;
  }
}
