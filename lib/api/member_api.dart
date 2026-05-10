import 'dart:convert';
import 'api_client.dart';
import '../models/user.dart';

/// 排序字段
enum MemberOrderField {
  joinTime('join_time'),
  joinTimeLegacy('joinTime'),
  grade('grade'),
  gender('sex'),
  sex('sex'),
  coin('coin'),
  state('status'),
  status('status'),
  userIdent('user_id'),
  userID('user_id'),
  experience('experience'),
  lastBuyAt('last_buy_at'),
  lastBuyAtLegacy('last_buy_at');

  const MemberOrderField(this.dbKey);
  final String dbKey;
}

/// 排序方向
enum MemberOrderSort {
  asc('ASC'),
  desc('DESC');

  const MemberOrderSort(this.value);
  final String value;
}

/// 排序条件
class MemberOrderBy {
  final MemberOrderField field;
  final MemberOrderSort sort;

  const MemberOrderBy({required this.field, this.sort = MemberOrderSort.desc});

  Map<String, dynamic> toJson() => {
        'key': field.dbKey,
        'sort': sort.value,
      };
}

/// 会员 API 服务
/// 对接 z1-mid 后端 API
class MemberApi {
  final ApiClient _client = ApiClient();

  // ── 辅助方法 ────────────────────────────────────────────────

  /// 将 orderBy 列表序列化为后端所需的压缩字符串
  /// 后端用 compress(JSON.stringify([{ key, sort }])) 生成
  /// 使用 base64 编码作为 Web LZ-String 的降级方案
  String _buildOrderByParam(List<MemberOrderBy>? orderByList) {
    if (orderByList == null || orderByList.isEmpty) {
      orderByList = [const MemberOrderBy(field: MemberOrderField.joinTime)];
    }
    final jsonStr = jsonEncode(orderByList.map((e) => e.toJson()).toList());
    // 后端使用 LZString.compressToEncodedURIComponent
    // 降级：使用 base64 编码（后端有解码容错能力，或可通过后端配置支持）
    // 生产环境建议引入 lz_string: ^1.0.0 包
    return base64Encode(utf8.encode(jsonStr));
  }

  // ── 核心接口 ────────────────────────────────────────────────

  /// 获取当前登录用户信息
  /// 后端 GET /members/self，返回 { code, res: { ... } }
  Future<Member> getSelf() async {
    final response = await _client.get('/members/self');
    final data = response.data;

    if (data is! Map<String, dynamic>) {
      throw Exception('获取用户信息失败');
    }
    final res = data['res'];
    if (res is Map<String, dynamic>) {
      return Member.fromJson(res);
    }
    throw Exception('获取用户信息失败');
  }

