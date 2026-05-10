import 'api_client.dart';

/// 仓库 API
/// 对应后端 /warehouse/* 系列接口
class WarehouseApi {
  final ApiClient _client = ApiClient();

  /// 获取当前用户管理的仓库列表
  /// 后端 GET /warehouse/manager-list
  Future<List<WarehouseInfo>> getManagerWarehouses() async {
    final res = await _client.get('/warehouse/manager-list');
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => WarehouseInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 根据部门ID获取仓库ID列表
  /// 后端 GET /warehouse/ids-by-department
  Future<List<int>> getWarehouseIdsByDeptId(int departmentId) async {
    final res = await _client.get(
      '/warehouse/ids-by-department',
      queryParameters: {'departmentID': departmentId},
    );
    final data = res.data['res'];
    if (data is List) return data.cast<int>();
    if (data is String) return [];
    return [];
  }

  /// 根据仓库ID列表获取仓库详情
  /// 后端 GET /warehouse/detail-by-ids
  Future<List<WarehouseInfo>> getWarehousesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final res = await _client.get(
      '/warehouse/detail-by-ids',
      queryParameters: {'ids': ids.join(',')},
    );
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data
        .map((e) => WarehouseInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取仓库列表
  /// 后端 GET /warehouse/list
  Future<List<WarehouseInfo>> list({
    List<int>? ids,
    String? keyword,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (ids != null && ids.isNotEmpty) {
      queryParams['ids'] = ids.join(',');
    }
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    final res = await _client.get('/warehouse/list', queryParameters: queryParams);
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data
        .map((e) => WarehouseInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// 仓库信息
class WarehouseInfo {
  final int id;
  final String? number;
  final String? name;
  final String? spell;
  final String? address;
  final int? departmentID;
  final String? departmentName;
  final String? principalName;
  final String? principalPhone;
  final int? totalStock;
  final int? status;

  const WarehouseInfo({
    required this.id,
    this.number,
    this.name,
    this.spell,
    this.address,
    this.departmentID,
    this.departmentName,
    this.principalName,
    this.principalPhone,
    this.totalStock,
    this.status,
  });

  factory WarehouseInfo.fromJson(Map<String, dynamic> json) {
    return WarehouseInfo(
      id: json['id'] as int? ?? 0,
      number: json['number'] as String?,
      name: json['name'] as String?,
      spell: json['spell'] as String?,
      address: json['address'] as String?,
      departmentID: json['departmentID'] as int?,
      departmentName: json['departmentName'] as String?,
      principalName: json['principalName'] as String?,
      principalPhone: json['principalPhone'] as String?,
      totalStock: json['totalStock'] as int?,
      status: json['status'] as int?,
    );
  }

  String get displayName {
    if (number != null && name != null) {
      return '$number $name';
    }
    return name ?? '仓库$id';
  }
}
