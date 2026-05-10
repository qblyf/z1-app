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

  /// 职员关闭预约上门（需备注）
  /// 对应 PWA closeAppointmentBooking
  Future<bool> close(int id, String remarks) async {
    final res = await _client.post(
      '/appointment-booking/close',
      data: {'id': id, 'appointmentRemarks': remarks},
    );
    return res.data['code'] == 0;
  }

  /// 处理员编辑预约上门（关闭/完成状态变更）
  /// 对应 PWA handlerEditAppointmentBooking
  /// status: 'closed' | 'completed'
  Future<bool> handlerEdit(int id, String status, {String? remarks}) async {
    final body = <String, dynamic>{'id': id, 'status': status};
    if (remarks != null) body['appointmentRemarks'] = remarks;
    final res = await _client.post('/appointment-booking/edit/handler', data: body);
    return res.data['code'] == 0;
  }

  /// 外呼员编辑预约上门（添加备注 / 修改内容）
  /// 对应 PWA callerEditAppointmentBooking
  Future<bool> callerEdit(int id, {String? appointmentRemarks, Map<String, dynamic>? content}) async {
    final body = <String, dynamic>{'id': id};
    if (appointmentRemarks != null) body['appointmentRemarks'] = appointmentRemarks;
    if (content != null) body['content'] = content;
    final res = await _client.post('/appointment-booking/edit/editor', data: body);
    return res.data['code'] == 0;
  }

  /// 重新设置为待处理状态
  /// 对应 PWA resetToProcessingAppointmentBooking
  Future<bool> resetToProcessing(int id, String remarks) async {
    final res = await _client.post(
      '/appointment-booking/reset-to-processing',
      data: {'id': id, 'appointmentRemarks': remarks},
    );
    return res.data['code'] == 0;
  }
}
