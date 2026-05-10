import 'package:z1_app/api/api_client.dart';
import '../models/approval.dart';

/// 审批 API 服务
/// 后端路径参考:
/// - z1-mid/src/model/z1/approval.ts (审批列表/计数)
/// - z1-mid/src/s1/approval.ts (审批实例)
class ApprovalApi {
  final ApiClient _client = ApiClient();

  /// 获取审批列表
  /// 后端 GET /approval/list，返回 { code, list: [...] }
  Future<List<Approval>> getList({
    int? status,
    String? type,
    int? applicantId,
    int? approverId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (applicantId != null) 'createdBy': applicantId,
      if (approverId != null) 'approverId': approverId,
      'limit': limit,
      'offset': offset,
    };

    // 后端 GET /approval/list，返回 { code, list: [...] }
    final response = await _client.get(
      '/approval/list',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data['list'] is List) {
      return (data['list'] as List)
          .map((e) => Approval.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取待我审批的列表
  /// 后端 GET /approval-instance/pending-list，返回 { code, res: [...] }
  Future<List<Approval>> getPending() async {
    // 后端 GET /approval-instance/pending-list，返回 { code, res: [...] }
    final response = await _client.get('/approval-instance/pending-list');
    final data = response.data;
    // 后端返回 { code, res: [...] }，res 是数组
    if (data['res'] is List) {
      return (data['res'] as List)
          .map((e) => Approval.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取我发起的审批
  /// 后端 GET /approval-instance/processed-list，返回 { code, res: [...] }
  Future<List<Approval>> getMyApplications() async {
    // 后端 GET /approval-instance/processed-list
    final response = await _client.get('/approval-instance/processed-list');
    final data = response.data;
    // 后端返回 { code, res: [...] }
    if (data['res'] is List) {
      return (data['res'] as List)
          .map((e) => Approval.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取审批详情
  /// 后端 GET /approval-instance/detail，返回 { code, res: { ... } }
  Future<Approval> getDetail(String id) async {
    // 后端 GET /approval-instance/detail
    final response = await _client.get(
      '/approval-instance/detail',
      queryParameters: {'id': id},
    );
    final data = response.data;
    if (data['res'] != null) {
      return Approval.fromJson(data['res'] as Map<String, dynamic>);
    }
    throw Exception('未找到审批记录');
  }

  /// 提交审批
  /// 后端 POST /approval-instance/add
  Future<String> submit({
    required String title,
    required ApprovalType type,
    required Map<String, dynamic> formData,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'type': type.value,
      'formData': formData,
      if (description != null) 'description': description,
    };

    // 后端 POST /approval-instance/add
    final response = await _client.post('/approval-instance/add', data: body);
    // 后端返回 { code, res: N }
    return response.data['res']?.toString() ?? '';
  }

  /// 审批（通过/拒绝）
  /// 后端 POST /approval-instance/audit，返回 { code, res: true/false }
  Future<bool> process({
    required String id,
    required bool approved,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'id': id,
      'approved': approved,
      if (comment != null) 'comment': comment,
    };

    // 后端 POST /approval-instance/audit
    final response = await _client.post('/approval-instance/audit', data: body);
    // 后端返回 { code, res: boolean }
    return response.data['res'] == true;
  }

  /// 撤回审批
  /// 后端 POST /approval-instance/cancel，返回 { code, res: true/false }
  Future<bool> cancel(String id) async {
    // 后端 POST /approval-instance/cancel
    final response = await _client.post('/approval-instance/cancel', data: {'id': id});
    // 后端返回 { code, res: boolean }
    return response.data['res'] == true;
  }
}
