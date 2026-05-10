import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';
import '../../services/token_service.dart';
import '../../services/permission_service.dart';
import '../../api/auth_api.dart';

/// 企业微信 OAuth 授权登录页面
class WeworkAuthPage extends ConsumerStatefulWidget {
  const WeworkAuthPage({super.key});

  @override
  ConsumerState<WeworkAuthPage> createState() => _WeworkAuthPageState();
}

class _WeworkAuthPageState extends ConsumerState<WeworkAuthPage> {
  StreamSubscription<Uri?>? _uriSubscription;
  bool _isLoading = false;
  String? _errorMessage;
  late final AppLinks _appLinks;

  // 企业微信配置
  static const String _corpId = 'ww00cc4c12ff49ae86';
  static const String _agentId = '1000003';

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _initUniLinks();
  }

  @override
  void dispose() {
    _uriSubscription?.cancel();
    super.dispose();
  }

  /// 初始化 deep link 监听
  Future<void> _initUniLinks() async {
    // 处理从外部打开应用的链接
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleCallback(initialUri);
      }
    } catch (e) {
      debugPrint('获取初始 URI 失败: $e');
    }

    // 监听后续的链接
    _uriSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      if (uri != null) {
        _handleCallback(uri);
      }
    }, onError: (err) {
      debugPrint('监听 URI 失败: $err');
    });
  }

  /// 处理 OAuth 回调
  void _handleCallback(Uri uri) {
    debugPrint('收到回调: $uri');
    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      _handleLogin(code);
    }
  }

  /// 打开企业微信授权页面
  Future<void> _openWeworkAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 使用 z1app 作为 redirect_uri scheme
      final redirectUri = Uri.encodeComponent('z1app://wework/callback');
      final state = DateTime.now().millisecondsSinceEpoch.toString();

      final authUrl = Uri.parse(
        'https://open.work.weixin.qq.com/wwopen/sso/qrConnect'
        '?appid=$_corpId'
        '&agentid=$_agentId'
        '&redirect_uri=$redirectUri'
        '&state=$state'
        '&lang=zh_CN'
        '&fun=implicit'
        '&param=',
      );

      debugPrint('打开企业微信授权: $authUrl');
      final launched = await launchUrl(
        authUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        setState(() {
          _errorMessage = '无法打开企业微信授权页面';
          _isLoading = false;
        });
      } else {
        // 等待用户授权完成
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '授权失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 处理登录
  Future<void> _handleLogin(String code) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('收到授权码: $code');

      // 开发模式：使用模拟 token
      if (code.startsWith('dev_') || code == 'test') {
        debugPrint('开发模式：使用模拟 token');
        final tokenService = TokenService();
        final mockToken = 'dev_mock_token_${DateTime.now().millisecondsSinceEpoch}';
        await tokenService.setToken(mockToken);
        await tokenService.setUserId(1);
        await tokenService.setPermission('admin');

        if (mounted) {
          context.go(Routes.home);
        }
        return;
      }

      // 正式环境：调用企业微信登录 API
      final authApi = ref.read(authApiProvider);
      final result = await authApi.loginByWeworkCode(code);

      // 保存 token
      final tokenService = TokenService();
      await tokenService.setToken(result.token);
      if (result.permission != null) {
        await tokenService.setPermission(result.permission!);
      }

      // 登录成功后，获取权限 JWT
      try {
        final permissionService = PermissionService();
        await permissionService.fetchPermissionPackages([
          'calendarManage',
          'calendarView',
          'approvalManage',
          'businessAssistant',
        ]);
      } catch (e) {
        debugPrint('获取权限失败: $e');
      }

      // 加载用户信息
      ref.read(currentUserProvider.notifier).loadCurrentUser();

      if (mounted) {
        context.go(Routes.home);
      }
    } catch (e) {
      debugPrint('登录失败: $e');
      setState(() {
        _errorMessage = '登录失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 开发模式：使用手机号密码登录
  Future<void> _usePhoneLogin() async {
    // 显示手机号密码登录对话框
    showCupertinoDialog(
      context: context,
      builder: (dialogContext) => _PhoneLoginDialog(
        onSuccess: () {
          Navigator.of(dialogContext).pop();
          if (mounted) {
            context.go(Routes.home);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('企业微信登录'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF12B7F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  CupertinoIcons.device_phone_portrait,
                  color: CupertinoColors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),

              // 标题
              const Text(
                '企业微信授权登录',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '使用企业微信账号登录 Z1 助手',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),

              const SizedBox(height: 48),

              // 企业微信登录按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: CupertinoButton.filled(
                  onPressed: _isLoading ? null : _openWeworkAuth,
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.device_phone_portrait, size: 20),
                            SizedBox(width: 8),
                            Text('使用企业微信登录', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // 开发模式：手机号密码登录
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '开发测试',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: CupertinoColors.activeBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: _usePhoneLogin,
                        child: const Text('手机号密码登录', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),

              // 错误信息
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 手机号密码登录对话框（开发模式）
class _PhoneLoginDialog extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;

  const _PhoneLoginDialog({required this.onSuccess});

  @override
  ConsumerState<_PhoneLoginDialog> createState() => _PhoneLoginDialogState();
}

class _PhoneLoginDialogState extends ConsumerState<_PhoneLoginDialog> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty) {
      setState(() => _errorMessage = '请输入手机号');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = '请输入密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 调用真实 API 登录
      final authApi = AuthApi();
      final result = await authApi.loginByPhonePassword(phone, password);

      // 保存 token
      final tokenService = ref.read(tokenServiceProvider);
      await tokenService.setToken(result.token);
      if (result.permission != null) {
        await tokenService.setPermission(result.permission!);
      }

      // 登录成功后，获取权限 JWT
      try {
        final permissionService = PermissionService();
        await permissionService.fetchPermissionPackages([
          'calendarManage',
          'calendarView',
          'approvalManage',
          'businessAssistant',
        ]);
      } catch (e) {
        debugPrint('获取权限失败: $e');
      }

      // 加载用户信息
      ref.read(currentUserProvider.notifier).loadCurrentUser();

      if (mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      setState(() {
        _errorMessage = '登录失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('手机号密码登录'),
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            CupertinoTextField(
              controller: _phoneController,
              placeholder: '手机号',
              keyboardType: TextInputType.phone,
              padding: const EdgeInsets.all(12),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.phone, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _passwordController,
              placeholder: '密码',
              obscureText: _obscurePassword,
              padding: const EdgeInsets.all(12),
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.lock, size: 18),
              ),
              suffix: CupertinoButton(
                padding: const EdgeInsets.only(right: 8),
                minSize: 0,
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                child: Icon(
                  _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
                  size: 18,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _isLoading ? null : _handleLogin,
          child: _isLoading
              ? const CupertinoActivityIndicator(radius: 8)
              : const Text('登录'),
        ),
      ],
    );
  }
}
