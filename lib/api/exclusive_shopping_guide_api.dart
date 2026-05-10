import 'api_client.dart';

/// 专属导购 API
/// 对应后端 /employee/shopping-guide/*
class ExclusiveShoppingGuideApi {
  final ApiClient _client = ApiClient();

  /// 获取导购的客户总数
  /// GET /employee/shopping-guide/member/count?userIdent=
  Future<int> memberCount(int userIdent) async {
    final res = await _client.get(
      '/employee/shopping-guide/member/count',
      queryParameters: {'userIdent': userIdent},
    );
    return res.data['res'] as int? ?? 0;
  }

  /// 获取导购的客户列表
  /// GET /employee/shopping-guide/member/list?userIdent=&limit=&offset=
  Future<List<ShoppingGuideMember>> memberList({
    required int userIdent,
    int limit = 100,
    int offset = 0,
  }) async {
    final res = await _client.get(
      '/employee/shopping-guide/member/list',
      queryParameters: {
        'userIdent': userIdent,
        'limit': limit,
        'offset': offset,
      },
    );
    final data = res.data['list'] as List<dynamic>? ?? [];
    return data
        .map((e) => ShoppingGuideMember.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 解绑客户
  /// POST /member/unbind/shopping-guide-by-empl
  Future<bool> unbind(int userIdent) async {
    final res = await _client.post(
      '/member/unbind/shopping-guide-by-empl',
      data: {'userIdent': userIdent},
    );
    return res.data['code'] == 10000;
  }
}

/// 导购客户列表项
class ShoppingGuideMember {
  final int userIdent;
  final String name;
  final int time;
  final int totalConsumptionAmount;
  final String memberLevelName;

  const ShoppingGuideMember({
    required this.userIdent,
    required this.name,
    required this.time,
    required this.totalConsumptionAmount,
    required this.memberLevelName,
  });

  factory ShoppingGuideMember.fromJson(Map<String, dynamic> json) {
    return ShoppingGuideMember(
      userIdent: json['userIdent'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      time: json['time'] as int? ?? 0,
      totalConsumptionAmount: json['totalConsumptionAmount'] as int? ?? 0,
      memberLevelName: json['memberLevelName'] as String? ?? '',
    );
  }

  String get formattedAmount => '¥${(totalConsumptionAmount / 100).toStringAsFixed(2)}';

  String get formattedTime {
    final dt = DateTime.fromMillisecondsSinceEpoch(time * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
