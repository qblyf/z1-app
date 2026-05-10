import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/order.dart';
import '../api/order_api.dart';

/// 商城订单列表 Provider
final mallOrderListProvider = StateNotifierProvider<MallOrderListNotifier, AsyncValue<List<MallOrder>>>((ref) {
  return MallOrderListNotifier(ref);
});

/// 商城订单 Tab 类型
enum MallOrderType { retail, recycle, afterSale }

class MallOrderListNotifier extends StateNotifier<AsyncValue<List<MallOrder>>> {
  final Ref _ref;
  List<MallOrder> _orders = [];
  int _offset = 0;
  bool _hasMore = true;
  int? _currentStatus;
  MallOrderType _currentType = MallOrderType.retail;

  MallOrderListNotifier(this._ref) : super(const AsyncValue.data([]));

  OrderApi get _api => _ref.read(orderApiProvider);

  /// 切换订单类型
  void setType(MallOrderType type) {
    if (_currentType == type) return;
    _currentType = type;
    _orders = [];
    _offset = 0;
    _hasMore = true;
    _currentStatus = null;
    state = const AsyncValue.data([]);
    loadOrders();
  }

  /// 切换状态筛选
  void setStatus(int? status) {
    _currentStatus = status;
    _orders = [];
    _offset = 0;
    _hasMore = true;
    state = const AsyncValue.data([]);
    loadOrders();
  }

  /// 加载订单
  Future<void> loadOrders() async {
    if (!_hasMore) return;
    state = const AsyncValue.loading();
    try {
      final orders = await _api.getMallOrderList(
        status: _currentStatus,
        limit: 20,
        offset: _offset,
      );
      _orders.addAll(orders);
      _offset += orders.length;
      _hasMore = orders.length >= 20;
      state = AsyncValue.data(List.from(_orders));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 刷新
  Future<void> refresh() async {
    _orders = [];
    _offset = 0;
    _hasMore = true;
    await loadOrders();
  }
}

/// 订单 API Provider
final orderApiProvider = Provider<OrderApi>((ref) {
  return OrderApi();
});

/// 订单列表 Provider
final orderListProvider = StateNotifierProvider<OrderListNotifier, AsyncValue<List<Order>>>((ref) {
  return OrderListNotifier(ref);
});

/// genre 字符串转数字（对应后端 SalesMode）
int? _genreToNumber(String? genre) {
  switch (genre) {
    case 'shopSale':
      return 1; // 店内零售
    case 'netSale':
      return 2; // 网销
    case 'outSale':
      return 3; // 批发
    case 'serviceSale':
      return 4; // 维修
    default:
      return null;
  }
}

class OrderListNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  final Ref _ref;
  List<Order> _orders = [];
  int _offset = 0;
  bool _hasMore = true;
  String? _currentGenre;

  OrderListNotifier(this._ref) : super(const AsyncValue.data([]));

  OrderApi get _api => _ref.read(orderApiProvider);

  /// 加载订单列表
  Future<void> loadOrders({String? genre, bool refresh = false}) async {
    if (refresh) {
      _orders = [];
      _offset = 0;
      _hasMore = true;
      _currentGenre = genre;
    }

    if (!_hasMore && !refresh) return;

    state = const AsyncValue.loading();
    try {
      final orders = await _api.getList(
        genre: _genreToNumber(genre ?? _currentGenre),
        limit: 20,
        offset: _offset,
      );
      _orders.addAll(orders);
      _offset += orders.length;
      _hasMore = orders.length >= 20;
      state = AsyncValue.data(_orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 刷新
  Future<void> refresh() async {
    await loadOrders(refresh: true);
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (!_hasMore) return;
    await loadOrders();
  }

  /// 更新订单状态
  void updateOrderStatus(String orderNumber, int status) {
    final index = _orders.indexWhere((o) => o.orderNumber == orderNumber);
    if (index != -1) {
      final oldOrder = _orders[index];
      final updatedOrders = List<Order>.from(_orders);
      updatedOrders[index] = Order(
        id: oldOrder.id,
        orderNumber: oldOrder.orderNumber,
        genre: oldOrder.genre,
        status: status,
        department: oldOrder.department,
        departmentName: oldOrder.departmentName,
        createdBy: oldOrder.createdBy,
        createdAt: oldOrder.createdAt,
        totalAmount: oldOrder.totalAmount,
        discountAmount: oldOrder.discountAmount,
        actualAmount: oldOrder.actualAmount,
        items: oldOrder.items,
        remark: oldOrder.remark,
        userIdent: oldOrder.userIdent,
        userName: oldOrder.userName,
        userPhone: oldOrder.userPhone,
        paidAt: oldOrder.paidAt,
        shippedAt: oldOrder.shippedAt,
      );
      _orders = updatedOrders;
      state = AsyncValue.data(_orders);
    }
  }
}

/// 订单详情 Provider
final orderDetailProvider = FutureProvider.family<Order, String>((ref, orderNumber) async {
  final api = ref.read(orderApiProvider);
  return api.getDetail(orderNumber);
});

/// 用户订单列表 Provider
final userOrdersProvider = FutureProvider.family<List<Order>, int>((ref, userIdent) async {
  final api = ref.read(orderApiProvider);
  return api.getByUserAndGenre(userIdent: userIdent);
});
