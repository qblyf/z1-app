import '../api_client.dart';
import '../models/ahs_order.dart';

/// 爱回收(AHS) API
class AhsApi {
  final ApiClient _client = ApiClient();

  /// 获取掌上回收单详情
  /// [number] 回收单编号
  Future<AhsOrder?> getOrderInfo(String number) async {
    final response = await _client.get(
      '/ahs/order/info',
      queryParameters: {'number': number},
    );
    final data = response.data;
    if (data == null || data['res'] == null) return null;
    return AhsOrder.fromJson(data['res']);
  }
}
