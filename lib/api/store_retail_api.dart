import 'package:z1_app/api/api_client.dart';
import 'package:z1_app/models/user.dart';
import 'package:z1_app/models/store_retail.dart';

/// 门店零售 API 服务
/// 对接 z1-mid 后端的代下单相关接口
class StoreRetailApi {
  final ApiClient _client = ApiClient();

  // ── 会员相关 ──────────────────────────────────────────────

  /// 根据手机号获取会员信息（零售入口用）
  Future<Member?> getMemberByPhone(String phone) async {
    try {
      final response = await _client.get(
        '/members/list-phones',
        queryParameters: {'phones': phone},
      );
      final data = response.data;
      if (data['res'] is List && (data['res'] as List).isNotEmpty) {
        return Member.fromJson((data['res'] as List)[0] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 新增会员（注册）
  /// 后端 POST /members/add
  Future<int> addMember({
    required String mobilePhone,
    String? realName,
    String? gender,
    String? birthDay,
  }) async {
    final body = <String, dynamic>{
      'mobilePhone': mobilePhone,
      if (realName != null) 'realName': realName,
      if (gender != null) 'gender': gender,
      if (birthDay != null) 'birthDay': birthDay,
    };
    // 后端返回 { code, res: 123 }
    final response = await _client.post('/members/add', data: body);
    return response.data['res'] as int? ?? 0;
  }

  /// 编辑会员信息
  /// 后端 POST /members/edit
  Future<bool> editMember(int userIdent, Map<String, dynamic> body) async {
    // 后端返回 { code, res: { rowCount: 1 } }
    final data = await _client.post('/members/edit', data: body);
    final res = data.data['res'];
    if (res is Map<String, dynamic>) {
      return (res['rowCount'] as int? ?? 0) == 1;
    }
    return false;
  }

  /// 获取会员等级列表
  /// 后端 GET /member-level/list
  Future<List<MemberLevel>> getMemberLevelList() async {
    // 后端返回 { code, res: [...] }
    final response = await _client.get('/member-level/list');
    final data = response.data;
    final res = data['res'];
    if (res is List) {
      return res.map((e) => MemberLevel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return MemberLevel.levels; // fallback
  }

  // ── 商品/库存相关 ─────────────────────────────────────────

  /// 获取仓库ID（根据部门）
  Future<List<int>> getWarehouseIdsByDeptId(int departmentId) async {
    final response = await _client.get(
      '/warehouse/ids-by-department',
      queryParameters: {'departmentID': departmentId},
    );
    final data = response.data;
    final res = data['res'];
    if (res is List) return res.cast<int>();
    if (res is String) return [];
    return [];
  }

  /// 获取商品库存
  Future<Map<String, int>> getStockStats({
    required List<int> warehouseIds,
    required List<int> productIds,
  }) async {
    final response = await _client.post(
      '/warehouse/stock-stats',
      data: {
        'warehouseIDs': warehouseIds,
        'productIDs': productIds,
      },
    );
    final data = response.data;
    final res = data['res'] as Map<String, dynamic>?;
    if (res != null) return res.map((k, v) => MapEntry(k, v as int));
    return {};
  }

  /// 获取 SKU 详情列表
  Future<List<RetailSkuItem>> getSkuDetails(List<int> skuIds) async {
    if (skuIds.isEmpty) return [];
    final response = await _client.get(
      '/sku/detail',
      queryParameters: {'ids': skuIds.join(',')},
    );
    final data = response.data;
    final list = data['list'] ?? data['res'];
    if (list is List) {
      return list
          .map((e) => RetailSkuItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 搜索商品（商城商品）
  Future<List<RetailSkuItem>> searchMallProducts({
    String? keyword,
    int? categoryId,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      if (keyword != null) 'keyword': keyword,
      if (categoryId != null) 'categoryID': categoryId,
      'limit': limit,
      'offset': offset,
    };
    final response = await _client.get(
      '/product/list-base',
      queryParameters: queryParams,
    );
    final data = response.data;
    final list = data['list'] ?? data['res'];
    if (list is List) {
      return list
          .map((e) => RetailSkuItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取商品直降价格
  Future<int?> getDirectDiscountPrice(int spuId) async {
    try {
      final response = await _client.get(
        '/direct-discount-activity/price',
        queryParameters: {'spuID': spuId},
      );
      final data = response.data;
      return data['res'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// 获取赠品活动
  Future<Map<String, dynamic>?> getGiveawayActivity({
    int? skuId,
    int? serviceId,
    int? itemId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (skuId != null) queryParams['skuID'] = skuId;
      if (serviceId != null) queryParams['serviceID'] = serviceId;
      if (itemId != null) queryParams['itemID'] = itemId;
      final response = await _client.get(
        '/giveaway-activity/info',
        queryParameters: queryParams,
      );
      return response.data['res'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  // ── 服务/非标品相关 ────────────────────────────────────────

  /// 获取服务详情
  Future<List<RetailServiceItem>> getServiceDetails(List<int> serviceIds) async {
    if (serviceIds.isEmpty) return [];
    final response = await _client.get(
      '/service/detail',
      queryParameters: {'ids': serviceIds.join(',')},
    );
    final data = response.data;
    final list = data['list'] ?? data['res'];
    if (list is List) {
      return list
          .map((e) => RetailServiceItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 获取非标品详情
  Future<List<RetailNonStandardItem>> getNonStandardDetails(List<int> itemIds) async {
    if (itemIds.isEmpty) return [];
    final response = await _client.get(
      '/non-standard/detail',
      queryParameters: {'ids': itemIds.join(',')},
    );
    final data = response.data;
    final list = data['list'] ?? data['res'];
    if (list is List) {
      return list
          .map((e) => RetailNonStandardItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ── 优惠券相关 ─────────────────────────────────────────────

  /// 获取会员可用优惠券
  Future<List<Coupon>> getMemberAvailableCoupons({
    required int userIdent,
    int? minOrderAmount,
  }) async {
    final queryParams = <String, dynamic>{
      'userIdents': userIdent.toString(),
      if (minOrderAmount != null) 'minOrderAmount': minOrderAmount,
    };
    final response = await _client.get(
      '/coupons/member',
      queryParameters: queryParams,
    );
    final data = response.data;
    // 后端返回 { code, res: [...] }
    final res = data['res'];
    if (res is List) {
      return res.map((e) => Coupon.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // ── 代下单核心 ─────────────────────────────────────────────

  /// 员工代下单（零售单）
  /// 后端 POST /mall-order/empl-add，返回 { code, res: "订单号" }
  Future<Map<String, dynamic>> emplAddMallOrder({
    required int customerIdent,
    required List<Map<String, dynamic>> products,
    int? departmentId,
    String? remark,
    List<int>? couponIds,
    int? coinAmount,
    String? associatedOrderNumber,
  }) async {
    final response = await _client.post(
      '/mall-order/empl-add',
      data: {
        'customerIdent': customerIdent,
        'info': products,
        if (departmentId != null) 'departmentID': departmentId,
        if (remark != null) 'remark': remark,
        if (couponIds != null && couponIds.isNotEmpty) 'couponIDs': couponIds,
        if (coinAmount != null && coinAmount > 0) 'coinAmount': coinAmount,
        if (associatedOrderNumber != null)
          'associatedOrderNumber': associatedOrderNumber,
      },
    );
    final data = response.data;
    // 后端返回 { code, res: "订单号" }
    final res = data['res'];
    return {
      'success': res is String && res.isNotEmpty,
      'orderNumber': res is String ? res : '',
      'message': data['message'] ?? '',
    };
  }

  /// 员工代下非标单
  /// 后端 POST /mall-order/empl-add-no-standard
  Future<Map<String, dynamic>> emplAddMallOrderNonStandard({
    required int customerIdent,
    required List<Map<String, dynamic>> products,
    int? departmentId,
    String? remark,
  }) async {
    final response = await _client.post(
      '/mall-order/empl-add-no-standard',
      data: {
        'customerIdent': customerIdent,
        'info': products,
        if (departmentId != null) 'departmentID': departmentId,
        if (remark != null) 'remark': remark,
      },
    );
    final data = response.data;
    // 后端返回 { code, res: "订单号" }
    final res = data['res'];
    return {
      'success': res is String && res.isNotEmpty,
      'orderNumber': res is String ? res : '',
      'message': data['message'] ?? '',
    };
  }

  /// 获取可加单的订单列表
  /// 后端 GET /mall-order/allow-associated-numbers
  Future<List<Map<String, dynamic>>> getAllowAssociatedOrderList({
    required int customer,
    int? departmentId,
  }) async {
    final queryParams = <String, dynamic>{
      'customer': customer,
      if (departmentId != null) 'departmentID': departmentId,
    };
    final response = await _client.get(
      '/mall-order/allow-associated-numbers',
      queryParameters: queryParams,
    );
    final data = response.data;
    // 后端返回 { code, res: [...] }
    final res = data['res'];
    if (res is List) return res.cast<Map<String, dynamic>>();
    return [];
  }

  // ── 退货退款相关 ───────────────────────────────────────────

  /// 获取订单详情（用于退货）
  /// 后端 GET /mall-order/new-order-mall-order-detail
  Future<Map<String, dynamic>> getNewOrderDetailByNumber(String orderNumber) async {
    final response = await _client.get(
      '/mall-order/new-order-mall-order-detail',
      queryParameters: {'p': orderNumber},
    );
    final data = response.data;
    // 后端返回 { code, res: { ... } }
    final res = data['res'];
    return res is Map<String, dynamic> ? res : data;
  }

  /// 提交退货
  /// 后端 POST /mall-order-back/add
  Future<bool> mallOrderBack({
    required String mallOrderNumber,
    required Map<String, dynamic> info,
    int? coinAmount,
    int? cashCouponAmount,
    String? payMode,
    List<int>? giftGoodsIds,
    String? remarks,
  }) async {
    final response = await _client.post(
      '/mall-order-back/add',
      data: {
        'mallOrderNumber': mallOrderNumber,
        'info': info,
        if (coinAmount != null) 'coinAmount': coinAmount,
        if (cashCouponAmount != null) 'cashCouponAmount': cashCouponAmount,
        if (payMode != null) 'payMode': payMode,
        if (giftGoodsIds != null) 'giftGoodsIDs': giftGoodsIds,
        if (remarks != null) 'remarks': remarks,
      },
    );
    // 后端返回 { code, res: { orderBackNumber, payAmount } }
    return response.data['code'] == 10000;
  }
}

/// 优惠券（内联，补充 coupon_api 的基础定义）
class Coupon {
  final int id;
  final int classId;
  final int state;
  final int type;
  final int cent;
  final int? minOrderAmount;
  final int? amount;
  final String title;
  final String? description;
  final int gotAt;
  final int? invalidAt;

  const Coupon({
    required this.id,
    required this.classId,
    required this.state,
    required this.type,
    required this.cent,
    this.minOrderAmount,
    this.amount,
    required this.title,
    this.description,
    required this.gotAt,
    this.invalidAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as int? ?? 0,
      classId: json['classID'] as int? ?? json['class_id'] as int? ?? 0,
      state: json['state'] as int? ?? 2,
      type: json['type'] as int? ?? 1,
      cent: json['cent'] as int? ?? 0,
      minOrderAmount: json['minOrderAmount'] as int?,
      amount: json['amount'] as int?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      gotAt: json['gotAt'] as int? ?? 0,
      invalidAt: json['invalidAt'] as int?,
    );
  }

  String get stateLabel {
    switch (state) {
      case 1: return '已失效';
      case 2: return '可用';
      case 3: return '已使用';
      default: return '未知';
    }
  }

  String get typeLabel {
    switch (type) {
      case 1: return '代金券';
      case 2: return '优惠券';
      case 3: return '兑换券';
      default: return '其他';
    }
  }

  String get formattedAmount => cent > 0
      ? '¥${(cent / 100).toStringAsFixed(2)}'
      : (amount != null ? '¥${(amount! / 100).toStringAsFixed(2)}' : '免费');
}
