import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../api/store_retail_api.dart';
import '../../models/store_retail.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../router/app_router.dart';

/// 赠品选择页面
/// 从销售订单页的购物车中点击"赠品"入口进入
class GiveawaySelectPage extends ConsumerStatefulWidget {
  /// 购物车项 key: 'sku-{skuId}' / 'service-{serviceId}' / 'item-{itemId}'
  final String itemKey;
  /// SKU ID（如果是从商品入口）
  final int? skuId;
  /// 服务 ID（如果是从服务入口）
  final int? serviceId;
  /// 非标品 ID（如果是从非标品入口）
  final int? itemId;
  /// 商品名称（用于显示）
  final String? itemName;
  /// 购买数量
  final int qty;

  const GiveawaySelectPage({
    super.key,
    required this.itemKey,
    this.skuId,
    this.serviceId,
    this.itemId,
    this.itemName,
    this.qty = 1,
  });

  @override
  ConsumerState<GiveawaySelectPage> createState() => _GiveawaySelectPageState();
}

class _GiveawaySelectPageState extends ConsumerState<GiveawaySelectPage> {
  final StoreRetailApi _api = StoreRetailApi();
  List<GiveawayActivityInfo> _activities = [];
  Map<int, List<GiveawaySkuInfo>> _skuInfoMap = {};
  Map<int, List<GiveawayServiceInfo>> _serviceInfoMap = {};
  /// 已选的赠品项: activityId -> [giftId1, giftId2]
  final Map<int, Set<int>> _selected = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final activities = await _api.getGiveawayActivityAvailable(
        skuId: widget.skuId,
        serviceId: widget.serviceId,
        itemId: widget.itemId,
      );

      if (!mounted) return;

      // 获取每个活动的赠品详情
      final skuInfoMap = <int, List<GiveawaySkuInfo>>{};
      final serviceInfoMap = <int, List<GiveawayServiceInfo>>{};
      final allSkuIds = <int>[];
      final allServiceIds = <int>[];

      for (final activity in activities) {
        allSkuIds.addAll(activity.skuGiveaway);
        allServiceIds.addAll(activity.serviceGiveaway);
      }

      // 批量获取赠品详情
      if (allSkuIds.isNotEmpty) {
        final uniqueSkuIds = allSkuIds.toSet().toList();
        final skuDetails = await _api.getGiveawaySkuDetails(uniqueSkuIds);
        for (final activity in activities) {
          final relevantIds = activity.skuGiveaway
              .where((id) => uniqueSkuIds.contains(id))
              .toList();
          if (relevantIds.isNotEmpty) {
            skuInfoMap[activity.id] = skuDetails
                .where((s) => relevantIds.contains(s.id))
                .toList();
          }
        }
      }

      if (allServiceIds.isNotEmpty) {
        final uniqueServiceIds = allServiceIds.toSet().toList();
        final serviceDetails = await _api.getGiveawayServiceDetails(uniqueServiceIds);
        for (final activity in activities) {
          final relevantIds = activity.serviceGiveaway
              .where((id) => uniqueServiceIds.contains(id))
              .toList();
          if (relevantIds.isNotEmpty) {
            serviceInfoMap[activity.id] = serviceDetails
                .where((s) => relevantIds.contains(s.id))
                .toList();
          }
        }
      }

