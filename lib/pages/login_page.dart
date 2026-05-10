import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../api/auth_api.dart';
import '../services/token_service.dart';

/// 从错误中提取用户友好的消息
String _extractErrorMessage(dynamic e) {
  if (e is DioException) {
    final data = e.response?.data;
    debugPrint('DioException data: $data');
    // 尝试从数组中提取
    if (data is List && data.isNotEmpty) {
      final first = data[0];
      debugPrint('DioException first: $first');
      if (first is Map) {
        final msg = first['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    }
    // 尝试从对象中提取
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    // 网络错误消息
    if (e.message != null && e.message!.isNotEmpty) return e.message!;
  }
  // 普通异常
  final msg = e.toString();
  debugPrint('登录异常: $msg');
  // 去掉 "Exception: " 前缀
  if (msg.startsWith('Exception: ')) return msg.substring(11);
  return msg;
}

/// 登录页面（精简版，移除了可能导致崩溃的可选功能）
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // 预填测试账号（方便调试）
    _phoneController.text = '99999999999';
    _passwordController.text = 'ncxSEpbZ\$20m\$W6O';
  }

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
      _successMessage = null;
    });

    try {
      // 调用手机号密码登录 API
      final authApi = AuthApi();
      final result = await authApi.loginByPhonePassword(phone, password).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('登录超时，请检查网络'),
      );

      setState(() => _successMessage = '登录成功，正在跳转...');

      // 保存 token
      final tokenService = TokenService();
      try {
        await tokenService.setToken(result.token);
        debugPrint('Token保存成功: ${result.token.substring(0, 20)}...');
      } catch (e) {
        debugPrint('Token保存失败: $e');
      }

      // 更新登录状态
      setLoginState(true);

      // 使用 go_router 跳转
      context.go(Routes.home);
    } catch (e, st) {
      debugPrint('登录异常: $e\n$st');
      final msg = _extractErrorMessage(e);
      setState(() => _errorMessage = msg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: GradientBgDecoration(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // 错误/成功提示
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemRed),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_circle, color: CupertinoColors.systemRed),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: CupertinoColors.systemRed))),
                      ],
                    ),
                  ),
                if (_successMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemGreen),
                    ),
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.checkmark_circle, color: CupertinoColors.systemGreen),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_successMessage!, style: const TextStyle(color: CupertinoColors.systemGreen))),
                      ],
                    ),
                  ),

                // Logo + 品牌标识
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // 如果图片加载失败，显示渐变背景
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primary, Color(0xFFD4AF37)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Z1',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '掌上高远',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '欢迎回来',
                        style: AppText.body.copyWith(
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // 登录表单卡片
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Column(
                    children: [
                      // 手机号输入
                      _LoginTextField(
                        controller: _phoneController,
                        placeholder: '手机号',
                        prefix: CupertinoIcons.phone,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // 密码输入
                      _LoginTextField(
                        controller: _passwordController,
                        placeholder: '密码',
                        prefix: CupertinoIcons.lock,
                        obscureText: _obscurePassword,
                        suffixIcon: _obscurePassword
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        onSuffixTap: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // 忘记密码
                      Align(
                        alignment: Alignment.centerRight,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () {},
                          child: Text(
                            '忘记密码？',
                            style: AppText.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 登录按钮
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text(
                            '登录',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData prefix;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;

  const _LoginTextField({
    required this.controller,
    required this.placeholder,
    required this.prefix,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      prefix: Padding(
        padding: const EdgeInsets.only(left: 14),
        child: Icon(prefix, color: CupertinoColors.systemGrey, size: 20),
      ),
      suffix: suffixIcon != null
          ? CupertinoButton(
              padding: const EdgeInsets.only(right: 8),
              minimumSize: Size.zero,
              onPressed: onSuffixTap,
              child: Icon(
                suffixIcon,
                color: CupertinoColors.systemGrey,
                size: 20,
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.divider,
        ),
      ),
    );
  }
}
