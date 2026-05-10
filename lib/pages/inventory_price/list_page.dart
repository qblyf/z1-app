import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/inventory_price_api.dart';
import '../../models/inventory_price.dart';
import '../../theme/app_theme.dart';
import '../../router/app_router.dart';

final _stockListProvider = FutureProvider.autoDispose<List<StockPriceItem>>((ref) async {
  return inventoryPriceApi.list(includeNoStock: false);
});

final _stockCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return inventoryPriceApi.count();
});

class InventoryPriceListPage extends ConsumerStatefulWidget {
  const InventoryPriceListPage({super.key});

  @override
  ConsumerState<InventoryPriceListPage> createState() => _InventoryPriceListPageState();
}

class _InventoryPriceListPageState extends ConsumerState<InventoryPriceListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countAsync = ref.watch(_stockCountProvider);
    final listAsync = ref.watch(_stockListProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('库存价格查询'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 表头
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: CupertinoColors.systemGrey6,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('SKU名称', style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontWeight: FontWeight.w600,
                    )),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text('库存', style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontWeight: FontWeight.w600,
                    ), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('成本价', style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontWeight: FontWeight.w600,
                    ), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('零售价', style: AppText.caption.copyWith(
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontWeight: FontWeight.w600,
                    ), textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
            // 统计栏
            countAsync.when(
              data: (count) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: CupertinoColors.systemGrey6,
                child: Text(
                  '共 $count 条记录',
                  style: AppText.caption.copyWith(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // 列表
            Expanded(
              child: listAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.cube_box, size: 48, color: CupertinoColors.systemGrey3.resolveFrom(context)),
                          const SizedBox(height: 12),
                          Text('暂无数据', style: AppText.body.copyWith(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: CupertinoColors.separator.resolveFrom(context)),
                    itemBuilder: (context, index) => _StockPriceRow(item: list[index]),
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error: (e, _) => Center(
                  child: Text('加载失败: $e', style: TextStyle(color: CupertinoColors.systemRed.resolveFrom(context))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockPriceRow extends StatelessWidget {
  final StockPriceItem item;

  const _StockPriceRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.skuName,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.warehouseName != null)
                  Text(
                    item.warehouseName!,
                    style: AppText.caption.copyWith(
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${item.stock}',
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w600,
                color: item.stock == 0 ? const Color(0xFFFF3B30) : AppColors.primary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.costPriceDisplay,
              style: AppText.body.copyWith(color: const Color(0xFF30D158)),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item.listPriceDisplay,
              style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
