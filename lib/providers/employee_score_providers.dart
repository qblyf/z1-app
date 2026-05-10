import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/employee_score_api.dart';
import '../models/employee_score.dart';

/// 员工积分 API Provider
final employeeScoreApiProvider = Provider<EmployeeScoreApi>((ref) => EmployeeScoreApi());

/// 当前用户积分余额
final currentUserScoreProvider = FutureProvider<CurrentUserScore>((ref) async {
  return ref.read(employeeScoreApiProvider).getCurrentUserScore();
});

/// 积分分类列表
final scoreClassListProvider = FutureProvider<List<ScoreClass>>((ref) async {
  return ref.read(employeeScoreApiProvider).getClassList();
});
