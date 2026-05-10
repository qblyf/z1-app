import 'api_client.dart';

/// 门店 API
/// 对应后端 store 系列接口
class StoreApi {
  final ApiClient _client = ApiClient();

  /// 门店详情
  /// GET /store/detail
  Future<StoreInfo?> detail({List<int>? departmentIDs}) async {
    final queryParams = <String, dynamic>{};
    if (departmentIDs != null && departmentIDs.isNotEmpty) {
      queryParams['departmentIDs'] = departmentIDs;
    }

    final res = await _client.get('/store/detail',
        queryParameters: queryParams);
    final result = res.data['res'] as List<dynamic>?;
    if (result == null || result.isEmpty) return null;
    return StoreInfo.fromJson(result[0] as Map<String, dynamic>);
  }

  /// 新增门店
  /// POST /store/add
  Future<bool> add({
    required int departmentID,
    required String name,
    String? telephone,
    String? address,
    String? gis,
    String? manager,
  }) async {
    final data = <String, dynamic>{
      'departmentID': departmentID,
      'name': name,
    };
    if (telephone != null) data['telephone'] = telephone;
    if (address != null) data['address'] = address;
    if (gis != null) data['gis'] = gis;
    if (manager != null) data['manager'] = manager;

    final res = await _client.post('/store/add', data: data);
    return res.data['code'] == 10000;
  }

  /// 编辑门店
  /// POST /store/edit
  Future<bool> edit({
    required int departmentID,
    String? name,
    String? telephone,
    String? address,
    String? gis,
    String? manager,
  }) async {
    final data = <String, dynamic>{'departmentID': departmentID};
    if (name != null) data['name'] = name;
    if (telephone != null) data['telephone'] = telephone;
    if (address != null) data['address'] = address;
    if (gis != null) data['gis'] = gis;
    if (manager != null) data['manager'] = manager;

    final res = await _client.post('/store/edit', data: data);
    return res.data['code'] == 10000;
  }
}

/// 门店信息
class StoreInfo {
  final int departmentID;
  final String? name;
  final String? telephone;
  final String? address;
  final String? gis; // "longitude,latitude"
  final String? manager;
  final String? managerName;

  const StoreInfo({
    required this.departmentID,
    this.name,
    this.telephone,
    this.address,
    this.gis,
    this.manager,
    this.managerName,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      departmentID: json['departmentID'] as int? ?? 0,
      name: json['name'] as String?,
      telephone: json['telephone'] as String?,
      address: json['address'] as String?,
      gis: json['gis'] as String?,
      manager: json['manager'] as String?,
      managerName: json['managerName'] as String?,
    );
  }

  double? get longitude {
    if (gis == null || gis!.isEmpty) return null;
    return double.tryParse(gis!.split(',')[0]);
  }

  double? get latitude {
    if (gis == null || gis!.isEmpty) return null;
    final parts = gis!.split(',');
    return parts.length > 1 ? double.tryParse(parts[1]) : null;
  }
}
