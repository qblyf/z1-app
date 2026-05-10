import 'package:flutter/cupertino.dart';
import 'api_client.dart';

/// 商城活动 API
/// 对应后端 /mall-activity/*
class MallActivityApi {
  final ApiClient _client = ApiClient();

  /// 获取商城活动列表
  /// GET /mall-activity/list
  Future<List<MallActivity>> list({
    int? limit,
    int? offset,
  }) async {
    final params = <String, dynamic>{};
    if (limit != null) params['limit'] = limit;
    if (offset != null) params['offset'] = offset;

    final res = await _client.get('/mall-activity/list', queryParameters: params);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => MallActivity.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 获取商城活动总数
  /// GET /mall-activity/count
  Future<int> count() async {
    final res = await _client.get('/mall-activity/count');
    return res.data['res'] as int? ?? 0;
  }

  /// 商城活动详情
  /// GET /mall-activity/info
  Future<MallActivity?> info(int id) async {
    final res = await _client.get(
      '/mall-activity/info',
      queryParameters: {'id': id},
    );
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return MallActivity.fromJson(data);
  }
}

/// 商城活动
class MallActivity {
  final int id;
  final String name;
  final List<String> images;
  final int? startAt;
  final int? endAt;
  final bool isOn;
  final int pv;
  final bool invitationEnabled;
  final int? inviteType;
  final int createdAt;
  final int createdBy;
  final int updatedAt;
  final int updatedBy;

  const MallActivity({
    required this.id,
    required this.name,
    this.images = const [],
    this.startAt,
    this.endAt,
    this.isOn = false,
    this.pv = 0,
    this.invitationEnabled = false,
    this.inviteType,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory MallActivity.fromJson(Map<String, dynamic> json) {
    return MallActivity(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      startAt: json['startAt'] as int?,
      endAt: json['endAt'] as int?,
      isOn: json['isOn'] as bool? ?? false,
      pv: json['pv'] as int? ?? 0,
      invitationEnabled: json['invitationEnabled'] as bool? ?? false,
      inviteType: json['inviteType'] as int?,
      createdAt: json['createdAt'] as int? ?? 0,
      createdBy: json['createdBy'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
      updatedBy: json['updatedBy'] as int? ?? 0,
    );
  }

  bool get isActive {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final start = startAt ?? 0;
    final end = endAt ?? 9999999999;
    return isOn && now >= start && now <= end;
  }

  String get statusLabel {
    if (!isOn) return '未开启';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (startAt != null && now < startAt!) return '未开始';
    if (endAt != null && now > endAt!) return '已结束';
    return '进行中';
  }

  Color get statusColor {
    if (!isOn) return const Color(0xFF8E8E93);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (startAt != null && now < startAt!) return const Color(0xFFBF5AF2);
    if (endAt != null && now > endAt!) return const Color(0xFF8E8E93);
    return const Color(0xFF30D158);
  }

  String get formattedTime {
    if (startAt == null || endAt == null) return '-';
    final s = DateTime.fromMillisecondsSinceEpoch(startAt! * 1000);
    final e = DateTime.fromMillisecondsSinceEpoch(endAt! * 1000);
    return '${s.month}/${s.day}-${e.month}/${e.day}';
  }
}
