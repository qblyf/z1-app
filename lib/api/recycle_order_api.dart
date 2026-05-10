import 'package:equatable/equatable.dart';
import 'api_client.dart';
import '../models/recycle_order.dart';

/// 回收订单 API
/// 对应后端 z1func/recycle-order-* 系列接口
/// 响应格式: { code: 10000, message: string, result: ... }
class RecycleOrderApi {
  final ApiClient _client = ApiClient();

  // ================================================================
  // 回收订单查询
  // ================================================================

  /// 回收订单列表
  /// GET /recycle-order/list
  Future<List<RecycleOrder>> list({
    String? number,
    String? serial,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? minPlatformSoldTime,
    int? maxPlatformSoldTime,
    List<String>? states,
    int? operator,
    int? department,
    int? inspector,
    int? vendor,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (number != null && number.isNotEmpty) queryParams['number'] = number;
    if (serial != null && serial.isNotEmpty) queryParams['serial'] = serial;
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;
    if (minPlatformSoldTime != null) queryParams['minPlatformSoldTime'] = minPlatformSoldTime;
    if (maxPlatformSoldTime != null) queryParams['maxPlatformSoldTime'] = maxPlatformSoldTime;
    if (states != null && states.isNotEmpty) queryParams['states'] = states;
    if (operator != null) queryParams['operator'] = operator;
    if (department != null) queryParams['department'] = department;
    if (inspector != null) queryParams['inspector'] = inspector;
    if (vendor != null) queryParams['vendor'] = vendor;

    final res = await _client.get('/recycle-order/list', queryParameters: queryParams);
    final result = res.data['result'] as List<dynamic>? ?? [];
    return result
        .map((e) => RecycleOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 回收订单详情
  /// GET /recycle-order/detail
  Future<RecycleOrder?> detail(String number) async {
    final res = await _client.get('/recycle-order/detail', queryParameters: {
      'number': number,
    });
    final result = res.data['result'] as List<dynamic>?;
    if (result == null || result.isEmpty) return null;
    return RecycleOrder.fromJson(result[0] as Map<String, dynamic>);
  }

  /// 回收订单统计
  /// GET /recycle-order/count
  Future<List<RecycleOrderStatistics>> count({
    String? number,
    String? serial,
    int? minCreatedAt,
    int? maxCreatedAt,
    int? minPlatformSoldTime,
    int? maxPlatformSoldTime,
    List<String>? states,
    int? operator,
    int? department,
    int? inspector,
    int? vendor,
  }) async {
    final queryParams = <String, dynamic>{};
    if (number != null && number.isNotEmpty) queryParams['number'] = number;
    if (serial != null && serial.isNotEmpty) queryParams['serial'] = serial;
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;
    if (minPlatformSoldTime != null) queryParams['minPlatformSoldTime'] = minPlatformSoldTime;
    if (maxPlatformSoldTime != null) queryParams['maxPlatformSoldTime'] = maxPlatformSoldTime;
    if (states != null && states.isNotEmpty) queryParams['states'] = states;
    if (operator != null) queryParams['operator'] = operator;
    if (department != null) queryParams['department'] = department;
    if (inspector != null) queryParams['inspector'] = inspector;
    if (vendor != null) queryParams['vendor'] = vendor;

    final res = await _client.get('/recycle-order/count', queryParameters: queryParams);
    final result = res.data['result'] as List<dynamic>? ?? [];
    return result
        .map((e) => RecycleOrderStatistics.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 用户回收订单数量
  /// GET /recycle-order/user/count
  Future<int> userCount(int userIdent) async {
    try {
      final res = await _client.get('/recycle-order/user/count', queryParameters: {
        'user': userIdent,
      });
      return res.data['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ================================================================
  // 回收订单状态操作
  // ================================================================

  /// 创建回收单
  /// POST /recycle-order/add
  Future<String?> add({
    required int customer,
    required int ruleId,
    required String serial,
    required String paymentType,
    required int actualAmount,
    required int evalAmount,
    required int costAmount,
    required int department,
    required int operator,
    required List<int> selects,
    List<String>? images,
    String? serialBefore,
    List<String>? specification,
    String? payInfo,
  }) async {
    final data = <String, dynamic>{
      'customer': customer,
      'ruleID': ruleId,
      'serial': serial,
      'paymentType': paymentType,
      'actualAmount': actualAmount,
      'evalAmount': evalAmount,
      'costAmount': costAmount,
      'department': department,
      'operator': operator,
      'selects': selects,
    };
    if (images != null) data['images'] = images;
    if (serialBefore != null) data['serialBefore'] = serialBefore;
    if (specification != null) data['specification'] = specification;
    if (payInfo != null) data['payInfo'] = payInfo;

    final res = await _client.post('/recycle-order/add', data: data);
    return res.data['result'] as String?;
  }

  /// 修改状态为已付款
  /// POST /recycle-order/paid
  Future<bool> paid({
    required String number,
    required int accountId,
  }) async {
    final res = await _client.post('/recycle-order/paid', data: {
      'number': number,
      'accountID': accountId,
    });
    return res.data['result'] as bool? ?? false;
  }

  /// 修改状态为调拨在途
  /// POST /recycle-order/transfer
  Future<bool> transfer({
    required String number,
    required int inDept,
  }) async {
    final res = await _client.post('/recycle-order/transfer', data: {
      'number': number,
      'inDept': inDept,
    });
    return res.data['result'] as bool? ?? false;
  }

  /// 修改状态为未复检
  /// POST /recycle-order/not-rechecked
  Future<bool> notRechecked(String number) async {
    final res = await _client.post('/recycle-order/not-rechecked', data: {
      'number': number,
    });
    return res.data['result'] as bool? ?? false;
  }

  /// 修改状态为已复检
  /// POST /recycle-order/rechecked
  Future<bool> rechecked(String number) async {
    final res = await _client.post('/recycle-order/rechecked', data: {
      'number': number,
    });
    return res.data['result'] as bool? ?? false;
  }

  /// 转为非标准货品
  /// POST /recycle-order/not-standard-goods
  Future<bool> notStandardGoods(String number) async {
    final res = await _client.post('/recycle-order/not-standard-goods', data: {
      'number': number,
    });
    return res.data['result'] as bool? ?? false;
  }

  /// 修改回收单状态为渠道
  /// POST /recycle-order/vendor
  Future<bool> vendor({
    required String number,
    required int vendorId,
  }) async {
    final res = await _client.post('/recycle-order/vendor', data: {
      'number': number,
      'vendor': vendorId,
    });
    return res.data['result'] as bool? ?? false;
  }

  /// 渠道转为渠道售出
  /// POST /recycle-order/vendor-sold
  Future<bool> vendorSold({
    required String number,
    required int accountId,
    required int platformPrice,
  }) async {
    final res = await _client.post('/recycle-order/vendor-sold', data: {
      'number': number,
      'accountID': accountId,
      'platformPrice': platformPrice,
    });
    return res.data['result'] as bool? ?? false;
  }

  /// 渠道转为已复检
  /// POST /recycle-order/vendor-to-rechecked
  Future<bool> vendorToRechecked(String number) async {
    final res = await _client.post('/recycle-order/vendor-to-rechecked', data: {
      'number': number,
    });
    return res.data['result'] as bool? ?? false;
  }

  /// 修改状态为已撤销
  /// POST /recycle-order/undone
  Future<bool> undone(String number) async {
    final res = await _client.post('/recycle-order/undone', data: {
      'number': number,
    });
    return res.data['result'] as bool? ?? false;
  }

  // ================================================================
  // 回收估价与问答（创建流程）
  // ================================================================

  /// 根据设备名称模糊搜索回收规则
  /// GET /recycle/list/title?title=xxx
  Future<List<RecycleRuleSimple>> getRecycleRulesByTitles(String title) async {
    final res = await _client.get('/recycle/list/title', queryParameters: {
      'title': title,
    });
    final list = res.data['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => RecycleRuleSimple.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取回收规则的所有问答选项
  /// GET /recycle-answer?ruleID=xxx
  Future<List<RecycleAnswer>> getRecycleAnswer(int ruleId) async {
    final res = await _client.get('/recycle-answer', queryParameters: {
      'ruleID': ruleId,
    });
    final result = res.data['result'] as List<dynamic>? ?? [];
    return result
        .map((e) => RecycleAnswer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 计算回收估价
  /// GET /recycle/price?ruleID=xxx&selects=1,2,3
  Future<RecyclePriceResult> getRecycleRulePrice(
    int ruleId,
    List<int> selects,
  ) async {
    final res = await _client.get('/recycle/price', queryParameters: {
      'ruleID': ruleId,
      'selects': selects.join(','),
    });
    final result = res.data['result'] as Map<String, dynamic>?;
    if (result == null) {
      return const RecyclePriceResult(evalAmount: 0, costAmount: 0);
    }
    return RecyclePriceResult.fromJson(result);
  }
}

/// 回收规则简略信息
class RecycleRuleSimple extends Equatable {
  final int id;
  final String title;

  const RecycleRuleSimple({required this.id, required this.title});

  factory RecycleRuleSimple.fromJson(Map<String, dynamic> json) {
    return RecycleRuleSimple(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, title];
}

/// 回收回答模型
class RecycleAnswer extends Equatable {
  final int id;
  final double? ratio;
  final int? addend;
  final String question;
  final String content;
  final int? questionIndex;
  final int? answerIndex;
  final bool disability;
  final int? questionType;
  final int questionId;

  const RecycleAnswer({
    required this.id,
    this.ratio,
    this.addend,
    required this.question,
    required this.content,
    this.questionIndex,
    this.answerIndex,
    required this.disability,
    this.questionType,
    required this.questionId,
  });

  factory RecycleAnswer.fromJson(Map<String, dynamic> json) {
    return RecycleAnswer(
      id: json['id'] as int? ?? 0,
      ratio: (json['ratio'] as num?)?.toDouble(),
      addend: json['addend'] as int?,
      question: json['question'] as String? ?? '',
      content: json['content'] as String? ?? '',
      questionIndex: json['questionIndex'] as int?,
      answerIndex: json['answerIndex'] as int?,
      disability: json['disability'] as bool? ?? false,
      questionType: json['questionType'] as int?,
      questionId: json['questionID'] as int? ?? 0,
    );
  }

  /// 问题类型：1=规格，2=常见问题，3=其他问题
  bool get isSpec => questionType == 1;
  bool get isCommon => questionType == 2;
  bool get isOther => questionType == 3;

  @override
  List<Object?> get props => [id, question, content, questionType];
}

/// 回收估价结果
class RecyclePriceResult extends Equatable {
  final int evalAmount;
  final int costAmount;

  const RecyclePriceResult({
    required this.evalAmount,
    required this.costAmount,
  });

  factory RecyclePriceResult.fromJson(Map<String, dynamic> json) {
    return RecyclePriceResult(
      evalAmount: json['evalAmount'] as int? ?? 0,
      costAmount: json['costAmount'] as int? ?? 0,
    );
  }

  /// 转为元
  double get evalAmountYuan => evalAmount / 100;
  double get costAmountYuan => costAmount / 100;

  @override
  List<Object?> get props => [evalAmount, costAmount];
}
