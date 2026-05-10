import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/coupon_api.dart';
import '../../api/member_api.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

/// 批量发放优惠券页面
class BatchIssueCouponsPage extends ConsumerStatefulWidget {
  const BatchIssueCouponsPage({super.key});

  @override
  ConsumerState<BatchIssueCouponsPage> createState() => _BatchIssueCouponsPageState();
}

class _BatchIssueCouponsPageState extends ConsumerState<BatchIssueCouponsPage> {
  List<CouponClass> _couponClasses = [];
  CouponClass? _selectedCoupon;
  bool _isLoading = true;

  // 选择的会员
  List<int> _selectedMembers = [];
  final _phoneController = TextEditingController();
  List<Member> _searchResults = [];
  bool _isSearching = false;

  // 备注
  final _remarkController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCouponClasses();
  }

  Future<void> _loadCouponClasses() async {
    try {
      final api = CouponApi();
      final classes = await api.getCouponClassList(limit: 100, state: 1);
      if (mounted) {
        setState(() {
          _couponClasses = classes;
          _isLoading = false;
          if (classes.isNotEmpty) _selectedCoupon = classes.first;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _searchMembers() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final api = MemberApi();
      final results = await api.getByPhones([phone]);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _toggleMember(int userIdent) {
    setState(() {
      if (_selectedMembers.contains(userIdent)) {
        _selectedMembers.remove(userIdent);
      } else {
        _selectedMembers.add(userIdent);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedCoupon == null) {
      _showToast('请选择优惠券');
      return;
    }
    if (_selectedMembers.isEmpty) {
      _showToast('请选择发放对象');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final api = CouponApi();
      final success = await api.batchGiveCoupons(
        userIdents: _selectedMembers,
        couponClassId: _selectedCoupon!.id,
        remark: _remarkController.text.trim(),
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          _showToast('发放成功！已成功发放 ${_selectedMembers.length} 张优惠券');
          setState(() {
            _selectedMembers.clear();
            _phoneController.clear();
            _searchResults.clear();
            _remarkController.clear();
          });
        } else {
          _showToast('发放失败');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showToast('发放失败: $e');
      }
    }
  }

  void _showToast(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('好的'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
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
        middle: const Text('批量发放优惠券'),
        trailing: _selectedMembers.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() => _selectedMembers.clear()),
                child: Text('清除(${_selectedMembers.length})', style: const TextStyle(fontSize: 14)),
              )
            : null,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 选择优惠券
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('选择优惠券', style: AppText.label),
                          const SizedBox(height: 12),
                          if (_couponClasses.isEmpty)
                            Text('暂无可用优惠券', style: AppText.caption)
                          else
                            ..._couponClasses.map((c) => _CouponOptionCard(
                              coupon: c,
                              isSelected: _selectedCoupon?.id == c.id,
                              onTap: () => setState(() => _selectedCoupon = c),
                            )),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 选择发放对象
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('选择发放对象', style: AppText.label),
                              const Spacer(),
                              Text('已选 ${_selectedMembers.length} 人', style: AppText.caption),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: CupertinoTextField(
                                  controller: _phoneController,
                                  placeholder: '输入手机号搜索会员',
                                  keyboardType: TextInputType.phone,
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CupertinoButton.filled(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                onPressed: _isSearching ? null : _searchMembers,
                                child: _isSearching
                                    ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                                    : const Text('搜索'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_searchResults.isNotEmpty) ...[
                            Text('搜索结果', style: AppText.caption),
                            const SizedBox(height: 8),
                            ..._searchResults.map((m) => _MemberOptionCard(
                              member: m,
                              isSelected: _selectedMembers.contains(m.userIdent),
                              onTap: () => _toggleMember(m.userIdent),
                            )),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 备注
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('备注（可选）', style: AppText.label),
                          const SizedBox(height: 12),
                          CupertinoTextField(
                            controller: _remarkController,
                            placeholder: '输入发放备注...',
                            maxLines: 3,
                            padding: const EdgeInsets.all(12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 提交按钮
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton.filled(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: (_selectedCoupon == null || _selectedMembers.isEmpty || _isSubmitting)
                            ? null
                            : _submit,
                        child: _isSubmitting
                            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                            : Text('发放给 ${_selectedMembers.length} 人'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CouponOptionCard extends StatelessWidget {
  final CouponClass coupon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CouponOptionCard({
    required this.coupon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0A84FF).withValues(alpha: 0.05) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0A84FF) : CupertinoColors.systemGrey4,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected ? const Color(0xFF0A84FF) : AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coupon.title, style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5E5CE6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(coupon.typeLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF5E5CE6))),
                      ),
                      const SizedBox(width: 8),
                      Text(coupon.formattedAmount, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFFF9500))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberOptionCard extends StatelessWidget {
  final Member member;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemberOptionCard({
    required this.member,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF30D158).withValues(alpha: 0.05) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF30D158) : CupertinoColors.systemGrey4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected ? const Color(0xFF30D158) : AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.realName ?? '会员', style: AppText.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(member.mobilePhone ?? '', style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
