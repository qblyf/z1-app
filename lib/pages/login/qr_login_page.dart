import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/login_service.dart';
import '../../theme/app_theme.dart';

/// 二维码登录页面
class QrLoginPage extends ConsumerStatefulWidget {
  const QrLoginPage({super.key});

  @override
  ConsumerState<QrLoginPage> createState() => _QrLoginPageState();
}

class _QrLoginPageState extends ConsumerState<QrLoginPage> {
  late String _uuid;
  Timer? _pollTimer;
  LoginStatus _status = LoginStatus.pending;
  String? _userName;
  String? _errorMessage;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _uuid = LoginService().generateUuid();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
  }

  Future<void> _poll() async {
    final result = await LoginService().pollLoginStatus(_uuid);
    if (!mounted) return;
    setState(() {
      _status = result.status;
      _userName = result.userName;
      _errorMessage = result.message;
      if (result.status == LoginStatus.expired ||
          result.status == LoginStatus.failed) {
        _isExpired = true;
      }
    });
  }

  void _refreshQrCode() {
    setState(() {
      _uuid = LoginService().generateUuid();
      _status = LoginStatus.pending;
      _userName = null;
      _errorMessage = null;
      _isExpired = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = LoginService().getQrCodeUrl(_uuid);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        border: null,
        middle: const Text('扫码登录'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF5E5CE6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.qrcode_viewfinder,
                  color: CupertinoColors.white,
                  size: 36,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // 二维码卡片
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.elevated,
                ),
                child: Column(
                  children: [
                    _buildQrCodeContent(qrUrl),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHintText(),
                  ],
                ),
              ),

              if (_isExpired || _status == LoginStatus.expired) ...[
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _refreshQrCode,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.refresh, size: 18),
                        SizedBox(width: 8),
                        Text('刷新二维码'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrCodeContent(String qrUrl) {
    if (_isExpired) {
      return SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 36,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '二维码已过期',
                style: AppText.body.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_status == LoginStatus.scanned && _userName != null) {
      return SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              UserAvatar(
                name: _userName,
                size: 64,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _userName ?? '',
                style: AppText.subtitle,
              ),
              const SizedBox(height: 4),
              Text(
                '请在企业微信中确认登录',
                style: AppText.caption.copyWith(
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return QrImageView(
      data: qrUrl,
      version: QrVersions.auto,
      size: 200,
      backgroundColor: CupertinoColors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  Widget _buildHintText() {
    String text;
    Color color;

    switch (_status) {
      case LoginStatus.pending:
        text = '请使用企业微信扫描二维码登录';
        color = CupertinoColors.secondaryLabel.resolveFrom(context);
        break;
      case LoginStatus.scanned:
        text = '扫码成功，请在企业微信中确认登录';
        color = AppColors.accent;
        break;
      case LoginStatus.complete:
        text = '登录成功！';
        color = AppColors.success;
        break;
      case LoginStatus.expired:
        text = _errorMessage ?? '二维码已过期，请刷新';
        color = AppColors.error;
        break;
      case LoginStatus.failed:
        text = _errorMessage ?? '登录失败，请重试';
        color = AppColors.error;
        break;
    }

    return Text(
      text,
      style: AppText.body.copyWith(color: color),
      textAlign: TextAlign.center,
    );
  }
}
