import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';

/// 扫码登录状态
enum ScanLoginStatus {
  waiting, // 等待扫码
  scanned, // 已扫码，等待确认
  confirmed, // 已确认登录
  expired, // 已过期
  error, // 错误
}

/// 扫码登录状态
class ScanLoginState {
  final String uuid;
  final ScanLoginStatus status;
  final String? scannerName;
  final String? errorMessage;

  ScanLoginState({
    required this.uuid,
    this.status = ScanLoginStatus.waiting,
    this.scannerName,
    this.errorMessage,
  });

  ScanLoginState copyWith({
    String? uuid,
    ScanLoginStatus? status,
    String? scannerName,
    String? errorMessage,
  }) {
    return ScanLoginState(
      uuid: uuid ?? this.uuid,
      status: status ?? this.status,
      scannerName: scannerName ?? this.scannerName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 扫码登录 Notifier
class ScanLoginNotifier extends Notifier<ScanLoginState> {
  Timer? _pollTimer;

  @override
  ScanLoginState build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    return ScanLoginState(uuid: '');
  }

  /// 生成新的登录二维码
  Future<void> generateNewQRCode() async {
    _pollTimer?.cancel();
    final uuid = DateTime.now().millisecondsSinceEpoch.toString();
    state = ScanLoginState(uuid: uuid);
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollStatus());
  }

  Future<void> _pollStatus() async {
    if (state.uuid.isEmpty) return;

    try {
      final authApi = ref.read(authApiProvider);
      final result = await authApi.checkAirLoginStatus(state.uuid);

      switch (result.status) {
        case 'null':
          // 缓存不存在或已过期
          break;
        case 'pending':
          // 扫码完成，等待确认
          state = state.copyWith(
            status: ScanLoginStatus.scanned,
            scannerName: result.scannerName,
          );
          break;
        case 'complete':
          // 登录确认完成
          _pollTimer?.cancel();
          state = state.copyWith(
            status: ScanLoginStatus.confirmed,
            scannerName: result.scannerName,
          );
          // 延迟一点跳转，让用户看到成功状态
          await Future.delayed(const Duration(milliseconds: 500));
          if (ref.mounted) {
            await _completeLogin(result.token!);
          }
          break;
        default:
          break;
      }
    } catch (e) {
      // 轮询错误不影响状态
    }
  }

  Future<void> _completeLogin(String token) async {
    try {
      final tokenService = ref.read(tokenServiceProvider);
      await tokenService.setToken(token);
      await tokenService.setLoginType('wework_scan');
      ref.read(currentUserProvider.notifier).loadCurrentUser();
    } catch (e) {
      state = state.copyWith(
        status: ScanLoginStatus.error,
        errorMessage: '登录失败: $e',
      );
    }
  }
}

/// 扫码登录 Provider
final scanLoginProvider = NotifierProvider<ScanLoginNotifier, ScanLoginState>(() {
  return ScanLoginNotifier();
});

/// 扫码登录页面
class ScanLoginPage extends ConsumerStatefulWidget {
  const ScanLoginPage({super.key});

  @override
  ConsumerState<ScanLoginPage> createState() => _ScanLoginPageState();
}

class _ScanLoginPageState extends ConsumerState<ScanLoginPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanLoginProvider.notifier).generateNewQRCode();
    });
  }

  /// 获取扫码登录 URL
  /// 格式: https://z1-fun.zsqk.com.cn/staff-portal-mobile/confirm-login/login?uuid=XXX
  /// 与 z1-pwa 项目的 QrcodeLogin 组件保持一致
  String get _scanUrl {
    const baseUrl = 'https://z1-fun.zsqk.com.cn/staff-portal-mobile/confirm-login/login';
    return '$baseUrl?uuid=${ref.watch(scanLoginProvider).uuid}';
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(scanLoginProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('扫码登录'),
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
            children: [
              const SizedBox(height: 20),
              // 标题
              Text(
                _getStatusTitle(loginState.status),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStatusSubtitle(loginState.status),
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 30),
              // 二维码区域
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildQRCode(loginState),
              ),
              const SizedBox(height: 24),
              // 扫码提示
              if (loginState.status == ScanLoginStatus.waiting)
                _buildScanInstructions(),
              if (loginState.status == ScanLoginStatus.scanned)
                _buildScannedInfo(loginState),
              const Spacer(),
              // 底部按钮
              if (loginState.status != ScanLoginStatus.confirmed)
                CupertinoButton(
                  onPressed: () {
                    ref.read(scanLoginProvider.notifier).generateNewQRCode();
                  },
                  child: const Text('刷新二维码'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRCode(ScanLoginState loginState) {
    if (loginState.status == ScanLoginStatus.confirmed) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: CupertinoColors.activeGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          CupertinoIcons.checkmark_circle_fill,
          size: 80,
          color: CupertinoColors.activeGreen,
        ),
      );
    }

    if (loginState.uuid.isEmpty) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    }

    return QrImageView(
      data: _scanUrl,
      version: QrVersions.auto,
      size: 200,
      backgroundColor: CupertinoColors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  Widget _buildScanInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF12B7F5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.qrcode_viewfinder,
                  color: Color(0xFF12B7F5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '打开企业微信扫一扫',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF12B7F5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.device_phone_portrait,
                  color: Color(0xFF12B7F5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '在企业微信中选择"扫一扫"',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF12B7F5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.checkmark_seal,
                  color: Color(0xFF12B7F5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '扫码后点击"确认登录"',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannedInfo(ScanLoginState loginState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF12B7F5).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF12B7F5).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const CupertinoActivityIndicator(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loginState.scannerName ?? "扫码者"} 已扫码',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF12B7F5),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '请在手机上确认登录',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusTitle(ScanLoginStatus status) {
    switch (status) {
      case ScanLoginStatus.waiting:
        return '请扫码登录';
      case ScanLoginStatus.scanned:
        return '扫码成功';
      case ScanLoginStatus.confirmed:
        return '登录成功';
      case ScanLoginStatus.expired:
        return '二维码已过期';
      case ScanLoginStatus.error:
        return '登录失败';
    }
  }

  String _getStatusSubtitle(ScanLoginStatus status) {
    switch (status) {
      case ScanLoginStatus.waiting:
        return '使用企业微信扫描二维码';
      case ScanLoginStatus.scanned:
        return '请在企业微信中确认登录';
      case ScanLoginStatus.confirmed:
        return '正在跳转...';
      case ScanLoginStatus.expired:
        return '请点击下方按钮刷新二维码';
      case ScanLoginStatus.error:
        return '请重试';
    }
  }
}
