import 'api_client.dart';

/// 登录结果
class LoginResult {
  final String token;
  final String? permission;

  LoginResult({required this.token, this.permission});

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'] as String,
      permission: json['permission'] as String?,
    );
  }
}

/// AirLogin 扫码登录状态
class AirLoginStatus {
  final String status; // 'null' | 'pending' | 'complete'
  final String? token;
  final String? scannerName;

  AirLoginStatus({
    required this.status,
    this.token,
    this.scannerName,
  });

  factory AirLoginStatus.fromJson(Map<String, dynamic> json) {
    final scanner = json['scanner'] as Map<String, dynamic>?;
    return AirLoginStatus(
      status: json['status'] as String,
      token: json['token'] as String?,
      scannerName: scanner?['name'] as String?,
    );
  }
}

/// 企业微信扫码登录结果
class WeworkScanLoginResult {
  final String token;
  final String scannerName;
  final String? scannerAvatar;

  WeworkScanLoginResult({
    required this.token,
    required this.scannerName,
    this.scannerAvatar,
  });

  factory WeworkScanLoginResult.fromJson(Map<String, dynamic> json) {
    final scanner = json['scanner'] as Map<String, dynamic>?;
    return WeworkScanLoginResult(
      token: json['token'] as String,
      scannerName: scanner?['name'] as String? ?? '',
      scannerAvatar: scanner?['avatar'] as String?,
    );
  }
}

/// 认证 API 服务
class AuthApi {
  final ApiClient _client = ApiClient();

  /// 企业微信 OAuth 授权 URL
  ///
  /// [corpId] 企业 ID
  /// [agentId] 应用 AgentId
  /// [redirectUri] 回调地址
  /// [state] 状态参数（用于防止 CSRF）
  String buildWeworkOAuthUrl({
    required String corpId,
    required String agentId,
    required String redirectUri,
    required String state,
  }) {
    final encodedRedirectUri = Uri.encodeComponent(redirectUri);
    return 'https://open.work.weixin.qq.com/wwopen/sso/qrConnect?'
        'appid=$corpId'
        '&agentid=$agentId'
        '&redirect_uri=$encodedRedirectUri'
        '&state=$state'
        '&lang=zh_CN'
        '&fun=implicit'
        '&param=';
  }

  /// 通过企业微信授权码登录
  ///
  /// 企业微信 OAuth 授权后，会在回调 URL 中带上 code 参数
  /// 此方法用 code 换取 Z1 Token
  Future<LoginResult> loginByWeworkCode(String code) async {
    final response = await _client.post(
      '/members/qywechat-code-token',
      data: {'code': code},
    );
    final data = response.data;

    // 后端返回格式: [{ "code": 10000, "res": { token: "..." } }]
    List<dynamic>? resList = data is List ? data.cast<dynamic>() : null;
    if (resList == null || resList.isEmpty) {
      throw Exception('企业微信登录接口返回格式异常');
    }

    final first = resList[0];
    if (first is! Map<String, dynamic>) {
      throw Exception('企业微信登录接口返回格式异常');
    }

    final codeVal = first['code'];
    if (codeVal != null && codeVal != 10000) {
      throw Exception(first['message'] ?? '企业微信登录失败');
    }

    final res = first['res'];
    if (res is String && res.isNotEmpty) {
      return LoginResult(token: res);
    }
    if (res is Map<String, dynamic> && res['token'] != null) {
      return LoginResult(
        token: res['token'] as String,
        permission: res['permission'] as String?,
      );
    }
    throw Exception('企业微信登录失败');
  }

  /// 获取企业微信 JS-SDK 签名
  Future<Map<String, dynamic>> getWeworkSignature(String url) async {
    final response = await _client.get(
      '/wework/get-signature',
      queryParameters: {'url': url},
    );
    final data = response.data;
    if (data['res'] != null) {
      return data['res'] as Map<String, dynamic>;
    }
    throw Exception('获取签名失败');
  }

  /// 获取企业微信应用 JS-SDK 签名
  Future<Map<String, dynamic>> getWeworkAgentSignature(String url) async {
    final response = await _client.get(
      '/wework/get-agent-signature',
      queryParameters: {'url': url},
    );
    final data = response.data;
    if (data['res'] != null) {
      return data['res'] as Map<String, dynamic>;
    }
    throw Exception('获取应用签名失败');
  }

  /// 跨设备扫码登录 - 设置扫码者信息（企业微信）
  Future<WeworkScanLoginResult> setWeworkScanner({
    required String uuid,
    required String code,
    String? ua,
  }) async {
    final response = await _client.post(
      '/air-login/set-scanner/qywechat',
      data: {
        'uuid': uuid,
        'code': code,
        if (ua != null) 'ua': ua,
      },
    );
    final data = response.data;
    if (data['res'] != null) {
      return WeworkScanLoginResult.fromJson(data['res'] as Map<String, dynamic>);
    }
    throw Exception('设置扫码者信息失败');
  }

  /// 跨设备扫码登录 - 确认登录
  Future<bool> confirmLogin({
    required String uuid,
    required String token,
  }) async {
    final response = await _client.post(
      '/login-air',
      queryParameters: {'o': 'confirm', 'uuid': uuid},
      data: {'token': token},
    );
    return response.data['res'] == true;
  }

  /// 跨设备扫码登录 - 检查登录状态
  Future<AirLoginStatus> checkAirLoginStatus(String uuid) async {
    final response = await _client.get(
      '/air-login/get-token',
      queryParameters: {'uuid': uuid},
    );
    final data = response.data;
    if (data['res'] != null) {
      return AirLoginStatus.fromJson(data['res'] as Map<String, dynamic>);
    }
    throw Exception('检查登录状态失败');
  }

  /// 钉钉登录 - 通过授权码获取 Token
  Future<LoginResult> loginByDingtalkCode(String code) async {
    final response = await _client.post(
      '/login',
      data: {'dingtalkCode': code},
    );
    final data = response.data;
    if (data['res'] != null && data['res']['token'] != null) {
      return LoginResult.fromJson({
        'token': data['res']['token'] as String,
        'permission': data['res']['permission'] as String?,
      });
    }
    throw Exception('钉钉登录失败');
  }

  /// 手机号密码登录
  Future<LoginResult> loginByPhonePassword(String phone, String password) async {
    final response = await _client.post(
      '/members/phone-login',
      data: {
        'phone': phone,
        'pwd': password,
      },
    );
    final data = response.data;

    // 后端返回格式: { "code": 10000, "res": { token: "...", permission?: "..." } }
    // 或失败: { "code": 70124, "message": "用户名或密码错误" }
    if (data is! Map<String, dynamic>) {
      throw Exception('登录接口返回格式异常');
    }

    // 检查业务错误码
    final code = data['code'];
    if (code != null && code != 10000) {
      final message = data['message'] ?? '登录失败';
      throw Exception(message);
    }

    final res = data['res'];
    if (res is Map<String, dynamic> && res['token'] != null) {
      return LoginResult(
        token: res['token'] as String,
        permission: res['permission'] as String?,
      );
    }

    throw Exception('手机号密码登录失败');
  }

  /// 登出
  Future<void> logout() async {
    await _client.post('/logout');
  }
}
