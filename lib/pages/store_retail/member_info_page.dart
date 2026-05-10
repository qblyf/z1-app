import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/member_api.dart';
import '../../models/user.dart';
import '../../models/store_retail.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 会员信息编辑页 Provider
final memberInfoProvider =
    FutureProvider.family<Member, int>((ref, userIdent) async {
  return MemberApi().getByIdent(userIdent);
});

/// 会员信息编辑页
class MemberInfoPage extends ConsumerStatefulWidget {
  final int userIdent;

  const MemberInfoPage({super.key, required this.userIdent});

  @override
  ConsumerState<MemberInfoPage> createState() => _MemberInfoPageState();
}

class _MemberInfoPageState extends ConsumerState<MemberInfoPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedGender = 'secret';
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMember();
    });
  }

  void _loadMember() async {
    try {
      final member = await MemberApi().getByIdent(widget.userIdent);
      if (mounted) {
        setState(() {
          _nameController.text = member.realName ?? '';
          _emailController.text = member.email ?? '';
          _selectedGender = member.gender.name;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final api = MemberApi();
      final success = await api.edit(widget.userIdent, {
        'realName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
      });
      if (!mounted) return;
      if (success) {
        setState(() => _hasChanges = false);
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.accent),
                const SizedBox(width: 8),
                const Text('保存成功'),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('确定'),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
              ),
            ],
          ),
        );
      } else {
        _showError('保存失败');
      }
    } catch (e) {
      if (mounted) _showError('保存失败: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('提示'),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final memberAsync = ref.watch(memberInfoProvider(widget.userIdent));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('会员信息'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
        trailing: _hasChanges
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const CupertinoActivityIndicator()
                    : Text(
                        '保存',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              )
            : null,
      ),
      child: SafeArea(
        child: memberAsync.when(
          data: (member) => _buildForm(member),
          loading: () => const LoadingWidget(message: '加载会员信息...'),
          error: (e, _) => AppErrorWidget(message: '加载失败: $e'),
        ),
      ),
    );
  }

  Widget _buildForm(Member member) {
    final level = MemberLevel.fromExperience(member.experience);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 会员卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [level.color, level.color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.elevated,
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: member.wxAcatar != null && member.wxAcatar!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            member.wxAcatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              CupertinoIcons.person_fill,
                              color: CupertinoColors.white,
                              size: 32,
                            ),
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.person_fill,
                          color: CupertinoColors.white,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.realName ?? '匿名顾客',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.mobilePhone ?? '',
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${level.name} · ${member.experience}经验',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 基本信息
          _SectionTitle('基本信息'),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _EditRow(
                  icon: CupertinoIcons.person,
                  label: '姓名',
                  child: CupertinoTextField(
                    controller: _nameController,
                    placeholder: '请输入姓名',
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    style: AppText.body,
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
                _divider(),
                _EditRow(
                  icon: CupertinoIcons.device_phone_portrait,
                  label: '手机号',
                  trailing: Text(
                    member.mobilePhone ?? '-',
                    style: AppText.body.copyWith(color: AppColors.textTertiary),
                  ),
                ),
                _divider(),
                _EditRow(
                  icon: CupertinoIcons.person_2,
                  label: '性别',
                  child: _GenderPicker(
                    value: _selectedGender,
                    onChanged: (v) {
                      setState(() {
                        _selectedGender = v;
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 联系信息
          _SectionTitle('联系信息'),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _EditRow(
                  icon: CupertinoIcons.envelope,
                  label: '邮箱',
                  child: CupertinoTextField(
                    controller: _emailController,
                    placeholder: '请输入邮箱',
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    style: AppText.body,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 扩展信息
          _SectionTitle('扩展信息'),
          Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                _EditRow(
                  icon: CupertinoIcons.gift,
                  label: '运营商',
                  trailing: Text(member.operator ?? '-', style: AppText.body),
                ),
                _divider(),
                _EditRow(
                  icon: CupertinoIcons.star,
                  label: '积分',
                  trailing: Text('${member.coin}', style: AppText.body.copyWith(color: AppColors.accent, fontWeight: FontWeight.bold)),
                ),
                _divider(),
                _EditRow(
                  icon: CupertinoIcons.calendar,
                  label: '注册时间',
                  trailing: Text(_formatTime(member.joinTime), style: AppText.body),
                ),
                _divider(),
                _EditRow(
                  icon: CupertinoIcons.time,
                  label: '最后活跃',
                  trailing: Text(_formatTime(member.lastTime), style: AppText.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    if (timestamp == 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _divider() => Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: 52),
        color: AppColors.divider,
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: AppText.label),
    );
  }
}

class _EditRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? child;
  final Widget? trailing;

  const _EditRow({
    required this.icon,
    required this.label,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          SizedBox(
            width: 60,
            child: Text(label, style: AppText.body.copyWith(color: AppColors.textSecondary)),
          ),
          if (child != null) Expanded(child: child!),
          if (trailing != null) Expanded(child: trailing!),
        ],
      ),
    );
  }
}

class _GenderPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _GenderPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _GenderOption('secret', '保密', value == 'secret', onChanged),
        const SizedBox(width: 20),
        _GenderOption('male', '男', value == 'male', onChanged),
        const SizedBox(width: 20),
        _GenderOption('female', '女', value == 'female', onChanged),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String value;
  final String label;
  final bool isSelected;
  final ValueChanged<String> onChanged;

  const _GenderOption(this.value, this.label, this.isSelected, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(label, style: AppText.body),
        ],
      ),
    );
  }
}
