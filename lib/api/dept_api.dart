import 'api_client.dart';

/// 部门信息
class DeptInfo {
  final int id;
  final String number;
  final String name;
  final String spell;
  final int pid;
  final String? remark;
  final String? telephone;
  final String? address;
  final String? image;
  final int? order;
  final int type;
  final int? manager;
  final String? level;
  final String? commissionLevel;
  final List<int> chain;
  final int state;
  final int createdAt;
  final int isStore;
  final String? latitude;
  final String? longitude;
  final String? jdxStoreEncode;
  final int? weworkDepartmentID;

  DeptInfo({
    required this.id,
    required this.number,
    required this.name,
    required this.spell,
    required this.pid,
    this.remark,
    this.telephone,
    this.address,
    this.image,
    this.order,
    required this.type,
    this.manager,
    this.level,
    this.commissionLevel,
    required this.chain,
    required this.state,
    required this.createdAt,
    required this.isStore,
    this.latitude,
    this.longitude,
    this.jdxStoreEncode,
    this.weworkDepartmentID,
  });

  factory DeptInfo.fromJson(Map<String, dynamic> json) {
    return DeptInfo(
      id: json['id'] as int,
      number: json['number'] as String? ?? '',
      name: json['name'] as String? ?? '',
      spell: json['spell'] as String? ?? '',
      pid: json['pid'] as int? ?? 0,
      remark: json['remark'] as String?,
      telephone: json['telephone'] as String?,
      address: json['address'] as String?,
      image: json['image'] as String?,
      order: json['order'] as int?,
      type: json['type'] as int? ?? 0,
      manager: json['manager'] as int?,
      level: json['level'] as String?,
      commissionLevel: json['commissionLevel'] as String?,
      chain: (json['chain'] as List<dynamic>?)?.cast<int>() ?? [],
      state: json['state'] as int? ?? 1,
      createdAt: json['createdAt'] as int? ?? 0,
      isStore: json['isStore'] as int? ?? 2,
      latitude: json['latitude'] as String?,
      longitude: json['longitude'] as String?,
      jdxStoreEncode: json['jdxStoreEncode'] as String?,
      weworkDepartmentID: json['weworkDepartmentID'] as int?,
    );
  }
}

/// 部门 API
/// 后端路径: /store/dept-detail
class DeptApi {
  final ApiClient _client = ApiClient();

  /// 获取部门详情
  /// GET /store/dept-detail?departmentID=X
  /// 返回 { department: {...}, store: {...} }
  Future<DeptInfo?> getDeptDetail(int departmentId) async {
    final res = await _client.get(
      '/store/dept-detail',
      queryParameters: {'departmentID': departmentId},
    );
    final data = res.data;
    if (data['code'] == 10000 && data['department'] != null) {
      return DeptInfo.fromJson(data['department'] as Map<String, dynamic>);
    }
    return null;
  }

  /// 获取部门列表（正常状态）
  /// GET /department/list?status=正常
  Future<List<DeptInfo>> getDepartmentList() async {
    final res = await _client.get(
      '/department/list',
      queryParameters: {'status': '正常'},
    );
    final list = res.data['res'] as List<dynamic>? ?? [];
    return list
        .map((e) => DeptInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
