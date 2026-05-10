import 'package:equatable/equatable.dart';
import 'package:z1_app/api/api_client.dart';

/// 往来单位/供应商
class Vendor extends Equatable {
  final int id;
  final String name;
  final String? number;
  final String? spell;
  final String? phone;
  final int state; // 1=正常 0=停用

  const Vendor({
    required this.id,
    required this.name,
    this.number,
    this.spell,
    this.phone,
    this.state = 1,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      number: json['number'] as String?,
      spell: json['spell'] as String?,
      phone: json['phone'] as String?,
      state: json['state'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [id, name, state];
}

/// 往来单位 API
class VendorApi {
  final ApiClient _client = ApiClient();

  /// 获取往来单位列表
  /// GET /vendor/list-condition?limit=X&offset=X&state=X
  Future<List<Vendor>> list({
    int? state,
    int limit = 500,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (state != null) params['state'] = state;

    final response = await _client.get('/vendor/list-condition',
        queryParameters: params);
    final data = response.data['list'] as List<dynamic>? ??
                 response.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => Vendor.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 根据ID列表获取往来单位详情
  /// POST /vendor/detail
  Future<List<Vendor>> getDetail(List<int> vendorIds) async {
    if (vendorIds.isEmpty) return [];
    final response = await _client.post('/vendor/detail',
        data: {'vendorIDs': vendorIds});
    final data = response.data['res'] as List<dynamic>? ??
                 response.data['list'] as List<dynamic>? ?? [];
    return data.map((e) => Vendor.fromJson(e as Map<String, dynamic>)).toList();
  }
}
