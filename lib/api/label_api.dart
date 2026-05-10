import 'api_client.dart';
import '../models/label.dart';

/// 标签 API
/// 对应后端 z1func/label-* 系列接口
/// 响应格式: { code: 10000, message: string, result: ... }
class LabelApi {
  final ApiClient _client = ApiClient();

  // ================================================================
  // 标签管理
  // ================================================================

  /// 条件获取标签列表
  /// GET /label/list
  Future<List<Label>> listByCondition({
    LabelType? type,
    LabelState? state,
    List<int>? itemIDs,
    int? minCreatedAt,
    int? maxCreatedAt,
    int limit = 10000,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (type != null) queryParams['type'] = type.value;
    if (state != null) queryParams['state'] = state.value;
    if (itemIDs != null && itemIDs.isNotEmpty) queryParams['itemIDs'] = itemIDs;
    if (minCreatedAt != null) queryParams['minCreatedAt'] = minCreatedAt;
    if (maxCreatedAt != null) queryParams['maxCreatedAt'] = maxCreatedAt;

    final res = await _client.get('/label/list', queryParameters: queryParams);
    // 后端返回 { code, message, result }，result 为标签列表
    final result = res.data['result'] as List<dynamic>? ?? [];
    return result
        .map((e) => Label.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 根据类型获取标签列表
  /// GET /label/list-by-type
  Future<List<Label>> listByType(LabelType type) async {
    final res = await _client.get('/label/list-by-type', queryParameters: {
      'type': type.value,
    });
    final result = res.data['result'] as List<dynamic>? ?? [];
    return result
        .map((e) => Label.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 根据标签ID列表获取标签
  /// GET /label/list-by-ids
  Future<List<Label>> listByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final res = await _client.get('/label/list-by-ids', queryParameters: {
      'ids': ids.join(','),
    });
    final result = res.data['result'] as List<dynamic>? ?? [];
    return result
        .map((e) => Label.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 新增标签
  /// POST /label/add
  Future<bool> add({
    required String name,
    required LabelType type,
    required String color,
    required int order,
    LabelState state = LabelState.normal,
  }) async {
    final res = await _client.post('/label/add', data: {
      'name': name,
      'type': type.value,
      'color': color,
      'order': order,
      'state': state.value,
    });
    return res.data['result'] as bool? ?? false;
  }

  /// 修改标签
  /// POST /label/edit
  Future<bool> edit({
    required int id,
    String? name,
    String? color,
    int? order,
    LabelState? state,
  }) async {
    final data = <String, dynamic>{'id': id};
    if (name != null) data['name'] = name;
    if (color != null) data['color'] = color;
    if (order != null) data['order'] = order;
    if (state != null) data['state'] = state.value;

    final res = await _client.post('/label/edit', data: data);
    return res.data['result'] as bool? ?? false;
  }

  /// 删除标签
  /// POST /label/delete
  Future<bool> delete(int id) async {
    final res = await _client.post('/label/delete', data: {'id': id});
    return res.data['result'] as bool? ?? false;
  }

  // ================================================================
  // 标签项管理
  // ================================================================

  /// 添加标签项（会员关联标签）
  /// POST /label-item/add
  Future<bool> addItem({
    required int labelID,
    required List<int> labelItemIDs,
  }) async {
    final res = await _client.post('/label-item/add', data: {
      'labelID': labelID,
      'labelItemIDs': labelItemIDs,
    });
    final code = res.data['code'];
    return code == 10000 || code == true;
  }

  /// 删除标签项（取消会员关联标签）
  /// POST /label-item/delete
  Future<int> deleteItem({
    required int labelID,
    required List<int> labelItemIDs,
  }) async {
    final res = await _client.post('/label-item/delete', data: {
      'labelID': labelID,
      'labelItemIDs': labelItemIDs,
    });
    return res.data['count'] as int? ?? 0;
  }

  /// 批量添加标签项
  /// POST /label-item/batch-add
  Future<bool> batchAddItems({
    required int labelID,
    required List<int> itemIDs,
  }) async {
    final res = await _client.post('/label-item/batch-add', data: {
      'labelID': labelID,
      'itemIDs': itemIDs,
    });
    final code = res.data['code'];
    return code == 10000;
  }

  /// 批量删除标签项
  /// POST /label-item/batch-delete
  Future<bool> batchDeleteItems({
    required int labelID,
    required List<int> itemIDs,
  }) async {
    final res = await _client.post('/label-item/batch-delete', data: {
      'labelID': labelID,
      'itemIDs': itemIDs,
    });
    final code = res.data['code'];
    return code == 10000;
  }

  /// 获取标签项ID列表
  /// GET /label/item/list
  Future<List<int>> getItemIdsByLabel(int labelID) async {
    final res = await _client.get('/label/item/list', queryParameters: {
      'labelID': labelID,
    });
    final result = res.data['result'] as List<dynamic>? ?? [];
    return result.map((e) => e as int).toList();
  }

  // ================================================================
  // 销售统计
  // ================================================================

  /// 会员购买商品统计
  /// GET /sales-statistic/customer/order-product
  Future<MemberSalesPreference> getSalesPreference(int memberIdent) async {
    // 手机(1)、配件(3696)、电脑(1518)、平板(1943)、保护壳(26)、贴膜(27)
    final res = await _client.get(
      '/sales-statistic/customer/order-product',
      queryParameters: {
        'user': memberIdent,
        'cates': [1, 3696, 1518, 1943, 26, 27],
      },
    );
    final result = res.data['result'] as List<dynamic>? ?? [];
    // 后端返回的是 BuyPreference[] 数组，需要包装成 MemberSalesPreference
    return MemberSalesPreference.fromJson({
      'buyPreference': result,
      'recycleCount': 0,
    });
  }

  /// 会员旧机回收次数
  /// GET /recycle-order/user-count
  Future<int> getRecycleCount(int memberIdent) async {
    try {
      final res = await _client.get('/recycle-order/user-count', queryParameters: {
        'user': memberIdent,
      });
      return res.data['result'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }
}