      if (mounted) {
        setState(() {
          _activities = activities;
          _skuInfoMap = skuInfoMap;
          _serviceInfoMap = serviceInfoMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggle(int activityId, int giftId) {
    setState(() {
      if (!_selected.containsKey(activityId)) {
        _selected[activityId] = {};
      }
      if (_selected[activityId]!.contains(giftId)) {
        _selected[activityId]!.remove(giftId);
        if (_selected[activityId]!.isEmpty) {
          _selected.remove(activityId);
        }
      } else {
        _selected[activityId]!.add(giftId);
      }
    });
  }

  bool _isSelected(int activityId, int giftId) {
    return _selected[activityId]?.contains(giftId) ?? false;
  }

  List<CartGiveaway> _buildSelectedGiveaways() {
    final result = <CartGiveaway>[];
    for (final entry in _selected.entries) {
      final activityId = entry.key;
      for (final giftId in entry.value) {
        // 尝试找赠品名称
        String? giftName;
        String? thumbnail;
        final skuList = _skuInfoMap[activityId];
        if (skuList != null) {
          final sku = skuList.where((s) => s.id == giftId).firstOrNull;
          giftName = sku?.name;
          thumbnail = sku?.thumbnail;
        }
        if (giftName == null) {
          final svcList = _serviceInfoMap[activityId];
          final svc = svcList?.where((s) => s.id == giftId).firstOrNull;
          giftName = svc?.name;
          thumbnail = svc?.thumbnail;
        }
        final type = (skuList?.any((s) => s.id == giftId) ?? false) ? 'sku' : 'service';
        result.add(CartGiveaway(
          activityId: activityId,
          type: type,
          giftId: giftId,
          giftName: giftName,
          thumbnail: thumbnail,
        ));
      }
    }
    return result;
  }

  void _confirm() {
    final giveaways = _buildSelectedGiveaways();
    context.pop(giveaways);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.itemName != null ? '选择赠品 - ${widget.itemName}' : '选择赠品'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('取消'),
          onPressed: () => context.pop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _confirm,
          child: Text(
            '确定',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _selected.isNotEmpty ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: '加载赠品方案...');
    }

    if (_error != null) {
      return AppErrorWidget(message: _error!, onRetry: _loadData);
    }

    if (_activities.isEmpty) {
      return const EmptyWidget(
        message: '暂无赠品活动',
        icon: CupertinoIcons.gift,
      );
    }

    return Column(
      children: [
        // 提示
        Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.info_circle, color: CupertinoColors.activeBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '可从以下赠品方案中选择，赠品将随订单赠送',
                  style: TextStyle(
                    color: CupertinoColors.activeBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 已选数量提示
        if (_selected.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.activeGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.checkmark_circle, color: CupertinoColors.activeGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  '已选 ${_selected.values.fold(0, (a, b) => a + b.length)} 件赠品',
                  style: TextStyle(color: CupertinoColors.activeGreen, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _activities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final activity = _activities[index];
              return _ActivityCard(
                activity: activity,
                skuInfos: _skuInfoMap[activity.id] ?? [],
                serviceInfos: _serviceInfoMap[activity.id] ?? [],
                isSelected: _isSelected,
                onToggle: (giftId) => _toggle(activity.id, giftId),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final GiveawayActivityInfo activity;
  final List<GiveawaySkuInfo> skuInfos;
  final List<GiveawayServiceInfo> serviceInfos;
  final bool Function(int, int) isSelected;
  final void Function(int) onToggle;

  const _ActivityCard({
    required this.activity,
    required this.skuInfos,
    required this.serviceInfos,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 活动头部
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.activeOrange.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.gift_fill, color: CupertinoColors.activeOrange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.giveawayCopy.isNotEmpty ? activity.giveawayCopy : activity.desc,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      if (activity.giveawayCopy.isNotEmpty && activity.desc.isNotEmpty)
                        Text(
                          activity.desc,
                          style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (activity.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '进行中',
                      style: TextStyle(color: CupertinoColors.white, fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          // 赠品列表
          if (skuInfos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text('商品赠品', style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 11)),
            ),
            ...skuInfos.map((sku) => _GiftItem(
              name: sku.name,
              thumbnail: sku.thumbnail,
              isSelected: isSelected(activity.id, sku.id),
              onTap: () => onToggle(sku.id),
            )),
          ],
          if (serviceInfos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text('服务赠品', style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 11)),
            ),
            ...serviceInfos.map((svc) => _GiftItem(
              name: svc.shortName ?? svc.name,
              thumbnail: svc.thumbnail,
              subtitle: svc.name,
              isSelected: isSelected(activity.id, svc.id),
              onTap: () => onToggle(svc.id),
            )),
          ],
          if (skuInfos.isEmpty && serviceInfos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('赠品详情加载中...', style: TextStyle(color: CupertinoColors.systemGrey)),
            ),
        ],
      ),
    );
  }
}

class _GiftItem extends StatelessWidget {
  final String name;
  final String? thumbnail;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _GiftItem({
    required this.name,
    this.thumbnail,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: isSelected
            ? CupertinoColors.activeBlue.withValues(alpha: 0.05)
            : CupertinoColors.white,
        child: Row(
          children: [
            if (thumbnail != null && thumbnail!.isNotEmpty)
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: CupertinoColors.systemGrey5,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(thumbnail!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.gift, size: 20)),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(CupertinoIcons.gift, color: CupertinoColors.activeOrange, size: 20),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  if (subtitle != null && subtitle != name)
                    Text(subtitle!, style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: isSelected ? CupertinoColors.activeBlue : CupertinoColors.systemGrey4,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
