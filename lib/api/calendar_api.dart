import 'package:z1_app/api/api_client.dart';
import '../models/calendar.dart';

/// 行事历 API 服务
/// 后端路径参考 z1-mid/src/model/z1/task-log.ts
class CalendarApi {
  final ApiClient _client = ApiClient();

  /// 获取行事历列表
  Future<List<CalendarTask>> getList({
    int? assignee,
    int? status,
    int? startTime,
    int? endTime,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (assignee != null) 'assignee': assignee,
      if (status != null) 'status': status,
      if (startTime != null) 'minStartTime': startTime,
      if (endTime != null) 'maxEndTime': endTime,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get(
      '/task-log/calendar-list',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data['list'] is List) {
      return (data['list'] as List)
          .map((e) => CalendarTask.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取进行中的行事历
  Future<List<CalendarTask>> getInProgress({String currentUserType = 'responsible'}) async {
    final response = await _client.get(
      '/task-log/my-calendar-list',
      queryParameters: {'currentUserType': currentUserType},
    );
    final data = response.data;
    if (data['list'] is List) {
      return (data['list'] as List)
          .map((e) => CalendarTask.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取已结束的行事历
  Future<List<CalendarTask>> getExpired({int limit = 20, int offset = 0}) async {
    final response = await _client.get(
      '/task-log/my-overdue-calendar-list',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data;
    if (data['list'] is List) {
      return (data['list'] as List)
          .map((e) => CalendarTask.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取待验收的行事历
  Future<List<CalendarTask>> getPendingCheck() async {
    final response = await _client.get('/task-log/my-check-calendar');
    final data = response.data;
    if (data['list'] is List) {
      return (data['list'] as List)
          .map((e) => CalendarTask.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取行事历详情
  Future<CalendarTask> getDetail(String id) async {
    final response = await _client.get(
      '/task-log/calendar-detail',
      queryParameters: {'p': id},
    );
    final data = response.data;
    if (data['res'] != null) {
      return CalendarTask.fromJson(data['res'] as Map<String, dynamic>);
    }
    throw Exception('未找到行事历');
  }

  /// 验收行事历（签到/验收共用）
  Future<bool> approve(String id, {String? remark}) async {
    final body = <String, dynamic>{
      'p': id,
      if (remark != null) 'remark': remark,
    };

    final response = await _client.post('/task-log/check', data: body);
    return response.data['res'] == true;
  }

  /// 完成任务
  Future<bool> complete(String id, {String? remark}) async {
    final body = <String, dynamic>{
      'p': id,
      if (remark != null) 'remark': remark,
    };

    final response = await _client.post('/task-log/self-evaluation-finished', data: body);
    return response.data['res'] == true;
  }

  /// 签到（使用验收接口）
  Future<bool> checkIn(String id, {String? location, String? remark}) async {
    final body = <String, dynamic>{
      'p': id,
      if (location != null) 'location': location,
      if (remark != null) 'remark': remark,
    };

    final response = await _client.post('/task-log/check', data: body);
    return response.data['res'] == true;
  }

  /// 签退
  Future<bool> checkOut(String id, {String? remark}) async {
    final body = <String, dynamic>{
      'p': id,
      if (remark != null) 'remark': remark,
    };

    final response = await _client.post('/task-log/review', data: body);
    return response.data['res'] == true;
  }

  /// 获取我的行事历列表（按用户类型筛选）
  /// GET /task-log/my-calendar-list
  /// currentUserType: responsible(责任人) / checked(验收人) / send(抄送人)
  Future<List<CalendarSendTask>> getMyCalendarList({
    required String currentUserType,
    List<int>? responsibleEmployees,
    String? taskName,
    List<String>? taskLogStatus,
    int? statStartAt,
    int? statEndAt,
    int limit = 300,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'currentUserType': currentUserType,
      if (responsibleEmployees != null && responsibleEmployees.isNotEmpty)
        'responsibleEmployees': responsibleEmployees,
      if (taskName != null && taskName.isNotEmpty) 'taskName': taskName,
      if (taskLogStatus != null && taskLogStatus.isNotEmpty)
        'taskLogStatus': taskLogStatus,
      if (statStartAt != null) 'statStartAt': statStartAt,
      if (statEndAt != null) 'statEndAt': statEndAt,
      'limit': limit,
      'offset': offset,
    };

    final response = await _client.get(
      '/task-log/my-calendar-list',
      queryParameters: params,
    );
    final data = response.data['list'] as List<dynamic>? ?? [];
    return data.map((e) => CalendarSendTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取我的行事历列表数量统计
  /// GET /task-log/my-calendar-count
  Future<List<CalendarStatusCount>> getMyCalendarCount({
    required String currentUserType,
    List<int>? responsibleEmployees,
    String? taskName,
    List<String>? taskLogStatus,
    int? statStartAt,
    int? statEndAt,
  }) async {
    final params = <String, dynamic>{
      'currentUserType': currentUserType,
      if (responsibleEmployees != null && responsibleEmployees.isNotEmpty)
        'responsibleEmployees': responsibleEmployees,
      if (taskName != null && taskName.isNotEmpty) 'taskName': taskName,
      if (taskLogStatus != null && taskLogStatus.isNotEmpty)
        'taskLogStatus': taskLogStatus,
      if (statStartAt != null) 'statStartAt': statStartAt,
      if (statEndAt != null) 'statEndAt': statEndAt,
    };

    final response = await _client.get(
      '/task-log/my-calendar-count',
      queryParameters: params,
    );
    final data = response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => CalendarStatusCount.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取当前用户可验收的行事历列表
  /// GET /task-log/my-check-calendar
  Future<List<CalendarSendTask>> getMyCheckCalendar() async {
    final response = await _client.get('/task-log/my-check-calendar');
    final data = response.data['list'] as List<dynamic>? ?? [];
    return data.map((e) => CalendarSendTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取已过期的行事历列表
  /// GET /task-log/my-overdue-calendar-list
  Future<List<CalendarSendTask>> getMyOverdueCalendarList({
    int? startAt,
    int? endAt,
    int limit = 300,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      if (startAt != null) 'statStartAt': startAt,
      if (endAt != null) 'statEndAt': endAt,
    };
    final response = await _client.get(
      '/task-log/my-overdue-calendar-list',
      queryParameters: params,
    );
    final data = response.data['list'] as List<dynamic>? ?? [];
    return data.map((e) => CalendarSendTask.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// 行事历状态统计
class CalendarStatusCount {
  final String status;
  final int count;

  CalendarStatusCount({required this.status, required this.count});

  factory CalendarStatusCount.fromJson(Map<String, dynamic> json) {
    return CalendarStatusCount(
      status: json['status'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

/// 行事历抄送任务（用于抄送列表）
class CalendarSendTask {
  final int? categoryID;
  final String? categoryName;
  final String taskName;
  final String? introduction;
  final List<dynamic> labelIDs;
  final int taskLogID;
  final String taskLogStatus;
  final int responsibleEmployee;
  final int startAt;
  final int duration;
  final bool isNeedSelfEvaluation;
  final String? allowCheckType;
  final int? lastCheckBy;
  final int? checkScore;
  final List<int> readUser;
  final int? taskWeight;
  final int? giveTaskWeight;
  final int? lastScore;

  CalendarSendTask({
    this.categoryID,
    this.categoryName,
    required this.taskName,
    this.introduction,
    this.labelIDs = const [],
    required this.taskLogID,
    required this.taskLogStatus,
    required this.responsibleEmployee,
    required this.startAt,
    required this.duration,
    required this.isNeedSelfEvaluation,
    this.allowCheckType,
    this.lastCheckBy,
    this.checkScore,
    this.readUser = const [],
    this.taskWeight,
    this.giveTaskWeight,
    this.lastScore,
  });

  factory CalendarSendTask.fromJson(Map<String, dynamic> json) {
    return CalendarSendTask(
      categoryID: json['categoryID'] as int?,
      categoryName: json['categoryName'] as String?,
      taskName: json['taskName'] as String? ?? '',
      introduction: json['introduction'] as String?,
      labelIDs: json['labelIDs'] as List<dynamic>? ?? [],
      taskLogID: json['taskLogID'] as int? ?? 0,
      taskLogStatus: json['taskLogStatus'] as String? ?? '',
      responsibleEmployee: json['responsibleEmployee'] as int? ?? 0,
      startAt: json['startAt'] as int? ?? 0,
      duration: json['duration'] as int? ?? 0,
      isNeedSelfEvaluation: json['isNeedSelfEvaluation'] as bool? ?? false,
      allowCheckType: json['allowCheckType'] as String?,
      lastCheckBy: json['lastCheckBy'] as int?,
      checkScore: json['checkScore'] as int?,
      readUser: (json['readUser'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      taskWeight: json['taskWeight'] as int?,
      giveTaskWeight: json['giveTaskWeight'] as int?,
      lastScore: json['lastScore'] as int?,
    );
  }
}
