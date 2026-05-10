import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

/// 库存分配页面
class StockDistributionPage extends ConsumerStatefulWidget {
  const StockDistributionPage({super.key});

  @override
  ConsumerState<StockDistributionPage> createState() =>
      _StockDistributionPageState();
}

class _StockDistributionPageState
    extends ConsumerState<StockDistributionPage> {
  bool _isLoading = false;
  List<_StockItem> _stocks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _stocks = _generateMockData();
      _isLoading = false;
    });
  }

  List<_StockItem> _generateMockData() {
    return [
      _StockItem(
          name: 'iPhone 15 Pro', sku: '256GB 钛金色', stock: 50, allocated: 30),
      _StockItem(
          name: 'iPhone 15', sku: '128GB 蓝色', stock: 80, allocated: 45),
      _StockItem(
          name: 'AirPods Pro 2', sku: 'USB-C', stock: 120, allocated: 60),
      _StockItem(
          name: 'iPad Air', sku: '64GB WiFi', stock: 35, allocated: 20),
      _StockItem(
          name: 'Apple Watch S9', sku: '45mm 蜂窝版', stock: 25, allocated: 15),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('库存分配'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _loadData,
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const LoadingWidget(message: '加载中...')
            : CustomScrollView(
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _loadData),
                  SliverPadding(
                    padding: const EdgeInsets.all(12),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _stocks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.sku,
                                            style: TextStyle(
                                              color: CupertinoColors
                                                  .secondaryLabel
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: const Icon(CupertinoIcons.pencil),
                                      onPressed: () =>
                                          _showAllocationDialog(context, item),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _StockProgress(
                                      label: '库存',
                                      value: item.stock,
                                      total: item.stock,
                                      color: CupertinoColors.activeBlue,
                                    ),
                                    _StockProgress(
                                      label: '已分配',
                                      value: item.allocated,
                                      total: item.stock,
                                      color: CupertinoColors.activeGreen,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: _stocks.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showAllocationDialog(BuildContext context, _StockItem item) {
    int allocated = item.allocated;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '分配 ${item.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.xmark_circle_fill),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('当前分配: $allocated / ${item.stock}'),
            const SizedBox(height: 16),
            Expanded(
              child: CupertinoSlider(
                value: allocated.toDouble(),
                min: 0,
                max: item.stock.toDouble(),
                divisions: item.stock,
                onChanged: (value) {
                  allocated = value.round();
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: () {
                  Navigator.pop(ctx);
                  showCupertinoDialog(
                    context: context,
                    builder: (c) => CupertinoAlertDialog(
                      title: const Text('提示'),
                      content: const Text('保存成功'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('确定'),
                          onPressed: () => Navigator.pop(c),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockItem {
  final String name;
  final String sku;
  final int stock;
  final int allocated;

  _StockItem({
    required this.name,
    required this.sku,
    required this.stock,
    required this.allocated,
  });
}

class _StockProgress extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const _StockProgress({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? value / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Cupertino 风格进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 6,
                color: CupertinoColors.systemGrey5.resolveFrom(context),
              ),
              Container(
                width: 120 * percentage,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
