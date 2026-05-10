import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../api/member_api.dart';
import '../api/auth_api.dart';
import '../services/token_service.dart';

/// Token 服务 Provider
final tokenServiceProvider = Provider<TokenService>((ref) {
  return TokenService();
});

/// 登录状态管理（用于 GoRouter redirect）
/// 使用简单的同步 Provider，从 storage 读取
final loginStateProvider = Provider<bool>((ref) {
  // 每次读取时从 storage 获取最新状态
  // 注意：这会在每次读取时执行 IO 操作
  return false; // 默认返回 false，由外部初始化
});

/// 全局登录状态
class LoginState {
  static bool isLoggedIn = false;
}

/// 初始化登录状态
Future<void> initLoginState() async {
  final tokenService = TokenService();
  LoginState.isLoggedIn = await tokenService.isLoggedIn();
}

/// 设置登录状态
void setLoginState(bool value) {
  LoginState.isLoggedIn = value;
}

/// 会员 API Provider
final memberApiProvider = Provider<MemberApi>((ref) {
  return MemberApi();
});

/// 认证 API Provider
final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi();
});

/// 企业微信配置
class WeworkConfig {
  final String corpId;
  final String agentId;
  final String agentSecret;

  const WeworkConfig({
    required this.corpId,
    required this.agentId,
    required this.agentSecret,
  });
}

/// 企业微信配置 Provider
final weworkConfigProvider = Provider<WeworkConfig>((ref) {
  return const WeworkConfig(
    corpId: 'ww00cc4c12ff49ae86',
    agentId: '1000003',
    agentSecret: 'PZXyqnzJGdPbnhmm2ik2nEW7rF5vyOkK2dJ9eINTlg8',
  );
});

/// 当前用户 Provider（使用 Riverpod 3.x AsyncNotifier）
final currentUserProvider = AsyncNotifierProvider<CurrentUserNotifier, Member?>(() {
  return CurrentUserNotifier();
});

class CurrentUserNotifier extends AsyncNotifier<Member?> {
  @override
  Future<Member?> build() async {
    return _loadUser();
  }

  MemberApi get _api => ref.read(memberApiProvider);
  TokenService get _tokenService => ref.read(tokenServiceProvider);

  Future<Member?> _loadUser() async {
    // 先检查 token 是否存在
    final token = await _tokenService.getToken();
    debugPrint('currentUserProvider._loadUser: token=${token == null ? 'null' : token.length > 20 ? token.substring(0, 20) : token}');
    if (token == null || token.isEmpty) {
      debugPrint('currentUserProvider._loadUser: 无token，返回null');
      return null;
    }

    try {
      return await _api.getSelf();
    } catch (e) {
      debugPrint('currentUserProvider._loadUser: API错误 $e');
      // 如果是 403 错误，说明 token 无效
      if (e is DioException && e.response?.statusCode == 403) {
        debugPrint('currentUserProvider._loadUser: 403错误，清除token');
        await _tokenService.clearToken();
        return null;
      }
      // 其他错误也清除 token
      if (e.toString().contains('403') || e.toString().contains('jwt')) {
        debugPrint('currentUserProvider._loadUser: jwt无效，清除token');
        await _tokenService.clearToken();
        return null;
      }
      rethrow;
    }
  }

  /// 加载当前用户
  Future<void> loadCurrentUser() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadUser());
  }

  /// 刷新用户信息
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _api.getSelf());
  }

  /// 清除用户状态
  void clear() {
    state = const AsyncData(null);
  }
}

/// 未认证异常
class UnauthenticatedException implements Exception {
  final String message;
  UnauthenticatedException([this.message = '未登录或登录已过期']);

  @override
  String toString() => message;
}

/// 登录状态 Provider
final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final tokenService = ref.read(tokenServiceProvider);
  return tokenService.isLoggedIn();
});

/// 会员详情 Provider
final memberDetailProvider = FutureProvider.family<Member, int>((ref, userIdent) async {
  final api = ref.read(memberApiProvider);
  return api.getByIdent(userIdent);
});

/// 会员列表 Provider
final memberListProvider = FutureProvider.family<List<Member>, Map<String, dynamic>>((ref, params) async {
  final api = ref.read(memberApiProvider);
  return api.getList(
    phone: params['phone'] as String?,
    mobilePhone: params['mobilePhone'] as String?,
    minCoin: params['minCoin'] as int?,
    maxCoin: params['maxCoin'] as int?,
    limit: params['limit'] as int? ?? 20,
    offset: params['offset'] as int? ?? 0,
  );
});
