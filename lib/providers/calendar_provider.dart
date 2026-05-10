import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/calendar.dart';
import '../api/calendar_api.dart';

/// 行事历 API Provider
final calendarApiProvider = Provider<CalendarApi>((ref) {
  return CalendarApi();
});

/// 行事历类型枚举
enum CalendarTab { doing, expired, checked, task }

/// 当前行事历 Tab
final calendarTabProvider = StateProvider<CalendarTab>((ref) {
  return CalendarTab.doing;
});

/// 进行中的行事历列表
final doingCalendarProvider = FutureProvider<List<CalendarTask>>((ref) async {
  final api = ref.read(calendarApiProvider);
  return api.getInProgress();
});

/// 已结束的行事历列表
final expiredCalendarProvider = FutureProvider.family<List<CalendarTask>, int>((ref, offset) async {
  final api = ref.read(calendarApiProvider);
  return api.getExpired(offset: offset);
});

/// 待验收的行事历列表
final pendingCheckCalendarProvider = FutureProvider<List<CalendarTask>>((ref) async {
  final api = ref.read(calendarApiProvider);
  return api.getPendingCheck();
});

/// 行事历详情
final calendarDetailProvider = FutureProvider.family<CalendarTask, String>((ref, id) async {
  final api = ref.read(calendarApiProvider);
  return api.getDetail(id);
});

/// 行事历操作结果
class CalendarActionResult {
  final bool success;
  final String? message;

  CalendarActionResult({required this.success, this.message});
}

/// 行事历操作服务
final calendarActionProvider = Provider<CalendarActionService>((ref) {
  return CalendarActionService(ref);
});

class CalendarActionService {
  final Ref _ref;

  CalendarActionService(this._ref);

  CalendarApi get _api => _ref.read(calendarApiProvider);

  /// 签到
  Future<CalendarActionResult> checkIn(String id, {String? location, String? remark}) async {
    try {
      final success = await _api.checkIn(id, location: location, remark: remark);
      if (success) {
        _ref.invalidate(doingCalendarProvider);
        _ref.invalidate(pendingCheckCalendarProvider);
        return CalendarActionResult(success: true);
      }
      return CalendarActionResult(success: false, message: '签到失败');
    } catch (e) {
      return CalendarActionResult(success: false, message: e.toString());
    }
  }

  /// 签退
  Future<CalendarActionResult> checkOut(String id, {String? remark}) async {
    try {
      final success = await _api.checkOut(id, remark: remark);
      if (success) {
        _ref.invalidate(doingCalendarProvider);
        return CalendarActionResult(success: true);
      }
      return CalendarActionResult(success: false, message: '签退失败');
    } catch (e) {
      return CalendarActionResult(success: false, message: e.toString());
    }
  }

  /// 完成任务
  Future<CalendarActionResult> complete(String id, {String? remark}) async {
    try {
      final success = await _api.complete(id, remark: remark);
      if (success) {
        _ref.invalidate(doingCalendarProvider);
        return CalendarActionResult(success: true);
      }
      return CalendarActionResult(success: false, message: '操作失败');
    } catch (e) {
      return CalendarActionResult(success: false, message: e.toString());
    }
  }

  /// 验收
  Future<CalendarActionResult> approve(String id, {String? remark}) async {
    try {
      final success = await _api.approve(id, remark: remark);
      if (success) {
        _ref.invalidate(pendingCheckCalendarProvider);
        return CalendarActionResult(success: true);
      }
      return CalendarActionResult(success: false, message: '验收失败');
    } catch (e) {
      return CalendarActionResult(success: false, message: e.toString());
    }
  }
}
