import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_retail_api.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 门店零售入口页
/// 员工输入顾客手机号，查找或注册会员，然后进入零售流程
class StoreRetailEntryPage extends ConsumerStatefulWidget {
  const StoreRetailEntryPage({super.key});

  @override
  ConsumerState<StoreRetailEntryPage> createState() =>
      _StoreRetailEntryPageState();
}

class _StoreRetailEntryPageState extends ConsumerState<StoreRetailEntryPage> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 11) {
      setState(() => _errorMessage = '请输入正确的手机号');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = StoreRetailApi();
      final member = await api.getMemberByPhone(phone);

      if (!mounted) return;

      if (member != null) {
        // 会员存在 → 进入会员首页
        context.push('/store-retail/home/${member.userIdent}');
      } else {
        // 会员不存在 → 弹出注册对话框
        _showRegisterDialog(phone);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '查询失败：${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister(String phone, {String? name}) async {
    setState(() => _isLoading = true);
    try {
      final api = StoreRetailApi();
      final userIdent = await api.addMember(mobilePhone: phone, realName: name);
      if (!mounted) return;
      if (userIdent > 0) {
        Navigator.pop(context); // 关闭对话框
        context.push('/store-retail/home/$userIdent');
      } else {
        setState(() => _errorMessage = '注册失败，请重试');
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '注册失败：${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRegisterDialog(String phone) {
    final nameController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('新会员'),
        content: Column(
          children: [
            const SizedBox(height: 8),
            Text('手机号 $phone 尚未注册，将为其创建会员档案'),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: nameController,
              placeholder: '姓名（选填）',
              padding: const EdgeInsets.all(12),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () => _handleRegister(phone, name: nameController.text),
            child: const Text('确认注册'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('门店零售'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.back, size: 24),
              SizedBox(width: 4),
              Text('返回', style: TextStyle(fontSize: 17)),
            ],
          ),
          onPressed: () => safePop(context),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // Logo 区域
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.elevated,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person_crop_circle,
                        size: 56,
                        color: CupertinoColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      '会员零售',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '输入顾客手机号开始服务',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // 手机号输入
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '顾客手机号',
                      style: AppText.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    CupertinoTextField(
                      controller: _phoneController,
                      placeholder: '请输入手机号码',
                      keyboardType: TextInputType.phone,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      style: const TextStyle(fontSize: 18, letterSpacing: 2),
                      maxLength: 11,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 搜索按钮
              CupertinoButton.filled(
                onPressed: _isLoading ? null : _handleSearch,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: _isLoading
                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                    : const Text(
                        '查询会员',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),

              const Spacer(),

              // 底部提示
              Text(
                '输入顾客手机号，查询已有会员或注册新会员',
                style: AppText.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
