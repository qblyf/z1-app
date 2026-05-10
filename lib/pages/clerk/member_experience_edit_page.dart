import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/member_api.dart';
import '../../models/user.dart';

/// 修改会员经验值页面
class MemberExperienceEditPage extends ConsumerStatefulWidget {
  const MemberExperienceEditPage({super.key});

  @override
  ConsumerState<MemberExperienceEditPage> createState() =>
      _MemberExperienceEditPageState();
}

class _MemberExperienceEditPageState
    extends ConsumerState<MemberExperienceEditPage> {
  int _step = 0;
  Member? _member;
  String _phone = '';
  String _experienceText = '0';
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('修改会员经验值'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 步骤指示器
            _StepIndicator(currentStep: _step),
            // 内容区
            Expanded(
              child: _step == 0
                  ? _InputUserInfo(
                      member: _member,
                      phone: _phone,
                      loading: _loading,
                      error: _error,
                      onPhoneChanged: (v) => setState(() {
                        _phone = v;
                        _error = null;
                      }),
                      onSearch: _searchMember,
                      onCancelEdit: () => setState(() {
                        _member = null;
                        _phone = '';
                      }),
                      onNextStep: () => setState(() => _step = 1),
                    )
                  : _UserExperienceInfo(
                      member: _member,
                      experienceText: _experienceText,
                      loading: _loading,
                      onExperienceChanged: (v) =>
                          setState(() => _experienceText = v),
                      onPrevStep: () => setState(() => _step = 0),
                      onSubmit: _submitExperience,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchMember() async {
    final phone = _phone.trim();
    if (phone.isEmpty) {
      setState(() => _error = '请输入手机号码');
      return;
    }
    if (!_isValidPhone(phone)) {
      setState(() => _error = '请输入合法的手机号码');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = MemberApi();
      final members = await api.getByPhones([phone]);
      if (members.isEmpty) {
        setState(() {
          _loading = false;
          _error = '没有找到顾客信息';
        });
        return;
      }
      setState(() {
        _member = members.first;
        _experienceText = _member!.experience.toString();
        _loading = false;
        _step = 1;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _submitExperience() async {
    if (_member == null) return;
    final exp = int.tryParse(_experienceText);
    if (exp == null || exp < 0) {
      _showToast('请输入大于等于0的正整数');
      return;
    }
    if (exp > 99999999) {
      setState(() => _experienceText = '99999999');
      _showToast('经验值不能超过99999999');
      return;
    }
    if (exp == _member!.experience) {
      _showToast('没有任何改变');
      return;
    }
    setState(() => _loading = true);
    try {
      final api = MemberApi();
      final rowCount = await api.editMemberExperience(
        member: _member!.userIdent,
        experience: exp,
      );
      if (rowCount > 0) {
        _showToast('修改成功');
        // 重新查询会员信息更新界面
        final members = await api.getByPhones([_member!.mobilePhone ?? '']);
        if (members.isNotEmpty) {
          setState(() {
            _member = members.first;
            _experienceText = _member!.experience.toString();
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      } else {
        setState(() => _loading = false);
        _showToast('修改失败');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showToast('修改失败: $e');
    }
  }

  bool _isValidPhone(String phone) {
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }

  void _showToast(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}

/// 步骤指示器
class _StepIndicator extends StatelessWidget {
  final int currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          Row(
            children: [
              _buildDot(0, '确认顾客信息'),
              Expanded(
                child: Container(
                  height: 2,
                  color: currentStep > 0
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey4,
                ),
              ),
              _buildDot(1, '修改经验值'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int step, String label) {
    final isActive = currentStep >= step;
    final isCurrent = currentStep == step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey4,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: CupertinoColors.activeBlue.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive
                    ? CupertinoColors.white
                    : CupertinoColors.systemGrey,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}

/// 步骤一：输入手机号查询顾客信息
class _InputUserInfo extends StatelessWidget {
  final Member? member;
  final String phone;
  final bool loading;
  final String? error;
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onSearch;
  final VoidCallback onCancelEdit;
  final VoidCallback onNextStep;

  const _InputUserInfo({
    required this.member,
    required this.phone,
    required this.loading,
    required this.error,
    required this.onPhoneChanged,
    required this.onSearch,
    required this.onCancelEdit,
    required this.onNextStep,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 已查到的顾客信息
          if (member != null) ...[
            _InfoCard(
              label: '顾客姓名',
              value: member!.realName ?? '未知姓名',
            ),
            const SizedBox(height: 8),
            _InfoCard(
              label: '手机号',
              value: _formatPhone(member!.mobilePhone ?? ''),
            ),
            const SizedBox(height: 24),
          ],
          // 手机号输入
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
              border: error != null
                  ? Border.all(color: CupertinoColors.destructiveRed)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '顾客手机号',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  placeholder: '输入手机号查询',
                  keyboardType: TextInputType.phone,
                  padding: EdgeInsets.zero,
                  decoration: const BoxDecoration(),
                  style: const TextStyle(fontSize: 16),
                  onChanged: onPhoneChanged,
                  controller: TextEditingController(text: phone)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: phone.length),
                    ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (member != null)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onCancelEdit,
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: Text(
                    '取消修改',
                    style: TextStyle(color: CupertinoColors.black),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          CupertinoButton.filled(
            padding: EdgeInsets.zero,
            onPressed: loading ? null : onSearch,
            child: Container(
              width: double.infinity,
              height: 44,
              child: Center(
                child: loading
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white)
                    : const Text('确认并进入下一步'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhone(String phone) {
    if (phone.length == 11) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    }
    return phone;
  }
}

/// 步骤二：修改经验值
class _UserExperienceInfo extends StatelessWidget {
  final Member? member;
  final String experienceText;
  final bool loading;
  final ValueChanged<String> onExperienceChanged;
  final VoidCallback onPrevStep;
  final VoidCallback onSubmit;

  const _UserExperienceInfo({
    required this.member,
    required this.experienceText,
    required this.loading,
    required this.onExperienceChanged,
    required this.onPrevStep,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (member != null) ...[
            _InfoCard(
              label: '姓名',
              value: member!.realName ?? '未知姓名',
            ),
            const SizedBox(height: 8),
            _InfoCard(
              label: '电话',
              value: _formatPhone(member!.mobilePhone ?? ''),
            ),
            const SizedBox(height: 24),
          ],
          // 经验值输入
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '经验值',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  placeholder: '请输入经验值，大于等于0的正整数，最大99999999',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  padding: EdgeInsets.zero,
                  decoration: const BoxDecoration(),
                  style: const TextStyle(fontSize: 16),
                  onChanged: onExperienceChanged,
                  controller: TextEditingController(text: experienceText)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: experienceText.length),
                    ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onPrevStep,
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5.resolveFrom(context),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Text(
                  '返回上一步',
                  style: TextStyle(color: CupertinoColors.black),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton.filled(
            padding: EdgeInsets.zero,
            onPressed: loading ? null : onSubmit,
            child: Container(
              width: double.infinity,
              height: 44,
              child: Center(
                child: loading
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white)
                    : const Text('确认修改'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhone(String phone) {
    if (phone.length == 11) {
      return '${phone.substring(0, 3)}-${phone.substring(3, 7)}-${phone.substring(7)}';
    }
    return phone;
  }
}

/// 信息卡片
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
