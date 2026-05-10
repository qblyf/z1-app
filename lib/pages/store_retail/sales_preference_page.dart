import 'package:flutter/cupertino.dart';
import '../../api/label_api.dart';
import '../../models/label.dart';
import '../../theme/app_theme.dart';

/// 销售偏好页
/// 显示指定会员的购买偏好和回收次数
class SalesPreferencePage extends StatefulWidget {
  final int memberIdent;
  final String memberName;

  const SalesPreferencePage({
    super.key,
    required this.memberIdent,
    required this.memberName,
  });

  @override
  State<SalesPreferencePage> createState() =>
      _SalesPreferencePageState();
}

class _SalesPreferencePageState extends State<SalesPreferencePage> {
  MemberSalesPreference? _preference;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final api = LabelApi();
      // 并行请求购买偏好和回收次数
      final results = await Future.wait([
        api.getSalesPreference(widget.memberIdent),
        api.getRecycleCount(widget.memberIdent),
      ]);
      if (mounted) {
        setState(() {
          _preference = MemberSalesPreference(
            buyPreference: results[0].buyPreference,
            recycleCount: results[1],
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('销售偏好'),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 会员信息头部
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              color: CupertinoColors.white,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      CupertinoIcons.chart_bar_fill,
                      color: Color(0xFFFF9500),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.memberName.isNotEmpty
                              ? widget.memberName
                              : '会员',
                          style: AppText.body
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${widget.memberIdent}',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // 页面标题
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                '会员销售偏好',
                style: AppText.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            // 内容区
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _hasError || _preference == null
                      ? _buildErrorState()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 8),
          Text('加载失败，请重试', style: AppText.caption),
          const SizedBox(height: 16),
          CupertinoButton(
            onPressed: _loadData,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final pref = _preference!;
    final preferences = pref.buyPreference;

    // 按顺序显示分类
    final categories = [
      _CategoryInfo(
        id: PreferenceCate.配件.id,
        name: '配件',
        preference: BuyPreference.findByCate(preferences, PreferenceCate.配件.id),
      ),
      _CategoryInfo(
        id: PreferenceCate.手机.id,
        name: '手机',
        preference: BuyPreference.findByCate(preferences, PreferenceCate.手机.id),
      ),
      _CategoryInfo(
        id: PreferenceCate.电脑.id,
        name: '笔记本',
        preference: BuyPreference.findByCate(preferences, PreferenceCate.电脑.id),
      ),
      _CategoryInfo(
        id: PreferenceCate.平板.id,
        name: '平板',
        preference:
            BuyPreference.findByCate(preferences, PreferenceCate.平板.id),
      ),
      _CategoryInfo(
        id: PreferenceCate.保护壳.id,
        name: '保护壳',
        preference:
            BuyPreference.findByCate(preferences, PreferenceCate.保护壳.id),
      ),
      _CategoryInfo(
        id: PreferenceCate.贴膜.id,
        name: '保护膜',
        preference: BuyPreference.findByCate(preferences, PreferenceCate.贴膜.id),
      ),
    ];

    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            // 前6行：购买次数
            for (int i = 0; i < categories.length; i += 2)
              _PreferenceRow(
                left: _PreferenceItem(
                  label: '${categories[i].name}购买次数',
                  value: categories[i].preference?.saleProductQuantity ?? 0,
                  isLeft: true,
                ),
                right: i + 1 < categories.length
                    ? _PreferenceItem(
                        label: '${categories[i + 1].name}购买次数',
                        value: categories[i + 1]
                                .preference
                                ?.saleProductQuantity ??
                            0,
                        isLeft: false,
                      )
                    : null,
              ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.divider,
            ),
            // 退换次数行
            _PreferenceRow(
              left: _PreferenceItem(
                label: '手机退换次数',
                value: BuyPreference.findByCate(preferences, PreferenceCate.手机.id)
                        ?.refundsChangeOrderQuantity ??
                    0,
                isLeft: true,
              ),
              right: _PreferenceItem(
                label: '旧机回收次数',
                value: pref.recycleCount,
                isLeft: false,
                valueColor: const Color(0xFF34C759),
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.divider,
            ),
            // 电脑退换次数
            _PreferenceRow(
              left: _PreferenceItem(
                label: '电脑退换次数',
                value: BuyPreference.findByCate(preferences, PreferenceCate.电脑.id)
                        ?.refundsChangeOrderQuantity ??
                    0,
                isLeft: true,
              ),
              right: null,
            ),
          ],
        ),
      ),
    );
  }
}

/// 分类信息
class _CategoryInfo {
  final int id;
  final String name;
  final BuyPreference? preference;

  _CategoryInfo({
    required this.id,
    required this.name,
    this.preference,
  });
}

/// 偏好数据行
class _PreferenceRow extends StatelessWidget {
  final _PreferenceItem? left;
  final _PreferenceItem? right;

  const _PreferenceRow({this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          if (left != null) Expanded(child: left!),
          if (right != null)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [right!],
              ),
            ),
        ],
      ),
    );
  }
}

/// 偏好数据项
class _PreferenceItem extends StatelessWidget {
  final String label;
  final int value;
  final bool isLeft;
  final Color? valueColor;

  const _PreferenceItem({
    required this.label,
    required this.value,
    required this.isLeft,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: isLeft ? MainAxisSize.min : MainAxisSize.max,
      children: [
        Text(label, style: AppText.body),
        const SizedBox(width: 10),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 14,
            color: valueColor ?? const Color(0xFF8D8B8B),
          ),
        ),
      ],
    );
  }
}