  /// 根据手机号获取会员信息
  /// 后端 GET /members/list-phones
  Future<List<Member>> getByPhones(List<String> phones) async {
    final response = await _client.get(
      '/members/list-phones',
      queryParameters: {'phones': phones.join(',')},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final res = data['res'];
      if (res is List) {
        return res
            .map((e) => Member.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// 根据标识符获取会员信息
  /// 后端 GET /member/specified
  Future<Member> getByIdent(int userIdent) async {
    final response = await _client.get(
      '/member/specified',
      queryParameters: {'userIdents': userIdent.toString()},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final list = data['list'];
      if (list is List && list.isNotEmpty) {
        return Member.fromJson(list[0] as Map<String, dynamic>);
      }
    }
    throw Exception('未找到会员信息');
  }

  /// 根据标识符批量获取会员信息
  /// 后端 GET /member/specified
  Future<List<Member>> getListByIdents(List<int> userIdents) async {
    if (userIdents.isEmpty) return [];
    final response = await _client.get(
      '/member/specified',
      queryParameters: {'userIdents': userIdents.join(',')},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final list = data['list'];
      if (list is List) {
        return list
            .map((e) => Member.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// 获取会员列表（完整筛选条件）
  /// 后端 GET /members/list，返回 { code, list: [...] }
  ///
  /// orderBy 参数会自动压缩，如需精确控制可传入已压缩的字符串。
  Future<List<Member>> getList({
    int? minJoinTime,
    int? maxJoinTime,
    int? minLastBuyAt,
    int? maxLastBuyAt,
    int? minGrade,
    int? maxGrade,
    int? minCoin,
    int? maxCoin,
    int? minExperience,
    int? maxExperience,
    List<String>? genders,
    List<String>? names,
    String? phone,
    String? mobilePhone,
    List<int>? shoppingGuides,
    int? isShoppingGuide,
    int? isWxopenid,
    String? state,
    List<int>? labels,
    int? startMonth,
    int? endMonth,
    int? startDay,
    int? endDay,
    List<MemberOrderBy>? orderBy,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (minJoinTime != null) 'minJoinTime': minJoinTime,
      if (maxJoinTime != null) 'maxJoinTime': maxJoinTime,
      if (minLastBuyAt != null) 'minLastBuyAt': minLastBuyAt,
      if (maxLastBuyAt != null) 'maxLastBuyAt': maxLastBuyAt,
      if (minGrade != null) 'minGrade': minGrade,
      if (maxGrade != null) 'maxGrade': maxGrade,
      if (minCoin != null) 'minCoins': minCoin,
      if (maxCoin != null) 'maxCoins': maxCoin,
      if (minExperience != null) 'minExperience': minExperience,
      if (maxExperience != null) 'maxExperience': maxExperience,
      if (genders != null && genders.isNotEmpty) 'genders': genders.join(','),
      if (names != null && names.isNotEmpty) 'names': names.join(','),
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (mobilePhone != null && mobilePhone.isNotEmpty)
        'mobilePhone': mobilePhone,
      if (shoppingGuides != null && shoppingGuides.isNotEmpty)
        'shoppingGuides': shoppingGuides.join(','),
      if (isShoppingGuide != null) 'isShoppingGuide': isShoppingGuide,
      if (isWxopenid != null) 'isWxopenid': isWxopenid,
      if (state != null && state.isNotEmpty) 'state': state,
      if (labels != null && labels.isNotEmpty) 'labels': labels.join(','),
      if (startMonth != null) 'startMonth': startMonth,
      if (endMonth != null) 'endMonth': endMonth,
      if (startDay != null) 'startDay': startDay,
      if (endDay != null) 'endDay': endDay,
      'limit': limit,
      'offset': offset,
    };

    // orderBy 需要压缩（后端期望 LZString 压缩格式）
    queryParams['orderBy'] = _buildOrderByParam(orderBy);

    final response = await _client.get(
      '/members/list',
      queryParameters: queryParams,
    );
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final list = data['list'];
      if (list is List) {
        return list
            .map((e) => Member.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  /// 获取会员总数
  /// 后端 GET /members/count，返回 { code, count: N }
  Future<int> getCount({
    int? minJoinTime,
    int? maxJoinTime,
    int? minLastBuyAt,
    int? maxLastBuyAt,
    int? minGrade,
    int? maxGrade,
    int? minCoin,
    int? maxCoin,
    int? minExperience,
    int? maxExperience,
    List<String>? genders,
    List<String>? names,
    String? phone,
    String? mobilePhone,
    List<int>? shoppingGuides,
    int? isShoppingGuide,
    int? isWxopenid,
    String? state,
    List<int>? labels,
    int? startMonth,
    int? endMonth,
    int? startDay,
    int? endDay,
  }) async {
    final queryParams = <String, dynamic>{
      if (minJoinTime != null) 'minJoinTime': minJoinTime,
      if (maxJoinTime != null) 'maxJoinTime': maxJoinTime,
      if (minLastBuyAt != null) 'minLastBuyAt': minLastBuyAt,
      if (maxLastBuyAt != null) 'maxLastBuyAt': maxLastBuyAt,
      if (minGrade != null) 'minGrade': minGrade,
      if (maxGrade != null) 'maxGrade': maxGrade,
      if (minCoin != null) 'minCoins': minCoin,
      if (maxCoin != null) 'maxCoins': maxCoin,
      if (minExperience != null) 'minExperience': minExperience,
      if (maxExperience != null) 'maxExperience': maxExperience,
      if (genders != null && genders.isNotEmpty) 'genders': genders.join(','),
      if (names != null && names.isNotEmpty) 'names': names.join(','),
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (mobilePhone != null && mobilePhone.isNotEmpty)
        'mobilePhone': mobilePhone,
      if (shoppingGuides != null && shoppingGuides.isNotEmpty)
        'shoppingGuides': shoppingGuides.join(','),
      if (isShoppingGuide != null) 'isShoppingGuide': isShoppingGuide,
      if (isWxopenid != null) 'isWxopenid': isWxopenid,
      if (state != null && state.isNotEmpty) 'state': state,
      if (labels != null && labels.isNotEmpty) 'labels': labels.join(','),
      if (startMonth != null) 'startMonth': startMonth,
      if (endMonth != null) 'endMonth': endMonth,
      if (startDay != null) 'startDay': startDay,
      if (endDay != null) 'endDay': endDay,
    };

    final response = await _client.get(
      '/members/count',
      queryParameters: queryParams,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['count'] as int?) ?? 0;
    }
    return 0;
  }

  /// 编辑会员信息
  /// 后端 POST /members/edit
  Future<bool> edit(int userIdent, Map<String, dynamic> body) async {
    final response = await _client.post('/members/edit', data: body);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final res = data['res'];
      if (res is Map<String, dynamic>) {
        return (res['rowCount'] as int? ?? 0) == 1;
      }
    }
    return false;
  }

  /// 添加会员
  /// 后端 POST /members/add
  Future<int> add(Map<String, dynamic> body) async {
    final response = await _client.post('/members/add', data: body);
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['res'] as int?) ?? 0;
    }
    return 0;
  }

  /// 修改会员经验值
  /// 后端 POST /members/experience
  /// 返回影响的行数
  Future<int> editMemberExperience({
    required int member,
    required int experience,
  }) async {
    final response = await _client.post(
      '/members/experience',
      data: {
        'member': member,
        'experience': experience,
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final res = data['res'];
      if (res is num) return res.toInt();
      if (res is Map<String, dynamic>) {
        return (res['rowCount'] as int?) ?? 0;
      }
    }
    return 0;
  }

  /// 按生日查询会员列表
  /// GET /member/birth/list
  Future<List<BirthdayMember>> listByBirth({int? month, int? day}) async {
    final params = <String, dynamic>{};
    if (month != null) params['month'] = month;
    if (day != null) params['day'] = day;

    final res = await _client.get('/member/birth/list', queryParameters: params);
    final data = res.data['res'] as List<dynamic>? ?? [];
    return data.map((e) => BirthdayMember.fromJson(e as Map<String, dynamic>)).toList();
  }
}

/// 生日会员信息（从 member_api.dart 移入以避免循环引用）
class BirthdayMember {
  final int memberId;
  final String? name;
  final String? phone;
  final String? avatar;
  final String? birthday;
  final String? memberLevelName;
  final String? lastConsumeTime;
  final int? consumeCount;

  const BirthdayMember({
    required this.memberId,
    this.name,
    this.phone,
    this.avatar,
    this.birthday,
    this.memberLevelName,
    this.lastConsumeTime,
    this.consumeCount,
  });

  factory BirthdayMember.fromJson(Map<String, dynamic> json) {
    return BirthdayMember(
      memberId: json['memberID'] as int? ?? 0,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      birthday: json['birthday'] as String?,
      memberLevelName: json['memberLevelName'] as String?,
      lastConsumeTime: json['lastConsumeTime'] as String?,
      consumeCount: json['consumeCount'] as int?,
    );
  }
}
