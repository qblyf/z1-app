import 'api_client.dart';
import '../models/appointment_booking.dart';

class AppointmentBookingApi {
  final _client = ApiClient();

  /// 国补预约上门列表
  Future<List<AppointmentBooking>> list({
    BookingStatus? status,
    int limit = 20,
    int offset = 0,
    bool descending = true,
  }) async {
    final body = <String, dynamic>{
      'limit': limit,
      'offset': offset,
      'orderBy': [
        {'key': 'created_at', 'sort': descending ? 'DESC' : 'ASC'}
      ],
    };
    if (status != null) body['status'] = status.value;

    final res = await _client.get(
      '/appointment-booking/state-subsidies/list',
      queryParameters: body,
    );
    final list = (res.data['res'] as List?) ?? [];
    return list.map((e) => AppointmentBooking.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 国补预约上门总数
  Future<int> count({BookingStatus? status}) async {
    final body = <String, dynamic>{};
    if (status != null) body['status'] = status.value;

    final res = await _client.get(
      '/appointment-booking/state-subsidies/count',
      queryParameters: body,
    );
    return (res.data['res'] as int?) ?? 0;
  }

  /// 预约详情
  Future<AppointmentBooking?> detail(int id) async {
    final res = await _client.get('/appointment-booking/detail', queryParameters: {'id': id});
    final data = res.data['res'] as Map<String, dynamic>?;
    if (data == null) return null;
    return AppointmentBooking.fromJson(data);
  }
}
