import 'api_client.dart';

/// 会员等级模型
class MemberLevel {
  final int id;
  final String name;
  final int number;
  final int minExperience;
  final int maxExperience;
  final String? iconUrl;
  final int? discount;
  final int? pointMultiple;
  final String? description;
  final int createdAt;

  const MemberLevel({
    required this.id,
    required this.name,
    required this.number,
    required this.minExperience,
    required this.maxExperience,
    this.iconUrl,
    this.discount,
    this.pointMultiple,
    this.description,
    required this.createdAt,
  });

  factory MemberLevel.fromJson(Map<String, dynamic> json) {
    return MemberLevel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      number: json['number'] as int? ?? 0,
      minExperience: json['minExperience'] as int? ?? json['min_experience'] as int? ?? 0,
      maxExperience: json['maxExperience'] as int? ?? json['max_experience'] as int? ?? 0,
      iconUrl: json['iconUrl'] as String? ?? json['icon_url'] as String?,
      discount: json['discount'] as int?,
      pointMultiple: json['pointMultiple'] as int? ?? json['point_multiple'] as int?,
      description: json['description'] as String?,
      createdAt: json['createdAt'] as int? ?? json['created_at'] as int? ?? 0,
    );
  }

  String get levelIcon {
    switch (number) {
      case 6: return '钻石';
      case 5: return '铂金';
      case 4: return '黄金';
      case 3: return '白银';
      case 2: return '青铜';
      default: return '普通';
    }
  }
}

/// 会员等级 API
/// 后端路径: /member-level/*
class MemberLevelApi {
  final ApiClient _client = ApiClient();

  /// 获取会员等级列表
  /// 后端 GET /member-level/list，返回 { code, res: [...] }
  Future<List<MemberLevel>> getList() async {
    // 后端 GET /member-level/list
    final response = await _client.get('/member-level/list');

    final data = response.data;
    // 后端返回 { code, res: [...] }
    final res = data['res'];
    if (res is List) {
      return res.map((e) => MemberLevel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// 获取会员等级详情
  /// 后端 GET /member-level/detail-or-all
  Future<MemberLevel> getDetail(int id) async {
    // 后端 GET /member-level/detail-or-all?id=X
    final response = await _client.get(
      '/member-level/detail-or-all',
      queryParameters: {'id': id},
    );

    final data = response.data;
    // 后端返回 { code, res: { ... } }
    final res = data['res'];
    if (res is Map<String, dynamic>) {
      return MemberLevel.fromJson(res);
    }
    throw Exception('未找到会员等级');
  }

  /// 根据经验值获取对应等级
  Future<MemberLevel?> getLevelByExperience(int experience) async {
    final levels = await getList();

    for (final level in levels) {
      if (experience >= level.minExperience && experience <= level.maxExperience) {
        return level;
      }
    }

    return levels.isNotEmpty ? levels.last : null;
  }
}
