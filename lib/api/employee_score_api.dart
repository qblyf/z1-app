import 'package:z1_app/api/api_client.dart';
import 'package:z1_app/models/employee_score.dart';

/// 员工积分 API 服务
/// 对应 z1-mid 后端 department-employee-score 系列接口
class EmployeeScoreApi {
  final ApiClient _client = ApiClient();

  // ── 积分分类 ────────────────────────────────────────────────

  /// 获取积分分类列表
  Future<List<ScoreClass>> getClassList() async {
    // 后端 GET /department-employee-score-class/list，返回 { code, list: [...] }
    final response = await _client.get('/department-employee-score-class/list');
    final list = response.data['list'] ?? response.data['res'];
    if (list is List) {
      return list.map((e) => ScoreClass.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ── 积分申报 ───────────────────────────────────────────────

  /// 获取积分申报列表
  Future<List<ScoreApply>> getApplyList({
    int? status,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (status != null) 'status': status,
      if (minCreatedAt != null) 'minCreatedAt': minCreatedAt,
      if (maxCreatedAt != null) 'maxCreatedAt': maxCreatedAt,
      'limit': limit,
      'offset': offset,
    };
    // 后端 GET /department-employee-score-apply/list，返回 { code, res: [...] }
    final response = await _client.get(
      '/department-employee-score-apply/list',
      queryParameters: queryParams,
    );
    final list = response.data['res'] ?? response.data['list'];
    if (list is List) {
      return list.map((e) => ScoreApply.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取积分申报详情
  Future<ScoreApply> getApplyDetail(int id) async {
    // 后端 GET /department-employee-score-apply/detail?id=X
    final response = await _client.get(
      '/department-employee-score-apply/detail',
      queryParameters: {'id': id},
    );
    final res = response.data['res'] ?? response.data;
    if (res is Map<String, dynamic>) {
      return ScoreApply.fromJson(res);
    }
    throw Exception('未找到申报记录');
  }

  /// 新建积分申报
  Future<int> addApply({
    required String title,
    required int classId,
    required int happenedAt,
    String? description,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.post(
      '/department-employee-score-apply/add',
      data: {
        'title': title,
        'classID': classId,
        'happenedAt': happenedAt,
        if (description != null) 'description': description,
        'info': items,
      },
    );
    return response.data['res'] as int? ?? 0;
  }

  /// 确认申报（管理员）
  Future<bool> confirmApply(int id) async {
    final response = await _client.post(
      '/department-employee-score-apply/confirm',
      data: {'id': id},
    );
    return response.data['res'] == true;
  }

  /// 拒绝申报（管理员）
  Future<bool> rejectApply(int id, {String? reason}) async {
    final response = await _client.post(
      '/department-employee-score-apply/reject',
      data: {
        'id': id,
        if (reason != null) 'reason': reason,
      },
    );
    return response.data['res'] == true;
  }

  // ── 积分发放 ───────────────────────────────────────────────

  /// 获取当前用户积分余额
  Future<CurrentUserScore> getCurrentUserScore() async {
    // 后端 GET /department-score-recharge-log/statistics
    final response = await _client.get('/department-score-recharge-log/statistics');
    final res = response.data['res'] ?? response.data;
    if (res is Map<String, dynamic>) {
      return CurrentUserScore.fromJson(res);
    }
    return const CurrentUserScore();
  }

  /// 发放积分给员工
  Future<bool> giveScore({
    required int employeeId,
    required int score,
    required int classId,
    int? departmentId,
    String? remark,
    int? happenedAt,
  }) async {
    final response = await _client.post(
      '/department-employee-score-give-log/give',
      data: {
        'employeeID': employeeId,
        'score': score,
        'classID': classId,
        if (departmentId != null) 'departmentID': departmentId,
        if (remark != null) 'remark': remark,
        if (happenedAt != null) 'happenedAt': happenedAt,
      },
    );
    return response.data['res'] == true;
  }

  /// 获取积分发放记录列表
  Future<List<ScoreGiveLog>> getGiveLogList({
    int? employeeId,
    int? departmentId,
    int? classId,
    int? minGivenAt,
    int? maxGivenAt,
    int limit = 20,
    int offset = 0,
  }) async {
    // 后端 GET /department-employee-score-give-log/details-list
    final response = await _client.get(
      '/department-employee-score-give-log/details-list',
      queryParameters: {
        if (employeeId != null) 'employees': [employeeId],
        if (departmentId != null) 'emplDepartmentIDs': [departmentId],
        if (classId != null) 'classIDs': [classId],
        if (minGivenAt != null) 'minGiveAt': minGivenAt,
        if (maxGivenAt != null) 'maxGiveAt': maxGivenAt,
        'limit': limit,
        'offset': offset,
      },
    );
    final list = response.data['res'] ?? response.data['list'];
    if (list is List) {
      return list.map((e) => ScoreGiveLog.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取积分发放明细列表（支持多员工/多部门过滤）
  /// 对应 PWA reward-punishment-details.tsx
  Future<List<ScoreGiveLog>> getGiveLogDetailsList({
    List<int>? employeeIdents,
    List<int>? departmentIds,
    List<int>? classIds,
    int? minGiveAt,
    int? maxGiveAt,
    int? scoreFrom,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (employeeIdents != null && employeeIdents.isNotEmpty) {
      queryParams['employees'] = employeeIdents;
    }
    if (departmentIds != null && departmentIds.isNotEmpty) {
      queryParams['emplDepartmentIDs'] = departmentIds;
    }
    if (classIds != null && classIds.isNotEmpty) {
      queryParams['classIDs'] = classIds;
    }
    if (minGiveAt != null) queryParams['minGiveAt'] = minGiveAt;
    if (maxGiveAt != null) queryParams['maxGiveAt'] = maxGiveAt;
    if (scoreFrom != null) queryParams['scoreFrom'] = scoreFrom;

    // 后端 GET /department-employee-score-give-log/details-list
    final response = await _client.get(
      '/department-employee-score-give-log/details-list',
      queryParameters: queryParams,
    );
    final list = response.data['res'] ?? response.data['list'];
    if (list is List) {
      return list.map((e) => ScoreGiveLog.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取积分发放明细总数
  Future<int> getGiveLogDetailsCount({
    List<int>? employeeIdents,
    List<int>? departmentIds,
    List<int>? classIds,
    int? minGiveAt,
    int? maxGiveAt,
    int? scoreFrom,
  }) async {
    final queryParams = <String, dynamic>{};
    if (employeeIdents != null && employeeIdents.isNotEmpty) {
      queryParams['employees'] = employeeIdents;
    }
    if (departmentIds != null && departmentIds.isNotEmpty) {
      queryParams['emplDepartmentIDs'] = departmentIds;
    }
    if (classIds != null && classIds.isNotEmpty) {
      queryParams['classIDs'] = classIds;
    }
    if (minGiveAt != null) queryParams['minGiveAt'] = minGiveAt;
    if (maxGiveAt != null) queryParams['maxGiveAt'] = maxGiveAt;
    if (scoreFrom != null) queryParams['scoreFrom'] = scoreFrom;

    // 后端 GET /department-employee-score-give-log/details-count
    final response = await _client.get(
      '/department-employee-score-give-log/details-count',
      queryParameters: queryParams,
    );
    final res = response.data['res'] ?? response.data;
    if (res is Map<String, dynamic>) {
      return (res['count'] as num?)?.toInt() ?? 0;
    }
    if (res is num) return res.toInt();
    return 0;
  }

  /// 获取积分统计（红黑榜）
  Future<List<ScoreRanking>> getScoreRanking({
    int? departmentId,
    int? classId,
    String? orderBy,
  }) async {
    // 后端 GET /department-employee-score-give-log/info
    final response = await _client.get(
      '/department-employee-score-give-log/info',
      queryParameters: {
        if (departmentId != null) 'departmentID': departmentId,
        if (classId != null) 'classID': classId,
        if (orderBy != null) 'orderBy': orderBy,
      },
    );
    final list = response.data['list'] ?? response.data['res'] ?? response.data;
    if (list is List) {
      return list.map((e) => ScoreRanking.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取部门积分统计
  Future<Map<String, dynamic>> getDepartmentScoreInfo() async {
    // 后端 GET /department-score-recharge-log/statistics
    final response = await _client.get('/department-score-recharge-log/statistics');
    return response.data['res'] as Map<String, dynamic>? ?? response.data;
  }

  // ── 员工查询 ───────────────────────────────────────────────

  /// 根据 ID 获取员工信息
  Future<Map<String, dynamic>?> getEmployeeByIdents(List<int> idents) async {
    if (idents.isEmpty) return null;
    // 后端 GET /employee/idents?idents=X,Y,Z
    final response = await _client.get(
      '/employee/idents',
      queryParameters: {'idents': idents.join(',')},
    );
    final list = response.data['list'] ?? response.data['res'];
    if (list is List && list.isNotEmpty) {
      return list[0] as Map<String, dynamic>;
    }
    return null;
  }

  // ── 分组排名（对应 PWA statistic.tsx） ───────────────────────────────

  /// 获取工分类别分组列表
  Future<List<DepartmentEmployeeScoreClassGroup>> getScoreClassGroupList() async {
    // 后端 GET /department-employee-score-class-group/list
    final response = await _client.get('/department-employee-score-class-group/list');
    final res = response.data['res'] ?? response.data;
    if (res is List) {
      return res.map((e) => DepartmentEmployeeScoreClassGroup.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取工分类别分组详情（按ID批量）
  Future<List<DepartmentEmployeeScoreClassGroup>> getScoreClassGroupDetail(List<int> ids) async {
    if (ids.isEmpty) return [];
    // 后端 GET /department-employee-score-class-group/detail?ids=X,Y,Z
    final response = await _client.get(
      '/department-employee-score-class-group/detail',
      queryParameters: {'ids': ids.join(',')},
    );
    final res = response.data['res'] ?? response.data;
    if (res is List) {
      return res.map((e) => DepartmentEmployeeScoreClassGroup.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取工分类别列表（支持过滤）
  Future<List<DepartmentEmployeeScoreClass>> getScoreClassList({bool? isHide}) async {
    // 后端 GET /department-employee-score-class/list
    final queryParams = <String, dynamic>{};
    if (isHide != null) queryParams['isHide'] = isHide;
    final response = await _client.get(
      '/department-employee-score-class/list',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final res = response.data['res'] ?? response.data['list'] ?? response.data;
    if (res is List) {
      return res.map((e) => DepartmentEmployeeScoreClass.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取职员得分统计（分组维度）
  /// 对应 PWA: departmentEmployeeScoreGiveLogInfo
  /// GET /department-employee-score-give-log/score-info?deptIDs=X&groupIDs=Y,Z
  Future<List<EmployeeScoreGiveLogInfo>> getScoreGiveLogInfo({
    List<int>? deptIds,
    required List<int> groupIds,
  }) async {
    final queryParams = <String, dynamic>{};
    if (deptIds != null && deptIds.isNotEmpty) {
      queryParams['deptIDs'] = deptIds;
    }
    if (groupIds.isNotEmpty) queryParams['groupIDs'] = groupIds;

    final response = await _client.get(
      '/department-employee-score-give-log/score-info',
      queryParameters: queryParams,
    );
    final res = response.data['res'] ?? response.data;
    if (res is List) {
      return res.map((e) => EmployeeScoreGiveLogInfo.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
