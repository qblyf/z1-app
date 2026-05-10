import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/token_service.dart';
import '../providers/permission_provider.dart';

export 'package:dio/dio.dart' show CancelToken;

/// 认证错误类型
enum AuthErrorType { tokenExpired, forbidden, unknown }

/// 认证错误事件
class AuthError {
  final AuthErrorType type;
  final String message;
  AuthError(this.type, this.message);
}

/// API 客户端
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final TokenService _tokenService = TokenService();

  /// 认证错误流
  final StreamController<AuthError> _authErrorController =
      StreamController<AuthError>.broadcast();

  Stream<AuthError> get authErrorStream => _authErrorController.stream;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: ApiConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // 添加拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));

    // 开发模式打印日志
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  /// 请求拦截器
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 添加 Token
    final token = await _tokenService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = token;
    }

    // 根据请求路径动态添加权限头
    final path = options.path;
    final permKey = _pathToPermissionKey(path);
    if (permKey != null) {
      // 从全局权限缓存中获取
      final jwt = permissionService.getCachedJwt(permKey);
      if (jwt != null) {
        options.headers['Use-Permissions'] = jwt;
      }
    }

    handler.next(options);
  }

  /// API 路径到权限 key 的映射
  static String? _pathToPermissionKey(String path) {
    if (path.startsWith('task-log/') ||
        path.startsWith('calendar/') ||
        path.startsWith('task/')) {
      return 'calendarManage';
    }
    if (path.startsWith('approval/')) {
      return 'approvalManage';
    }
    if (path.startsWith('product-warehouse/') ||
        path.startsWith('warehouse/')) {
      return 'stockManage';
    }
    return null;
  }

  /// 响应拦截器
  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    // 打印关键接口的响应数据，方便调试
    final path = response.requestOptions.path;
    debugPrint('=== API 响应 ===');
    debugPrint('路径: $path');
    debugPrint('状态码: ${response.statusCode}');
    debugPrint('数据: ${response.data}');
    debugPrint('====================');
    handler.next(response);
  }

  /// 错误拦截器
  void _onError(DioException error, ErrorInterceptorHandler handler) {
    debugPrint('=== API 错误 ===');
    debugPrint('类型: ${error.type}');
    debugPrint('消息: ${error.message}');
    debugPrint('路径: ${error.requestOptions.path}');
    if (error.response != null) {
      debugPrint('状态码: ${error.response?.statusCode}');
      debugPrint('响应数据: ${error.response?.data}');
    }
    debugPrint('====================');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        debugPrint('请求超时');
        break;
      case DioExceptionType.badResponse:
        _handleBadResponse(error.response);
        break;
      case DioExceptionType.cancel:
        debugPrint('请求取消');
        break;
      case DioExceptionType.connectionError:
        debugPrint('连接错误');
        break;
      default:
        debugPrint('网络错误: ${error.message}');
    }
    handler.next(error);
  }

  /// 从响应数据中提取错误消息
  /// 后端返回格式: { "code": xxx, "message": "..." }
  String? _extractMessage(dynamic data) {
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return null;
  }

  void _handleBadResponse(Response? response) {
    if (response == null) {
      debugPrint('_handleBadResponse: response is null');
      return;
    }

    debugPrint('_handleBadResponse statusCode: ${response.statusCode}');
    debugPrint('_handleBadResponse data: ${response.data}');

    final message = _extractMessage(response.data) ?? '请求失败';

    switch (response.statusCode) {
      case 400:
        debugPrint('请求参数错误: $message');
        break;
      case 401:
        debugPrint('未授权，请重新登录');
        _authErrorController.add(AuthError(
          AuthErrorType.tokenExpired,
          message,
        ));
        break;
      case 403:
        debugPrint('没有权限');
        _authErrorController.add(AuthError(
          AuthErrorType.forbidden,
          message,
        ));
        break;
      case 404:
        debugPrint('资源不存在');
        break;
      case 500:
        debugPrint('服务器内部错误');
        break;
      default:
        debugPrint('请求失败: ${response.statusCode}');
    }
  }

  /// 清理路径中的多余前缀
  String _cleanPath(String path) {
    // 移除开头的 /（Dio 会自动处理）
    if (path.startsWith('/')) {
      return path.substring(1);
    }
    return path;
  }

  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      _cleanPath(path),
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// POST 请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      _cleanPath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// PUT 请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      _cleanPath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      _cleanPath(path),
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// 文件上传
  Future<Response<T>> uploadFile<T>(
    String path, {
    required FormData data,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      _cleanPath(path),
      data: data,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }
}
